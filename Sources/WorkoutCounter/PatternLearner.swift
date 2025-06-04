import Foundation

/// Represents a learned template for a particular exercise
public struct ExercisePattern {
    public let jointVelocities: [String: Float]
    public let jointAngles: [String: Float]
    public let movementIntensity: Float
    public let symmetry: Float
}

/// Naïve pattern learner that averages features across examples
public final class PatternLearner {
    private var positive: [MovementFeatures] = []
    private var negative: [MovementFeatures] = []

    public init() {}

    public func startLearningSession() {
        positive.removeAll()
        negative.removeAll()
    }

    public func recordPositiveExample(poses: [PoseSample]) {
        positive.append(Self.extractFeatures(from: poses))
    }

    public func recordNegativeExample(poses: [PoseSample]) {
        negative.append(Self.extractFeatures(from: poses))
    }

    public func generatePattern() -> ExercisePattern {
        let count = Float(positive.count)
        guard count > 0 else {
            return ExercisePattern(jointVelocities: [:], jointAngles: [:], movementIntensity: 0, symmetry: 0)
        }
        var velocities: [String: Float] = [:]
        var angles: [String: Float] = [:]
        var intensity: Float = 0
        var symmetry: Float = 0
        for f in positive {
            for (k,v) in f.jointVelocities { velocities[k, default: 0] += v }
            for (k,v) in f.jointAngles { angles[k, default: 0] += v }
            intensity += f.movementIntensity
            symmetry += f.symmetry
        }
        for k in velocities.keys { velocities[k]! /= count }
        for k in angles.keys { angles[k]! /= count }
        return ExercisePattern(
            jointVelocities: velocities,
            jointAngles: angles,
            movementIntensity: intensity / count,
            symmetry: symmetry / count
        )
    }

    // MARK: - Feature Extraction
    static func extractFeatures(from poses: [PoseSample]) -> MovementFeatures {
        guard !poses.isEmpty else {
            return MovementFeatures(jointVelocities: [:], jointAngles: [:], movementIntensity: 0, symmetry: 0)
        }
        var velocities: [Float] = []
        for i in 1..<poses.count {
            let dt = poses[i].time - poses[i-1].time
            if dt > 0 {
                let v = Float((poses[i].metric - poses[i-1].metric)/dt)
                velocities.append(abs(v))
            }
        }
        let avgVel = velocities.reduce(0, +) / Float(max(velocities.count,1))
        let metrics = poses.map { Float($0.metric) }
        let maxMetric = metrics.max() ?? 0
        let minMetric = metrics.min() ?? 0
        let intensity = maxMetric - minMetric
        return MovementFeatures(
            jointVelocities: ["metric": avgVel],
            jointAngles: ["metric": 0],
            movementIntensity: intensity,
            symmetry: 1
        )
    }
}

/// Learns temporal patterns for full motion sequences
public final class TemporalPatternLearner {
    private var exampleSequences: [TemporalFeatures] = []

    public init() {}

    public func recordExampleSequence(_ poses: [PoseSample]) {
        let temporal = extractTemporalFeatures(poses)
        exampleSequences.append(temporal)
    }

    public func generateTemporalPattern() -> ExerciseTemporalPattern {
        let durations = exampleSequences.map { $0.sequenceDuration }
        let avgDuration = durations.reduce(0, +) / Double(max(durations.count, 1))
        let velocityProfiles = exampleSequences.map { $0.velocityProfile }
        let templateVel = velocityProfiles.first ?? []
        return ExerciseTemporalPattern(expectedDuration: avgDuration, velocityTemplate: templateVel)
    }

    private func extractTemporalFeatures(_ poses: [PoseSample]) -> TemporalFeatures {
        guard !poses.isEmpty else {
            return TemporalFeatures(poseSequence: [], phaseDurations: [], velocityProfile: [], accelerationProfile: [], transitionPoints: [], sequenceDuration: 0)
        }
        var velocities: [Float] = []
        var accelerations: [Float] = []
        for i in 1..<poses.count {
            let dt = poses[i].time - poses[i-1].time
            if dt > 0 {
                let v = Float((poses[i].metric - poses[i-1].metric)/dt)
                velocities.append(v)
            } else {
                velocities.append(0)
            }
        }
        for i in 1..<velocities.count {
            let dv = velocities[i] - velocities[i-1]
            accelerations.append(dv)
        }
        let features = Self.extractSequenceFeatures(poses)
        let duration = poses.last!.time - poses.first!.time
        return TemporalFeatures(
            poseSequence: features,
            phaseDurations: [],
            velocityProfile: velocities,
            accelerationProfile: accelerations,
            transitionPoints: [],
            sequenceDuration: duration
        )
    }

    static func extractSequenceFeatures(_ poses: [PoseSample]) -> [MovementFeatures] {
        // compute features once using the full sequence then reuse for each frame
        let features = PatternLearner.extractFeatures(from: poses)
        return Array(repeating: features, count: poses.count)
    }
}

/// Represents a simplified temporal pattern template
public struct ExerciseTemporalPattern {
    public let expectedDuration: TimeInterval
    public let velocityTemplate: [Float]
}
