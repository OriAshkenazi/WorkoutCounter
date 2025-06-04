import Testing
import Foundation
@testable import WorkoutCounter

@Test
func realTimePerformance() async throws {
    let detector = ProductionRepetitionDetector()
    let samples = generateHighFrequencyFrameStream(sampleCount: 1000)
    for s in samples { _ = detector.processFrame(s) }
}

@Test
func memoryPerformance() async throws {
    let detector = ProductionRepetitionDetector()
    let samples = generateLongFrameStream(sampleCount: 1000)
    for s in samples { _ = detector.processFrame(s) }
}

@Test
func adaptiveQualityPerformance() async throws {
    let engine = StreamingWorkoutEngine(exercisePattern: nil)
    let samples = generateHighComplexityFrameStream()
    for s in samples { _ = engine.processFrame(s) }
}
