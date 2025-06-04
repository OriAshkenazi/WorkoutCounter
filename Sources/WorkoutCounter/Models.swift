import Foundation

public struct RepetitionLog {
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let confidence: Float
}

public struct WorkoutSession {
    public let exerciseType: String
    public let startTime: Date
    public var endTime: Date?
    public var repetitions: [RepetitionLog] = []
}

public final class SessionManager {
    public enum State { case idle, running, paused, ended }
    private(set) public var state: State = .idle
    private var session: WorkoutSession?
    private(set) public var sessions: [WorkoutSession] = []
    private var analytics = SessionAnalytics()

    public var sessionAnalytics: SessionAnalytics { analytics }

    public init() {}

    public func startSession(exerciseType: String) {
        guard state == .idle else { return }
        session = WorkoutSession(exerciseType: exerciseType, startTime: Date())
        analytics = SessionAnalytics()
        state = .running
    }

    public func pauseSession() { guard state == .running else { return }; state = .paused }
    public func resumeSession() { guard state == .paused else { return }; state = .running }

    public func updateIntensity(_ intensity: Double, at offset: TimeInterval) {
        guard state == .running else { return }
        analytics.updateMotionIntensity(intensity, at: offset)
    }

    public func endSession() {
        guard state == .running || state == .paused else { return }
        if var current = session {
            current.endTime = Date()
            sessions.append(current)
        }
        session = nil
        state = .ended
    }

    public func logRepetition(startOffset: TimeInterval, endOffset: TimeInterval, confidence: Float) {
        guard state == .running, var current = session else { return }
        let log = RepetitionLog(startTime: startOffset, endTime: endOffset, confidence: confidence)
        current.repetitions.append(log)
        session = current
        analytics.registerRepetition(start: startOffset, end: endOffset)
    }
}

/// Describes key metrics extracted from a motion sequence
public struct MovementFeatures {
    public let jointVelocities: [String: Float]
    public let jointAngles: [String: Float]
    public let movementIntensity: Float
    public let symmetry: Float
}

/// Captures temporal metrics for a full motion sequence
public struct TemporalFeatures {
    public let poseSequence: [MovementFeatures]
    public let phaseDurations: [TimeInterval]
    public let velocityProfile: [Float]
    public let accelerationProfile: [Float]
    public let transitionPoints: [Int]
    public let sequenceDuration: TimeInterval
}

/// Describes a single phase within a repetition
public struct RepetitionPhase: Equatable {
    public enum PhaseType {
        case rest, starting, eccentric, peak, concentric, ending
    }
    public let type: PhaseType
    public let startFrame: Int
    public let endFrame: Int
    public let confidence: Float
}
