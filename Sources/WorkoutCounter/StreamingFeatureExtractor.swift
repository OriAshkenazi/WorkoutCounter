import Foundation

/// Extracts movement features from streaming pose data using a sliding window.
struct StreamingFeatureExtractor {
    private var buffer: CircularPoseBuffer
    private var cached: [TimeInterval: MovementFeatures] = [:]

    init(bufferSize: Int = 180) {
        buffer = CircularPoseBuffer(capacity: bufferSize)
    }

    mutating func processNewFrame(_ frame: PoseFrame) -> MovementFeatures {
        buffer.append(frame)
        let recent = buffer.getRecentFrames(3)
        let features = Self.extractMovementFeatures(recent)
        cached[frame.time] = features
        cleanupOldFeatures(olderThan: frame.time - 10.0)
        return features
    }

    private mutating func cleanupOldFeatures(olderThan cutoff: TimeInterval) {
        cached = cached.filter { $0.key >= cutoff }
    }

    private static func extractMovementFeatures(_ frames: [PoseFrame]) -> MovementFeatures {
        guard frames.count >= 2 else {
            return MovementFeatures(jointVelocities: [:], jointAngles: [:], movementIntensity: 0, symmetry: 0)
        }

        var velocitySums: [PoseObservation.JointName: Float] = [:]
        var leftTotal: Float = 0
        var rightTotal: Float = 0
        var count: Int = 0

        for i in 1..<frames.count {
            let prev = frames[i-1]
            let cur = frames[i]
            let dt = Float(cur.time - prev.time)
            guard dt > 0 else { continue }
            let joints = Set(prev.joints.keys).intersection(cur.joints.keys)
            for j in joints {
                guard let p1 = prev.joints[j], let p2 = cur.joints[j] else { continue }
                let dx = Float(p2.x - p1.x)
                let dy = Float(p2.y - p1.y)
                let v = sqrt(dx*dx + dy*dy) / dt
                velocitySums[j, default: 0] += v
                if j.rawValue.contains("left") { leftTotal += v } else if j.rawValue.contains("right") { rightTotal += v }
            }
            count += 1
        }

        var velocities: [String: Float] = [:]
        for (j, sum) in velocitySums { velocities[j.rawValue] = sum / Float(max(count,1)) }

        // Provide a generic metric velocity for legacy algorithms
        let avgVel = velocitySums.values.reduce(0, +) / Float(max(velocitySums.count,1))
        velocities["metric"] = avgVel / Float(max(count,1))

        // Joint angles from the latest frame
        let last = frames.last!.joints
        func angle(_ a: PoseObservation.JointName, _ b: PoseObservation.JointName, _ c: PoseObservation.JointName) -> Float? {
            guard let p1 = last[a], let p2 = last[b], let p3 = last[c] else { return nil }
            let v1 = (x: p1.x - p2.x, y: p1.y - p2.y)
            let v2 = (x: p3.x - p2.x, y: p3.y - p2.y)
            let dot = v1.x * v2.x + v1.y * v2.y
            let m1 = sqrt(v1.x * v1.x + v1.y * v1.y)
            let m2 = sqrt(v2.x * v2.x + v2.y * v2.y)
            guard m1 > 0 && m2 > 0 else { return nil }
            let cosv = max(-1.0, min(1.0, dot / (m1 * m2)))
            return Float(acos(cosv))
        }

        var angles: [String: Float] = [:]
        if let a = angle(.leftShoulder, .leftElbow, .leftWrist) { angles["leftElbow"] = a }
        if let a = angle(.rightShoulder, .rightElbow, .rightWrist) { angles["rightElbow"] = a }
        if let a = angle(.leftHip, .leftKnee, .leftAnkle) { angles["leftKnee"] = a }
        if let a = angle(.rightHip, .rightKnee, .rightAnkle) { angles["rightKnee"] = a }

        let velocityValues = Array(velocitySums.values)
        let rms = velocityValues.isEmpty ? 0 : sqrt(velocityValues.map { $0 * $0 }.reduce(0, +) / Float(velocityValues.count)) / Float(max(count,1))

        let symmetry: Float
        if max(leftTotal, rightTotal) > 0 {
            symmetry = min(leftTotal, rightTotal) / max(leftTotal, rightTotal)
        } else {
            symmetry = 1
        }

        return MovementFeatures(jointVelocities: velocities, jointAngles: angles, movementIntensity: rms, symmetry: symmetry)
    }
}
