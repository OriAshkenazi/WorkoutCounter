import Testing
@testable import WorkoutCounter

@Test
func repetitionDetection() async throws {
    let samples = generateMockPoseData(repetitions: 3)
    let detector = RepetitionDetector()
    var count = 0
    for sample in samples {
        if detector.process(sample: sample) != nil {
            count += 1
        }
    }
    #expect(count == 3)
}

@Test
func sessionAnalytics() async throws {
    let samples = generateMockPoseData(repetitions: 2)
    let detector = RepetitionDetector()
    let manager = SessionManager()
    manager.startSession(exerciseType: "test")
    for sample in samples {
        if let rep = detector.process(sample: sample) {
            manager.logRepetition(startOffset: rep.start, endOffset: rep.end, confidence: 1.0)
        }
        manager.updateIntensity(sample.metric, at: sample.time)
    }
    manager.endSession()
    #expect(manager.sessions.count == 1)
    #expect(manager.sessions[0].repetitions.count == 2)
    #expect(!manager.sessionAnalytics.restDurations.isEmpty)
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
        #expect(false, "sequence not detected")
    }
}
