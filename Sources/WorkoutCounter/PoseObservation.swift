import Foundation

#if !canImport(Vision)
/// Minimal stubs to allow building on platforms without the Vision framework.
public struct VNRecognizedPoint: Sendable {
    public let location: CGPoint
    public let confidence: Double

    public init(x: Double, y: Double, confidence: Double) {
        self.location = CGPoint(x: x, y: y)
        self.confidence = confidence
    }
}

public struct VNHumanBodyPoseObservation: Sendable {
    public struct JointName: Hashable, Equatable, RawRepresentable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let root = Self(rawValue: "root")
        public static let neck = Self(rawValue: "neck")
        public static let nose = Self(rawValue: "nose")
        public static let leftEye = Self(rawValue: "leftEye")
        public static let rightEye = Self(rawValue: "rightEye")
        public static let leftEar = Self(rawValue: "leftEar")
        public static let rightEar = Self(rawValue: "rightEar")
        public static let leftShoulder = Self(rawValue: "leftShoulder")
        public static let rightShoulder = Self(rawValue: "rightShoulder")
        public static let leftElbow = Self(rawValue: "leftElbow")
        public static let rightElbow = Self(rawValue: "rightElbow")
        public static let leftWrist = Self(rawValue: "leftWrist")
        public static let rightWrist = Self(rawValue: "rightWrist")
        public static let leftHip = Self(rawValue: "leftHip")
        public static let rightHip = Self(rawValue: "rightHip")
        public static let leftKnee = Self(rawValue: "leftKnee")
        public static let rightKnee = Self(rawValue: "rightKnee")
        public static let leftAnkle = Self(rawValue: "leftAnkle")
        public static let rightAnkle = Self(rawValue: "rightAnkle")
    }

    private var points: [JointName: VNRecognizedPoint]

    public init(points: [JointName: VNRecognizedPoint]) {
        self.points = points
    }

    public func recognizedPoint(_ name: JointName) throws -> VNRecognizedPoint {
        guard let point = points[name] else {
            throw NSError(domain: "VisionStub", code: -1)
        }
        return point
    }
}
#else
import Vision
#endif

/// Platform-agnostic representation of a body pose.
public struct PoseObservation {
    /// Supported joint identifiers matching Vision's joint names.
    public enum JointName: String, Sendable {
        case root
        case neck
        case nose
        case leftEye
        case rightEye
        case leftEar
        case rightEar
        case leftShoulder
        case rightShoulder
        case leftElbow
        case rightElbow
        case leftWrist
        case rightWrist
        case leftHip
        case rightHip
        case leftKnee
        case rightKnee
        case leftAnkle
        case rightAnkle
    }

    /// Location and confidence for a body joint.
    public struct JointPoint: Sendable {
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
#endif

public extension PoseObservation {
    /// Creates a ``PoseObservation`` from a ``VNHumanBodyPoseObservation``.
    init(visionObservation: VNHumanBodyPoseObservation) {
        var mapped: [JointName: JointPoint] = [:]
        let mapping: [(JointName, VNHumanBodyPoseObservation.JointName)] = [
            (.root, .root),
            (.neck, .neck),
            (.nose, .nose),
            (.leftEye, .leftEye),
            (.rightEye, .rightEye),
            (.leftEar, .leftEar),
            (.rightEar, .rightEar),
            (.leftShoulder, .leftShoulder),
            (.rightShoulder, .rightShoulder),
            (.leftElbow, .leftElbow),
            (.rightElbow, .rightElbow),
            (.leftWrist, .leftWrist),
            (.rightWrist, .rightWrist),
            (.leftHip, .leftHip),
            (.rightHip, .rightHip),
            (.leftKnee, .leftKnee),
            (.rightKnee, .rightKnee),
            (.leftAnkle, .leftAnkle),
            (.rightAnkle, .rightAnkle)
        ]
        for (name, vnName) in mapping {
            if let p = try? visionObservation.recognizedPoint(vnName) {
                mapped[name] = JointPoint(
                    x: Double(p.location.x),
                    y: Double(p.location.y),
                    confidence: Double(p.confidence)
                )
            }
        }
        self.init(joints: mapped)
    }
}

/// Converts a ``PoseObservation`` to a ``PoseSample`` using the right elbow
/// angle as the metric.
/// - Parameters:
///   - observation: The pose observation to convert.
///   - time: Timestamp for the resulting sample.
/// - Returns: A ``PoseSample`` value.
public func poseSample(from observation: PoseObservation, at time: TimeInterval) -> PoseSample {
    guard let shoulder = observation.joints[.rightShoulder],
          let elbow = observation.joints[.rightElbow],
          let wrist = observation.joints[.rightWrist] else {
        return PoseSample(time: time, metric: 0)
    }
    let upper = (x: shoulder.x - elbow.x, y: shoulder.y - elbow.y)
    let lower = (x: wrist.x - elbow.x, y: wrist.y - elbow.y)
    let dot = upper.x * lower.x + upper.y * lower.y
    let mag1 = sqrt(upper.x * upper.x + upper.y * upper.y)
    let mag2 = sqrt(lower.x * lower.x + lower.y * lower.y)
    guard mag1 > 0 && mag2 > 0 else {
        return PoseSample(time: time, metric: 0)
    }
    let cosAngle = max(-1.0, min(1.0, dot / (mag1 * mag2)))
    let angle = acos(cosAngle)
    return PoseSample(time: time, metric: angle)
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
