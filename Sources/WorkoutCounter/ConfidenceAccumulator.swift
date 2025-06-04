import Foundation

/// Accumulates per-phase confidence over multiple frames.
struct ConfidenceAccumulator {
    private var buffers: [RepetitionPhase.PhaseType: CircularBuffer<Float>] = [:]
    private let requiredFrames: Int
    private let threshold: Float

    init(requiredFrames: Int = 3, threshold: Float = 0.7) {
        self.requiredFrames = requiredFrames
        self.threshold = threshold
    }

    mutating func accumulate(phase: RepetitionPhase.PhaseType, confidence: Float) {
        if buffers[phase] == nil {
            buffers[phase] = CircularBuffer(capacity: requiredFrames)
        }
        buffers[phase]?.append(confidence)
    }

    func isConfirmed(_ phase: RepetitionPhase.PhaseType) -> Bool {
        guard let buf = buffers[phase] else { return false }
        let vals = buf.toArray()
        guard vals.count >= requiredFrames else { return false }
        let avg = vals.reduce(0, +) / Float(vals.count)
        return avg >= threshold
    }

    mutating func reset() {
        buffers.removeAll()
    }
}
