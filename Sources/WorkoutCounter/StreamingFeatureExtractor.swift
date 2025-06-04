import Foundation

/// Extracts movement features from streaming pose data using a sliding window.
struct StreamingFeatureExtractor {
    private var buffer: CircularPoseBuffer
    private var cached: [TimeInterval: MovementFeatures] = [:]

    init(bufferSize: Int = 180) {
        buffer = CircularPoseBuffer(capacity: bufferSize)
    }

    mutating func processNewFrame(_ sample: PoseSample) -> MovementFeatures {
        buffer.append(sample)
        let recent = buffer.getRecentFrames(3)
        let features = Self.extractMovementFeatures(recent)
        cached[sample.time] = features
        cleanupOldFeatures(olderThan: sample.time - 10.0)
        return features
    }

    private mutating func cleanupOldFeatures(olderThan cutoff: TimeInterval) {
        cached = cached.filter { $0.key >= cutoff }
    }

    private static func extractMovementFeatures(_ frames: [PoseSample]) -> MovementFeatures {
        guard !frames.isEmpty else {
            return MovementFeatures(jointVelocities: [:], jointAngles: [:], movementIntensity: 0, symmetry: 0)
        }
        var velocities: [Float] = []
        for i in 1..<frames.count {
            let dt = frames[i].time - frames[i-1].time
            if dt > 0 {
                let v = Float((frames[i].metric - frames[i-1].metric)/dt)
                velocities.append(v)
            }
        }
        let avgVel = velocities.reduce(0, +) / Float(max(velocities.count,1))
        let rms = sqrt(velocities.map { $0 * $0 }.reduce(0, +) / Float(max(velocities.count,1)))
        return MovementFeatures(jointVelocities: ["metric": avgVel], jointAngles: [:], movementIntensity: rms, symmetry: 1)
    }
}
