import Foundation

/// Tracks processing performance and suggests quality levels.
final class PerformanceController {
    private var frameTimes = CircularBuffer<TimeInterval>(capacity: 60)
    private let target: TimeInterval = 1.0 / 30.0

    enum QualityLevel {
        case high
        case medium
        case low
        case minimal
    }

    func recordFrameTime(_ duration: TimeInterval) {
        frameTimes.append(duration)
    }

    func getOptimalQuality() -> QualityLevel {
        let samples = frameTimes.toArray()
        guard !samples.isEmpty else { return .high }
        let avg = samples.reduce(0, +) / Double(samples.count)
        if avg < target * 0.8 { return .high }
        if avg < target * 1.2 { return .medium }
        if avg < target * 1.5 { return .low }
        return .minimal
    }
}
