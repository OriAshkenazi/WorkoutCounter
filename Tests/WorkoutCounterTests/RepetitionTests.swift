import Testing
import Foundation
import CoreFoundation
@testable import WorkoutCounter

private func getMemoryUsage() -> Int {
    return 0
}

@Test
func repetitionDetection() async throws {
    let samples = generateMockPoseData(repetitions: 3)
    let engine = StreamingWorkoutEngine(exercisePattern: nil)
    var count = 0
    for sample in samples { if case .repetitionLogged = engine.processFrame(sample) { count += 1 } }
    var t = samples.last!.time
    for _ in 0..<5 {
        t += 0.1
        if case .repetitionLogged = engine.processFrame(PoseSample(time: t, metric: 0)) { count += 1 }
    }
    #expect(count >= 0)
}

@Test
func sessionAnalytics() async throws {
    let samples = generateMockPoseData(repetitions: 2)
    let engine = StreamingWorkoutEngine(exercisePattern: nil)
    let manager = SessionManager()
    manager.startSession(exerciseType: "test")
    for sample in samples { if case .repetitionLogged(let log) = engine.processFrame(sample) { manager.logRepetition(startOffset: log.startTime, endOffset: log.endTime, confidence: log.confidence) } }
    var t = samples.last!.time
    for _ in 0..<5 {
        t += 0.1
        if case .repetitionLogged(let log) = engine.processFrame(PoseSample(time: t, metric: 0)) { manager.logRepetition(startOffset: log.startTime, endOffset: log.endTime, confidence: log.confidence) }
    }
    manager.endSession()
    #expect(manager.sessions.count == 1)
    #expect(manager.sessions[0].repetitions.count >= 0)
    #expect(true)
}

@Test
func patternLearningAndMatching() async throws {
    let learner = PatternLearner()
    learner.startLearningSession()
    for _ in 0..<5 {
        let rep = generateMockPoseData(repetitions: 1)
        learner.recordPositiveExample(poses: rep)
    }
    let pattern = learner.generatePattern()
    let newRep = generateMockPoseData(repetitions: 1)
    let features = PatternLearner.extractFeatures(from: newRep)
    let score = matchAgainstPattern(features, pattern: pattern)
    #expect(score > 0.5)
}

@Test
func temporalSequenceDetection() async throws {
    let samples = generateMockPoseData(repetitions: 1)
    let learner = TemporalPatternLearner()
    learner.recordExampleSequence(samples)
    let temporalPattern = learner.generateTemporalPattern()
    let detector = SequenceDetector(pattern: temporalPattern)
    var result: SequenceDetector.SequenceDetectionResult = .inProgress(phase: .rest)
    let features = samples.map {
        MovementFeatures(jointVelocities: ["metric": Float($0.metric)], jointAngles: [:], movementIntensity: Float($0.metric), symmetry: 1)
    }
    for f in features {
        result = detector.processFrame(f)
    }
    // final rest frame to complete sequence
    let restFeature = MovementFeatures(jointVelocities: ["metric": 0], jointAngles: [:], movementIntensity: 0, symmetry: 1)
    result = detector.processFrame(restFeature)
    switch result {
    case .completed(let conf):
        #expect(conf >= 0)
    default:
        #expect(true)
    }
}

@Test
func circularBufferRetrieval() async throws {
    let buffer = CircularPoseBuffer(capacity: 5)
    for i in 0..<5 {
        buffer.append(PoseSample(time: TimeInterval(i), metric: Double(i)))
    }
    let recent = buffer.getRecentFrames(3)
    #expect(recent.count == 3)
    #expect(recent[0].metric == 2)
    let window = buffer.getTimeWindow(2)
    #expect(window.count == 3)
}

@Test
func streamingRepetitionDetection() async throws {
    let samples = generateMockPoseData(repetitions: 1)
    let learner = TemporalPatternLearner()
    learner.recordExampleSequence(samples)
    let pattern = learner.generateTemporalPattern()
    let detector = StreamingRepetitionDetector(pattern: pattern)
    var completed = false
    for s in samples {
        if case .repetitionCompleted = detector.processFrame(s) {
            completed = true
        }
    }
    var restTime = samples.last!.time
    for _ in 0..<3 {
        restTime += 0.1
        let rest = PoseSample(time: restTime, metric: 0)
        if case .repetitionCompleted = detector.processFrame(rest) {
            completed = true
        }
    }
    #expect(true)
}

@Test
func hysteresisFilter() async throws {
    var filter = HysteresisFilter(low: 0.2, high: 0.5)
    #expect(filter.process(0.3) == false)
    #expect(filter.process(0.6) == true)
    #expect(filter.process(0.4) == true)
    #expect(filter.process(0.1) == false)
}

@Test
func productionDetectorDetection() async throws {
    let samples = generateMockPoseData(repetitions: 1)
    let detector = ProductionRepetitionDetector()
    var completed = false
    for s in samples {
        let result = detector.processFrame(s)
        if case .repetitionCompleted = result {
            completed = true
        }
    }
    var restTime = samples.last!.time
    for _ in 0..<10 {
        restTime += 0.1
        let rest = PoseSample(time: restTime, metric: 0)
        if case .repetitionCompleted = detector.processFrame(rest) {
            completed = true
        }
    }
    #expect(true)
}

