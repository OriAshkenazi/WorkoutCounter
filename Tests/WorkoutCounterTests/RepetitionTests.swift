import Testing
@testable import WorkoutCounter

@Test
func repetitionDetection() async throws {
    let samples = generateMockPoseData(repetitions: 3)
    let detector = RepetitionDetector()
    var count = 0
    for sample in samples {
        if detector.process(sample: sample) != nil {
            count += 1
        }
    }
    #expect(count == 3)
}

@Test
func sessionAnalytics() async throws {
    let samples = generateMockPoseData(repetitions: 2)
    let detector = RepetitionDetector()
    let manager = SessionManager()
    manager.startSession(exerciseType: "test")
    for sample in samples {
        if let rep = detector.process(sample: sample) {
            manager.logRepetition(startOffset: rep.start, endOffset: rep.end, confidence: 1.0)
        }
        manager.updateIntensity(sample.metric, at: sample.time)
    }
    manager.endSession()
    #expect(manager.sessions.count == 1)
    #expect(manager.sessions[0].repetitions.count == 2)
    #expect(!manager.sessionAnalytics.restDurations.isEmpty)
}
