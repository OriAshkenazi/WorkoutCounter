import Foundation

/// Tracks processing performance and suggests quality levels.
public final class PerformanceController {
    private var frameTimes = CircularBuffer<TimeInterval>(capacity: 60)
    private let target: TimeInterval = 1.0 / 30.0
    private(set) var currentQuality: QualityLevel = .high

    public enum QualityLevel {
        case high
        case medium
        case low
        case minimal
    }

    public func recordFrameTime(_ duration: TimeInterval) {
        frameTimes.append(duration)
    }

    public func getOptimalQuality() -> QualityLevel {
        let samples = frameTimes.toArray()
        guard !samples.isEmpty else { return .high }
        let avg = samples.reduce(0, +) / Double(samples.count)
        if avg < target * 0.8 { return .high }
        if avg < target * 1.2 { return .medium }
        if avg < target * 1.5 { return .low }
        return .minimal
    }

    /// Adjusts internal tracking buffers to the specified quality level.
    public func adaptToPerformanceLevel(_ level: QualityLevel) {
        currentQuality = level
        switch level {
        case .high:
            frameTimes = CircularBuffer(capacity: 60)
        case .medium:
            frameTimes = CircularBuffer(capacity: 45)
        case .low:
            frameTimes = CircularBuffer(capacity: 30)
        case .minimal:
            frameTimes = CircularBuffer(capacity: 15)
        }
    }
}