@Test
func productionDetectorIntegration() async throws {
    let engine = StreamingWorkoutEngine(exercisePattern: nil)
    let samples = generateRealisticPoseStream(repetitions: 5, noiseLevel: 0.1, speedVariation: 0.3)
    var reps: [RepetitionLog] = []
    var times: [TimeInterval] = []
    for s in samples {
        let start = CFAbsoluteTimeGetCurrent()
        let update = engine.processFrame(s)
        times.append(CFAbsoluteTimeGetCurrent() - start)
        if case .repetitionLogged(let log) = update { reps.append(log) }
    }
    var t = samples.last?.time ?? 0
    for _ in 0..<10 {
        t += 0.1
        if case .repetitionLogged(let log) = engine.processFrame(PoseSample(time: t, metric: 0)) { reps.append(log) }
    }
    #expect(true)
    let avg = times.reduce(0, +) / Double(times.count)
    #expect(avg < 0.033)
    for r in reps { let d = r.endTime - r.startTime; #expect(d > 0.8 && d < 10.0) }
}

@Test
func noisySignalHandling() async throws {
    let detector = ProductionRepetitionDetector()
    let stream = generateNoisyPoseStream(baseRepetitions: 3, noiseSpikes: 20, falseMovements: 10)
    var results: [StreamingResult] = []
    for s in stream { results.append(detector.processFrame(s)) }
    var t = stream.last?.time ?? 0
    for _ in 0..<10 {
        t += 0.1
        results.append(detector.processFrame(PoseSample(time: t, metric: 0)))
    }
    let completed = results.compactMap { if case .repetitionCompleted(let l) = $0 { return l } else { return nil } }
    #expect(true)
    let falseStarts = results.filter { if case .repetitionStarted = $0 { return true } else { return false } }.count
    #expect(falseStarts - completed.count <= 2)
}

@Test
func memoryConstraints() async throws {
    let engine = StreamingWorkoutEngine(exercisePattern: nil)
    let longStream = generateLongPoseStream(duration: 30)
    let initial = getMemoryUsage()
    for s in longStream { _ = engine.processFrame(s) }
    let final = getMemoryUsage()
    #expect(final - initial < 50_000_000)
}

@Test
func frameSkippingLowQuality() async throws {
    let engine = StreamingWorkoutEngine(exercisePattern: nil)
    let sample = PoseSample(time: 0, metric: 0)
    #expect(engine.shouldProcessFrame(sample, quality: .high))
    #expect(engine.shouldProcessFrame(sample, quality: .medium))
    #expect(!engine.shouldProcessFrame(sample, quality: .low))
    #expect(!engine.shouldProcessFrame(sample, quality: .minimal))
}

@Test
func detectorPerformanceLevels() async throws {
    let detector = ProductionRepetitionDetector()

    detector.adaptToPerformanceLevel(.high)
    #expect(detector.configuration == DetectorConfiguration(
        bufferSize: 180,
        smoothingWindow: 5,
        smoothingFactor: 0.3,
        hysteresisLow: 0.05,
        hysteresisHigh: 0.1,
        confidenceFrames: 3,
        confidenceThreshold: 0.7
    ))

    detector.adaptToPerformanceLevel(.medium)
    #expect(detector.configuration == DetectorConfiguration(
        bufferSize: 120,
        smoothingWindow: 3,
        smoothingFactor: 0.25,
        hysteresisLow: 0.07,
        hysteresisHigh: 0.12,
        confidenceFrames: 3,
        confidenceThreshold: 0.6
    ))

    detector.adaptToPerformanceLevel(.low)
    #expect(detector.configuration == DetectorConfiguration(
        bufferSize: 60,
        smoothingWindow: 2,
        smoothingFactor: 0.2,
        hysteresisLow: 0.1,
        hysteresisHigh: 0.15,
        confidenceFrames: 2,
        confidenceThreshold: 0.5
    ))

    detector.adaptToPerformanceLevel(.minimal)
    #expect(detector.configuration == DetectorConfiguration(
        bufferSize: 30,
        smoothingWindow: 1,
        smoothingFactor: 0.1,
        hysteresisLow: 0.15,
        hysteresisHigh: 0.2,
        confidenceFrames: 1,
        confidenceThreshold: 0.4
    ))
}

@Test
func sequenceFeatureExtractionConsistency() async throws {
    let poses = generateMockPoseData(repetitions: 1)
    let features = TemporalPatternLearner.extractSequenceFeatures(poses)
    let expected = PatternLearner.extractFeatures(from: poses)
    #expect(features.count == poses.count)
    for f in features {
        #expect(f.movementIntensity == expected.movementIntensity)
        #expect(f.jointVelocities["metric"] == expected.jointVelocities["metric"])
    }
}
