import Foundation

/// Platform-agnostic representation of a body pose.
public struct PoseObservation {
    /// Supported joint identifiers.
    public enum JointName: String {
        case rightWrist
        case rightShoulder
    }

    /// Location and confidence for a body joint.
    public struct JointPoint {
        public let x: Double
        public let y: Double
        public let confidence: Double

        public init(x: Double, y: Double, confidence: Double) {
            self.x = x
            self.y = y
            self.confidence = confidence
        }
    }

    /// Dictionary of joints indexed by ``JointName``.
    public var joints: [JointName: JointPoint]

    public init(joints: [JointName: JointPoint]) {
        self.joints = joints
    }
}

#if canImport(Vision)
import Vision

public extension PoseObservation {
    /// Creates a ``PoseObservation`` from a ``VNHumanBodyPoseObservation``.
    init(visionObservation: VNHumanBodyPoseObservation) {
        var mapped: [JointName: JointPoint] = [:]
        if let wrist = try? visionObservation.recognizedPoint(.rightWrist) {
            mapped[.rightWrist] = JointPoint(
                x: Double(wrist.location.x),
                y: Double(wrist.location.y),
                confidence: Double(wrist.confidence)
            )
        }
        if let shoulder = try? visionObservation.recognizedPoint(.rightShoulder) {
            mapped[.rightShoulder] = JointPoint(
                x: Double(shoulder.location.x),
                y: Double(shoulder.location.y),
                confidence: Double(shoulder.confidence)
            )
        }
        self.init(joints: mapped)
    }
}
#endif

/// Converts a ``PoseObservation`` to a ``PoseSample`` using the vertical
/// distance between the right shoulder and wrist as the metric.
/// - Parameters:
///   - observation: The pose observation to convert.
///   - time: Timestamp for the resulting sample.
/// - Returns: A ``PoseSample`` value.
public func poseSample(from observation: PoseObservation, at time: TimeInterval) -> PoseSample {
    guard let wrist = observation.joints[.rightWrist],
          let shoulder = observation.joints[.rightShoulder] else {
        return PoseSample(time: time, metric: 0)
    }
    let metric = wrist.y - shoulder.y
    return PoseSample(time: time, metric: metric)
}

/// Extracts ``MovementFeatures`` from a ``PoseObservation`` using
/// the average joint confidence as movement intensity.
/// - Parameter observation: The pose observation to analyze.
/// - Returns: ``MovementFeatures`` describing the observation.
public func movementFeatures(from observation: PoseObservation) -> MovementFeatures {
    let confidences = observation.joints.values.map { Float($0.confidence) }
    let intensity = confidences.reduce(0, +) / Float(max(confidences.count, 1))
    return MovementFeatures(jointVelocities: [:], jointAngles: [:], movementIntensity: intensity, symmetry: 1)
}
