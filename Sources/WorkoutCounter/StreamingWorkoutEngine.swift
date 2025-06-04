import Foundation
import CoreFoundation

/// High level engine that coordinates streaming processing.
public final class StreamingWorkoutEngine {
    private let detector: ProductionRepetitionDetector
    private let memoryManager: MemoryManager
    private let performanceController: PerformanceController
    private let sessionManager = SessionManager()
    private var lastProcessedTime: TimeInterval = 0

    public init(exercisePattern: ExercisePattern? = nil) {
        self.detector = ProductionRepetitionDetector(pattern: exercisePattern)
        self.memoryManager = MemoryManager()
        self.performanceController = PerformanceController()
        detector.adaptToPerformanceLevel(.high)
        performanceController.adaptToPerformanceLevel(.high)
    }

    public enum WorkoutUpdate {
        case frameSkipped(reason: FrameSkipReason)
        case noEvent
        case repetitionLogged(RepetitionLog)
    }

  public enum FrameSkipReason { case performanceOptimization }

    public func processFrame(_ frame: PoseFrame) -> WorkoutUpdate {
        let start = CFAbsoluteTimeGetCurrent()

        let quality = performanceController.getOptimalQuality()
        detector.adaptToPerformanceLevel(quality)
        performanceController.adaptToPerformanceLevel(quality)

        guard shouldProcessFrame(frame, quality: quality) else {
            return .frameSkipped(reason: .performanceOptimization)
        }

        let result = detector.processFrame(frame)
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

    public func shouldProcessFrame(_ sample: PoseFrame, quality: PerformanceController.QualityLevel) -> Bool {
        let interval: TimeInterval
        switch quality {
        case .high:
            interval = 0
        case .medium:
            interval = 0.033
        case .low:
            interval = 0.066
        case .minimal:
            return false
        }
        guard sample.time - lastProcessedTime >= interval else { return false }
        lastProcessedTime = sample.time
        return true
    }

    /// Records Vision processing duration for performance metrics.
    public func recordVisionProcessingTime(_ duration: TimeInterval) {
        detector.recordVisionProcessingTime(duration)
    }

    /// Retrieves aggregated detector performance metrics.
    func getDetectorMetrics() -> DetectorPerformanceMetrics {
        return detector.getPerformanceMetrics()
    }
}
