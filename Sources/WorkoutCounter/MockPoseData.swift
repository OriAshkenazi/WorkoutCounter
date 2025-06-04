import Foundation

/// Generates a simple sequence of pose samples representing up and down motion.
/// - Parameters:
///   - repetitions: Number of repetitions in the sequence.
///   - step: Time difference between samples.
/// - Returns: Array of `PoseSample` values.
public func generateMockPoseData(repetitions: Int, step: TimeInterval = 0.1) -> [PoseSample] {
    var samples: [PoseSample] = []
    var time: TimeInterval = 0
    for _ in 0..<repetitions {
        // go down
        samples.append(PoseSample(time: time, metric: 1.0))
        time += step
        samples.append(PoseSample(time: time, metric: 0.0))
        time += step
        // come up
        samples.append(PoseSample(time: time, metric: 1.0))
        time += step
    }
    return samples
}
