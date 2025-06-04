import Foundation
import CoreFoundation

/// High level engine that coordinates streaming processing.
final class StreamingWorkoutEngine {
    private let detector: StreamingRepetitionDetector
    private let memoryManager = MemoryManager()
    private let performance = PerformanceController()
    private let sessionManager = SessionManager()

    init(pattern: ExerciseTemporalPattern) {
        detector = StreamingRepetitionDetector(pattern: pattern)
    }

    enum WorkoutUpdate {
        case frameSkipped
        case noEvent
        case repetitionLogged(RepetitionLog)
    }

    func processFrame(_ sample: PoseSample) -> WorkoutUpdate {
        let start = CFAbsoluteTimeGetCurrent()
        let result = detector.processFrame(sample)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        performance.recordFrameTime(elapsed)
        if memoryManager.shouldReduceQuality() {
            memoryManager.optimizeMemoryUsage()
        }
        switch result {
        case .repetitionCompleted(let log):
            sessionManager.logRepetition(startOffset: log.startTime, endOffset: log.endTime, confidence: log.confidence)
            return .repetitionLogged(log)
        default:
            return .noEvent
        }
    }
}
