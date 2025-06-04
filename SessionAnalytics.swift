import Foundation

class SessionAnalytics {
    private(set) var restDurations: [TimeInterval] = []
    private var lastRepEnd: TimeInterval?
    private var restStart: TimeInterval?
    private var isResting = false
    var intensityThreshold: Double = 0.1

    func updateMotionIntensity(_ intensity: Double, at offset: TimeInterval) {
        if intensity < intensityThreshold {
            if !isResting {
                restStart = offset
                isResting = true
            }
        } else {
            if isResting {
                if let start = restStart {
                    let duration = offset - start
                    if duration > 0 { restDurations.append(duration) }
                }
                restStart = nil
                isResting = false
            }
        }
    }

    func registerRepetition(start: TimeInterval, end: TimeInterval) {
        if let lastEnd = lastRepEnd {
            let duration = start - lastEnd
            if duration > 0 { restDurations.append(duration) }
        }
        lastRepEnd = end
        restStart = nil
        isResting = false
    }
}
