import Foundation

public struct PoseSample {
    public let time: TimeInterval
    public let metric: Double
    public init(time: TimeInterval, metric: Double) {
        self.time = time
        self.metric = metric
    }
}

public final class RepetitionDetector {
    public var lowThreshold: Double
    public var highThreshold: Double
    private var isDown = false
    private var currentStart: TimeInterval?

    public init(lowThreshold: Double = 0.2, highThreshold: Double = 0.8) {
        self.lowThreshold = lowThreshold
        self.highThreshold = highThreshold
    }

    /// Returns a tuple of start/end timestamps when a repetition is detected.
    public func process(sample: PoseSample) -> (start: TimeInterval, end: TimeInterval)? {
        if !isDown {
            if sample.metric <= lowThreshold {
                isDown = true
                currentStart = sample.time
            }
        } else {
            if sample.metric >= highThreshold, let start = currentStart {
                isDown = false
                currentStart = nil
                return (start: start, end: sample.time)
            }
        }
        return nil
    }
}
