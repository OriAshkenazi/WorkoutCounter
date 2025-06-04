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

/// Compares extracted features to a learned exercise pattern. Returns a score 0...1.
public func matchAgainstPattern(_ features: MovementFeatures, pattern: ExercisePattern) -> Float {
    var score: Float = 0
    // compare movement intensity
    let diff = abs(features.movementIntensity - pattern.movementIntensity)
    let intensityScore = max(0, 1 - diff)
    score += intensityScore
    // compare average velocity if available
    if let fVel = features.jointVelocities["metric"], let pVel = pattern.jointVelocities["metric"] {
        let velDiff = abs(fVel - pVel)
        score += max(0, 1 - velDiff)
    }
    // symmetry currently constant
    score += 1 - abs(features.symmetry - pattern.symmetry)
    return score / 3
}
