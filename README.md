# WorkoutCounter

WorkoutCounter is a Swift package for counting workout repetitions using pose metrics. It provides lightweight algorithms for detecting motion phases and learning exercise patterns. The code is completely platform agnostic so that it can be integrated on iOS or other Swift environments.

## Project Overview

The library processes temporal pose data to detect when a full repetition has occurred. It includes utilities for learning patterns from example repetitions and for aligning new sequences with previously learned templates. The design is modular so that pose capture can be provided by any vision system.

## Current Implementation Status

- **Temporal sequence detection** with phase analysis
- **Pattern learning** from example repetitions
- **Dynamic Time Warping** based sequence matching
- **Comprehensive tests** covering the major features
- **Platform agnostic** core ready for future iOS integration

## Architecture Overview

```
PoseSample -> RepetitionDetector -> SessionManager
              ^                    |
              |                    v
 PatternLearner <-------- SequenceDetector
```

- `PoseSample` represents a single time‑stamped pose metric.
- `RepetitionDetector` performs real time threshold detection.
- `PatternLearner` generates an `ExercisePattern` from positive examples.
- `SequenceDetector` validates full motion sequences using `ExerciseTemporalPattern`.
- `SessionManager` collects repetitions and analytics data.

## Key Features

- Simple threshold based repetition detection
- Learning of average movement patterns for validation
- Dynamic Time Warping for aligning observed sequences with templates
- Temporal phase extraction to classify parts of a repetition
- Session analytics for rest duration tracking

## Quick Start

```swift
import WorkoutCounter

// Detect repetitions from mock pose data
let samples = generateMockPoseData(repetitions: 3)
let detector = RepetitionDetector()
for sample in samples {
    if let rep = detector.process(sample: sample) {
        print("rep from", rep.start, "to", rep.end)
    }
}

// Learn a simple pattern
let learner = PatternLearner()
learner.startLearningSession()
learner.recordPositiveExample(poses: samples)
let pattern = learner.generatePattern()

// Score a new repetition using the learned pattern
let testRep = generateMockPoseData(repetitions: 1)
var velocities: [Float] = []
for i in 1..<testRep.count {
    let dt = testRep[i].time - testRep[i - 1].time
    if dt > 0 {
        velocities.append(Float((testRep[i].metric - testRep[i - 1].metric) / dt))
    }
}
let features = MovementFeatures(
    jointVelocities: ["metric": velocities.reduce(0, +) / Float(max(velocities.count, 1))],
    jointAngles: ["metric": 0],
    movementIntensity: Float(testRep.map { $0.metric }.max()! - testRep.map { $0.metric }.min()!),
    symmetry: 1
)
let score = matchAgainstPattern(features, pattern: pattern)
print("match score", score)
```

### Temporal Sequence Detection

```swift
let temporalLearner = TemporalPatternLearner()
temporalLearner.recordExampleSequence(samples)
let template = temporalLearner.generateTemporalPattern()

let sequenceDetector = SequenceDetector(pattern: template)
var result: SequenceDetector.SequenceDetectionResult = .inProgress(phase: .rest)
let featureFrames = samples.map {
    MovementFeatures(jointVelocities: ["metric": Float($0.metric)], jointAngles: [:], movementIntensity: Float($0.metric), symmetry: 1)
}
for f in featureFrames {
    result = sequenceDetector.processFrame(f)
}
// send a rest frame to finish the sequence
let rest = MovementFeatures(jointVelocities: ["metric": 0], jointAngles: [:], movementIntensity: 0, symmetry: 1)
result = sequenceDetector.processFrame(rest)
if case .completed(let confidence) = result {
    print("sequence detected", confidence)
}
```

## API Documentation

### RepetitionDetector
- `process(sample:)` → returns start and end times for a detected repetition.
- Configurable thresholds through `lowThreshold` and `highThreshold`.

### PatternLearner
- `startLearningSession()` – resets stored examples.
- `recordPositiveExample(poses:)` / `recordNegativeExample(poses:)` – store sample sequences.
- `generatePattern()` – returns an `ExercisePattern` representing the average features of the positives.

### SequenceDetector
- Processes `MovementFeatures` frames and determines when a full sequence has completed.
- Uses an `ExerciseTemporalPattern` created by `TemporalPatternLearner` for timing validation.

### SessionManager & SessionAnalytics
- Manages workout sessions and stores `RepetitionLog` values.
- `sessionAnalytics` tracks rest durations based on motion intensity.

## Testing

Run the full test suite with:

```bash
swift test
```

The tests in `Tests/WorkoutCounterTests/RepetitionTests.swift` demonstrate detection, analytics, pattern learning and sequence matching using the mock data generators.

## Platform Strategy

The package avoids dependencies on platform frameworks so it can compile on Linux and macOS. The public APIs use simple data types making it straightforward to integrate with an iOS app that supplies pose information from Vision.

## Performance Characteristics

The algorithms are lightweight and operate on small arrays of metrics, targeting realtime analysis (~33ms per frame) when connected to camera input. Accuracy depends on the quality of pose data and the learned patterns.

## Contributing

Please read [AGENTS.md](AGENTS.md) for coding style, testing requirements and project guidelines before opening a pull request.
