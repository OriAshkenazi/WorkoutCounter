import Foundation

private func joints(for angle: Double) -> [PoseObservation.JointName: PoseObservation.JointPoint] {
    let shoulder = PoseObservation.JointPoint(x: 1, y: 0, confidence: 1)
    let elbow = PoseObservation.JointPoint(x: 0, y: 0, confidence: 1)
    let wrist = PoseObservation.JointPoint(x: cos(angle), y: sin(angle), confidence: 1)
    return [
        .rightShoulder: shoulder,
        .rightElbow: elbow,
        .rightWrist: wrist
    ]
}

/// Generates a simple sequence of pose samples representing up and down motion.
/// - Parameters:
///   - repetitions: Number of repetitions in the sequence.
///   - step: Time difference between samples.
/// - Returns: Array of `PoseSample` values.
public func generateMockPoseFrames(repetitions: Int, step: TimeInterval = 0.1) -> [PoseFrame] {
    var frames: [PoseFrame] = []
    var time: TimeInterval = 0
    for _ in 0..<repetitions {
        frames.append(PoseFrame(time: time, joints: joints(for: 1.0)))
        time += step
        frames.append(PoseFrame(time: time, joints: joints(for: 0.0)))
        time += step
        frames.append(PoseFrame(time: time, joints: joints(for: 1.0)))
        time += step
        // rest period
        frames.append(PoseFrame(time: time, joints: joints(for: 0.0)))
        time += step
    }
    return frames
}

public func generateMockPoseData(repetitions: Int, step: TimeInterval = 0.1) -> [PoseSample] {
    return generateMockPoseFrames(repetitions: repetitions, step: step).map { $0.toPoseSample() }
}

/// Generates a stream with noise and varying speed for integration tests.
public func generateRealisticPoseFrameStream(repetitions: Int, noiseLevel: Double, speedVariation: Double) -> [PoseFrame] {
    var frames: [PoseFrame] = []
    var time: TimeInterval = 0
    for _ in 0..<repetitions {
        let varStep = 0.1 * (1 + Double.random(in: -speedVariation...speedVariation))
        frames.append(PoseFrame(time: time, joints: joints(for: 1.0 + Double.random(in: -noiseLevel...noiseLevel))))
        time += varStep
        frames.append(PoseFrame(time: time, joints: joints(for: Double.random(in: -noiseLevel...noiseLevel))))
        time += varStep
        frames.append(PoseFrame(time: time, joints: joints(for: 1.0 + Double.random(in: -noiseLevel...noiseLevel))))
        time += varStep
    }
    return frames
}

/// Generates a noisy stream with false movements for robustness tests.
public func generateNoisyPoseFrameStream(baseRepetitions: Int, noiseSpikes: Int, falseMovements: Int) -> [PoseFrame] {
    var stream = generateRealisticPoseFrameStream(repetitions: baseRepetitions, noiseLevel: 0.05, speedVariation: 0)
    var time = stream.last?.time ?? 0
    for _ in 0..<noiseSpikes {
        time += 0.05
        stream.append(PoseFrame(time: time, joints: joints(for: Double.random(in: -1...1))))
    }
    for _ in 0..<falseMovements {
        time += 0.1
        stream.append(PoseFrame(time: time, joints: joints(for: 0.5)))
    }
    return stream
}

/// Generates a long neutral pose stream for memory tests.
public func generateLongPoseFrameStream(duration: TimeInterval) -> [PoseFrame] {
    var samples: [PoseFrame] = []
    var time: TimeInterval = 0
    while time < duration {
        samples.append(PoseFrame(time: time, joints: joints(for: sin(time))))
        time += 0.1
    }
    return samples
}

public func generateHighFrequencyFrameStream(sampleCount: Int) -> [PoseFrame] {
    var samples: [PoseFrame] = []
    for i in 0..<sampleCount {
        let t = Double(i) * 0.033
        samples.append(PoseFrame(time: t, joints: joints(for: sin(t))))
    }
    return samples
}

public func generateHighFrequencyStream(sampleCount: Int) -> [PoseSample] {
    return generateHighFrequencyFrameStream(sampleCount: sampleCount).map { $0.toPoseSample() }
}

public func generateLongFrameStream(sampleCount: Int) -> [PoseFrame] {
    var samples: [PoseFrame] = []
    for i in 0..<sampleCount {
        samples.append(PoseFrame(time: Double(i) * 0.033, joints: joints(for: Double.random(in: -1...1))))
    }
    return samples
}

public func generateLongStream(sampleCount: Int) -> [PoseSample] {
    return generateLongFrameStream(sampleCount: sampleCount).map { $0.toPoseSample() }
}

public func generateHighComplexityFrameStream() -> [PoseFrame] {
    var samples: [PoseFrame] = []
    var time: TimeInterval = 0
    for _ in 0..<1000 {
        samples.append(PoseFrame(time: time, joints: joints(for: Double.random(in: -1...1))))
        time += 0.016
    }
    return samples
}

public func generateHighComplexityStream() -> [PoseSample] {
    return generateHighComplexityFrameStream().map { $0.toPoseSample() }
}
