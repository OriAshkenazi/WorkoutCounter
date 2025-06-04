import Foundation

/// Time-stamped pose information for live processing.
public struct PoseFrame: Sendable {
    /// Capture time of the frame in seconds.
    public let time: TimeInterval
    /// Mapping of body joints detected in the frame.
    public let joints: [PoseObservation.JointName: PoseObservation.JointPoint]

    public init(time: TimeInterval, joints: [PoseObservation.JointName: PoseObservation.JointPoint]) {
        self.time = time
        self.joints = joints
    }
}

public extension PoseFrame {
    /// Initialize from a ``PoseObservation`` and timestamp.
    init(time: TimeInterval, observation: PoseObservation) {
        self.init(time: time, joints: observation.joints)
    }

    /// Converts the frame into a legacy ``PoseSample`` value.
    /// - Returns: ``PoseSample`` using the right elbow angle metric.
    func toPoseSample() -> PoseSample {
        poseSample(from: PoseObservation(joints: joints), at: time)
    }
}
