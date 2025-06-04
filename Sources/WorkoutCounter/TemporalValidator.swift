import Foundation

/// Validates timing constraints for repetitions and phases.
struct TemporalValidator {
    static let minRepetitionDuration: TimeInterval = 0.8
    static let maxRepetitionDuration: TimeInterval = 10.0
    static let minPhaseDuration: TimeInterval = 0.2

    func validateRepetition(start: TimeInterval, end: TimeInterval) -> ValidationResult {
        let duration = end - start
        if duration < Self.minRepetitionDuration { return .invalid(.tooFast(duration)) }
        if duration > Self.maxRepetitionDuration { return .invalid(.tooSlow(duration)) }
        return .valid
    }

    enum ValidationResult {
        case valid
        case invalid(ValidationError)
    }

    enum ValidationError {
        case tooFast(TimeInterval)
        case tooSlow(TimeInterval)
    }
}
