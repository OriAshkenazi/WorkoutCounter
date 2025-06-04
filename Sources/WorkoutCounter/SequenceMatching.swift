import Foundation

struct DTWMatcher {
    static func alignSequences(_ observed: [MovementFeatures], _ template: [MovementFeatures]) -> Float {
        guard !observed.isEmpty && !template.isEmpty else { return 0 }
        let n = observed.count
        let m = template.count
        var dtw = Array(repeating: Array(repeating: Float.infinity, count: m+1), count: n+1)
        dtw[0][0] = 0
        for i in 1...n {
            for j in 1...m {
                let cost = abs(observed[i-1].movementIntensity - template[j-1].movementIntensity)
                let minPrev = min(dtw[i-1][j], dtw[i][j-1], dtw[i-1][j-1])
                dtw[i][j] = cost + minPrev
            }
        }
        let maxCost = Float(n + m)
        return max(0, 1 - dtw[n][m] / maxCost)
    }

    static func extractPhases(_ sequence: [MovementFeatures]) -> [RepetitionPhase] {
        guard !sequence.isEmpty else { return [] }
        var phases: [RepetitionPhase] = []
        var start = 0
        var current = RepetitionPhase.PhaseType.rest
        for i in 1..<sequence.count {
            let diff = sequence[i].movementIntensity - sequence[i-1].movementIntensity
            let newPhase: RepetitionPhase.PhaseType = diff > 0 ? .eccentric : .concentric
            if newPhase != current {
                phases.append(RepetitionPhase(type: current, startFrame: start, endFrame: i-1, confidence: 1))
                start = i-1
                current = newPhase
            }
        }
        phases.append(RepetitionPhase(type: current, startFrame: start, endFrame: sequence.count-1, confidence: 1))
        return phases
    }
}

func detectMovementPhase(_ current: MovementFeatures, _ previous: [MovementFeatures]) -> RepetitionPhase.PhaseType {
    guard let last = previous.last else { return .starting }
    let velocity = current.movementIntensity - last.movementIntensity
    if abs(velocity) < 0.01 { return .rest }
    if velocity > 0 { return .eccentric } else { return .concentric }
}

struct VelocityProfile {
    let profile: [Float]
}

func analyzeVelocityProfile(_ sequence: [MovementFeatures]) -> VelocityProfile {
    var profile: [Float] = []
    for i in 1..<sequence.count {
        let v = sequence[i].movementIntensity - sequence[i-1].movementIntensity
        profile.append(Float(v))
    }
    return VelocityProfile(profile: profile)
}
