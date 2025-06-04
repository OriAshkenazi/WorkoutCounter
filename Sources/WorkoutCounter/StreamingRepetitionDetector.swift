import Foundation

/// State machine that detects repetitions from streaming pose data.
final class StreamingRepetitionDetector {
    private var featureExtractor = StreamingFeatureExtractor()
    private let sequenceDetector: SequenceDetector
    private var state: DetectionState = .monitoring
    private var activeStart: TimeInterval?

    enum DetectionState {
        case monitoring
        case inProgress(startTime: TimeInterval)
        case cooldown(until: TimeInterval)
    }

    init(pattern: ExerciseTemporalPattern) {
        self.sequenceDetector = SequenceDetector(pattern: pattern)
    }

    func processFrame(_ frame: PoseFrame) -> StreamingResult {
        let features = featureExtractor.processNewFrame(frame)
        switch state {
        case .monitoring:
            if features.movementIntensity > 0.1 {
                state = .inProgress(startTime: frame.time)
                activeStart = frame.time
                return .repetitionStarted(confidence: 1)
            }
            return .monitoring

        case .inProgress(let startTime):
            let result = sequenceDetector.processFrame(features)
            switch result {
            case .completed(let conf):
                state = .cooldown(until: frame.time + 0.5)
                let log = RepetitionLog(startTime: startTime, endTime: frame.time, confidence: conf)
                return .repetitionCompleted(log)
            case .inProgress(let phase):
                if features.movementIntensity < 0.05 {
                    state = .cooldown(until: frame.time + 0.5)
                    let log = RepetitionLog(startTime: startTime, endTime: frame.time, confidence: 1)
                    return .repetitionCompleted(log)
                }
                return .repetitionInProgress(phase: phase)
            }

        case .cooldown(let until):
            if frame.time >= until {
                state = .monitoring
            }
            return .monitoring
        }
    }
}

/// Stream processing results
enum StreamingResult {
    case monitoring
    case repetitionStarted(confidence: Float)
    case repetitionInProgress(phase: RepetitionPhase.PhaseType)
    case repetitionCompleted(RepetitionLog)
    case repetitionRejected(reason: String)
}
