import Foundation

/// Applies hysteresis to a boolean state based on high and low thresholds.
struct HysteresisFilter {
    private(set) var state: Bool = false
    private let high: Float
    private let low: Float

    init(low: Float, high: Float) {
        self.low = low
        self.high = high
    }

    mutating func process(_ value: Float) -> Bool {
        if state {
            if value < low { state = false }
        } else {
            if value > high { state = true }
        }
        return state
    }
}

/// Smooths noisy values using an exponential moving average.
struct TemporalSmoothingFilter {
    private var history: CircularBuffer<Float>
    private let factor: Float

    init(windowSize: Int = 5, smoothingFactor: Float = 0.3) {
        history = CircularBuffer(capacity: windowSize)
        factor = smoothingFactor
    }

    mutating func process(_ value: Float) -> Float {
        history.append(value)
        let values = history.toArray()
        guard var result = values.first else { return value }
        for v in values.dropFirst() {
            result = factor * v + (1 - factor) * result
        }
        return result
    }
}
