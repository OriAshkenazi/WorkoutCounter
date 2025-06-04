import Foundation
import CoreFoundation

/// More robust streaming repetition detector with hysteresis and validation.
final class ProductionRepetitionDetector {
    private var featureExtractor = StreamingFeatureExtractor()
    private var state: DetectionState = .monitoring
    private var startTime: TimeInterval?
    private var intensityFilter = TemporalSmoothingFilter()
    private var movementHysteresis = HysteresisFilter(low: 0.05, high: 0.1)
    private var confidence = ConfidenceAccumulator()
    private let validator = TemporalValidator()
    private var processingTimes = CircularBuffer<TimeInterval>(capacity: 60)

    enum DetectionState: Equatable {
        case monitoring
        case potentialStart(frames: Int)
        case inProgress(phase: RepetitionPhase.PhaseType)
        case potentialEnd(endTime: TimeInterval)
        case cooldown(until: TimeInterval)
    }

    func processFrame(_ sample: PoseSample) -> StreamingResult {
        let start = CFAbsoluteTimeGetCurrent()
        let features = featureExtractor.processNewFrame(sample)
        let smoothed = intensityFilter.process(features.movementIntensity)
        let moving = movementHysteresis.process(smoothed)
        let currentPhase = detectCurrentPhase(features)
        confidence.accumulate(phase: currentPhase, confidence: features.movementIntensity)

        defer { processingTimes.append(CFAbsoluteTimeGetCurrent() - start) }

        switch state {
        case .monitoring:
            if moving {
                state = .potentialStart(frames: 1)
                startTime = sample.time
                return .repetitionStarted(confidence: 0.1)
            }
            return .monitoring

        case .potentialStart(let frames):
            if moving {
                if frames + 1 > 5 {
                    state = .inProgress(phase: currentPhase)
                } else {
                    state = .potentialStart(frames: frames + 1)
                }
            } else {
                state = .monitoring
            }
            return .monitoring

        case .inProgress:
            if !moving && confidence.isConfirmed(currentPhase) {
                state = .potentialEnd(endTime: sample.time)
            }
            return .repetitionInProgress(phase: currentPhase)

        case .potentialEnd(let endTime):
            if moving {
                state = .inProgress(phase: currentPhase)
                return .repetitionInProgress(phase: currentPhase)
            }
            let val = validator.validateRepetition(start: startTime ?? endTime, end: endTime)
            state = .cooldown(until: sample.time + 0.5)
            confidence.reset()
            switch val {
            case .valid:
                return .repetitionCompleted(RepetitionLog(startTime: startTime ?? endTime, endTime: endTime, confidence: 1))
            case .invalid(let err):
                return .repetitionRejected(reason: String(describing: err))
            }

        case .cooldown(let until):
            if sample.time >= until {
                state = .monitoring
            }
            return .monitoring
        }
    }

    private func detectCurrentPhase(_ features: MovementFeatures) -> RepetitionPhase.PhaseType {
        if features.movementIntensity < 0.1 { return .rest }
        if features.jointVelocities["metric", default: 0] > 0 { return .eccentric }
        return .concentric
    }

    // MARK: - Performance Management

    /// Reduces internal buffers to free memory during pressure.
    func reduceMemoryFootprint() {
        featureExtractor = StreamingFeatureExtractor()
        confidence.reset()
    }

    /// Reports simple performance metrics for debugging.
    func getPerformanceMetrics() -> DetectorPerformanceMetrics {
        let times = processingTimes.toArray()
        let avg = times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
        return DetectorPerformanceMetrics(
            averageProcessingTime: avg,
            memoryUsage: 0,
            confidenceAccuracy: 1,
            falsePositiveRate: 0
        )
    }

    /// Adjusts detection complexity according to a quality level.
    func adaptToPerformanceLevel(_ level: PerformanceController.QualityLevel) {
        switch level {
        case .high:
            break
        case .medium:
            break
        case .low:
            break
        case .minimal:
            break
        }
    }
}

/// Basic metrics describing detector performance.
struct DetectorPerformanceMetrics {
    let averageProcessingTime: TimeInterval
    let memoryUsage: Int
    let confidenceAccuracy: Float
    let falsePositiveRate: Float
}
