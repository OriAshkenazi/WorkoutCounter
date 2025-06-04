import Foundation
import CoreFoundation

/// High level engine that coordinates streaming processing.
final class StreamingWorkoutEngine {
    private let detector: ProductionRepetitionDetector
    private let memoryManager: MemoryManager
    private let performanceController: PerformanceController
    private let sessionManager = SessionManager()

    init(exercisePattern: ExercisePattern? = nil) {
        self.detector = ProductionRepetitionDetector()
        self.memoryManager = MemoryManager()
        self.performanceController = PerformanceController()
        detector.adaptToPerformanceLevel(.high)
    }

    enum WorkoutUpdate {
        case frameSkipped(reason: FrameSkipReason)
        case noEvent
        case repetitionLogged(RepetitionLog)
    }

    enum FrameSkipReason { case performanceOptimization }

    func processFrame(_ sample: PoseSample) -> WorkoutUpdate {
        let start = CFAbsoluteTimeGetCurrent()

        let quality = performanceController.getOptimalQuality()
        detector.adaptToPerformanceLevel(quality)

        guard shouldProcessFrame(sample, quality: quality) else {
            return .frameSkipped(reason: .performanceOptimization)
        }

        let result = detector.processFrame(sample)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        performanceController.recordFrameTime(elapsed)

        if memoryManager.shouldReduceQuality() {
            memoryManager.optimizeMemoryUsage()
            detector.reduceMemoryFootprint()
        }

        return convertToWorkoutUpdate(result)
    }

    private func convertToWorkoutUpdate(_ result: StreamingResult) -> WorkoutUpdate {
        switch result {
        case .repetitionCompleted(let log):
            sessionManager.logRepetition(startOffset: log.startTime, endOffset: log.endTime, confidence: log.confidence)
            return .repetitionLogged(log)
        case .repetitionStarted, .repetitionInProgress, .monitoring:
            return .noEvent
        case .repetitionRejected:
            return .noEvent
        }
    }

    private func shouldProcessFrame(_ sample: PoseSample, quality: PerformanceController.QualityLevel) -> Bool {
        _ = quality
        return true
    }
}
