import Foundation

/// Generates a simple sequence of pose samples representing up and down motion.
/// - Parameters:
///   - repetitions: Number of repetitions in the sequence.
///   - step: Time difference between samples.
/// - Returns: Array of `PoseSample` values.
public func generateMockPoseData(repetitions: Int, step: TimeInterval = 0.1) -> [PoseSample] {
    var samples: [PoseSample] = []
    var time: TimeInterval = 0
    for _ in 0..<repetitions {
        samples.append(PoseSample(time: time, metric: 1.0))
        time += step
        samples.append(PoseSample(time: time, metric: 0.0))
        time += step
        samples.append(PoseSample(time: time, metric: 1.0))
        time += step
        // rest period
        samples.append(PoseSample(time: time, metric: 0.0))
        time += step
    }
    return samples
}

/// Generates a stream with noise and varying speed for integration tests.
public func generateRealisticPoseStream(repetitions: Int, noiseLevel: Double, speedVariation: Double) -> [PoseSample] {
    var samples: [PoseSample] = []
    var time: TimeInterval = 0
    for _ in 0..<repetitions {
        let varStep = 0.1 * (1 + Double.random(in: -speedVariation...speedVariation))
        samples.append(PoseSample(time: time, metric: 1.0 + Double.random(in: -noiseLevel...noiseLevel)))
        time += varStep
        samples.append(PoseSample(time: time, metric: Double.random(in: -noiseLevel...noiseLevel)))
        time += varStep
        samples.append(PoseSample(time: time, metric: 1.0 + Double.random(in: -noiseLevel...noiseLevel)))
        time += varStep
    }
    return samples
}

/// Generates a noisy stream with false movements for robustness tests.
public func generateNoisyPoseStream(baseRepetitions: Int, noiseSpikes: Int, falseMovements: Int) -> [PoseSample] {
    var stream = generateRealisticPoseStream(repetitions: baseRepetitions, noiseLevel: 0.05, speedVariation: 0)
    var time = stream.last?.time ?? 0
    for _ in 0..<noiseSpikes {
        time += 0.05
        stream.append(PoseSample(time: time, metric: Double.random(in: -1...1)))
    }
    for _ in 0..<falseMovements {
        time += 0.1
        stream.append(PoseSample(time: time, metric: 0.5))
    }
    return stream
}

/// Generates a long neutral pose stream for memory tests.
public func generateLongPoseStream(duration: TimeInterval) -> [PoseSample] {
    var samples: [PoseSample] = []
    var time: TimeInterval = 0
    while time < duration {
        samples.append(PoseSample(time: time, metric: sin(time)))
        time += 0.1
    }
    return samples
}

public func generateHighFrequencyStream(sampleCount: Int) -> [PoseSample] {
    var samples: [PoseSample] = []
    for i in 0..<sampleCount {
        let t = Double(i) * 0.033
        samples.append(PoseSample(time: t, metric: sin(t)))
    }
    return samples
}

public func generateLongStream(sampleCount: Int) -> [PoseSample] {
    var samples: [PoseSample] = []
    for i in 0..<sampleCount {
        samples.append(PoseSample(time: Double(i) * 0.033, metric: Double.random(in: -1...1)))
    }
    return samples
}

public func generateHighComplexityStream() -> [PoseSample] {
    var samples: [PoseSample] = []
    var time: TimeInterval = 0
    for _ in 0..<1000 {
        samples.append(PoseSample(time: time, metric: Double.random(in: -1...1)))
        time += 0.016
    }
    return samples
}
