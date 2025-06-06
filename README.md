# WorkoutCounter

WorkoutCounter is a Swift package for counting workout repetitions using pose metrics. It provides lightweight algorithms for detecting motion phases and learning exercise patterns. The core library remains platform agnostic so it can be integrated on iOS or other Swift environments.

## Project Overview

The library processes temporal pose data to detect when a full repetition has occurred. It includes utilities for learning patterns from example repetitions and for aligning new sequences with previously learned templates. The design is modular so that pose capture can be provided by any vision system.

## Current Implementation Status

- **Temporal sequence detection** with phase analysis
- **Pattern learning** from example repetitions
- **Dynamic Time Warping** based sequence matching
- **Comprehensive tests** covering the major features
- **Platform agnostic** core ready for future iOS integration
- **Real-time streaming engine** with adaptive performance and memory management
- **iOS sample library and Vision demo app** for camera-based testing

## Architecture Overview

```
PoseFrame -> StreamingWorkoutEngine -> SessionManager
                 |       ^
                 v       |
  StreamingFeatureExtractor -> ProductionRepetitionDetector
                 |       |
   PerformanceController <- MemoryManager
```

- `PoseFrame` represents a time‑stamped set of joint locations.
- `StreamingWorkoutEngine` coordinates real time processing.
- `ProductionRepetitionDetector` validates movement sequences.
- `StreamingFeatureExtractor` converts pose data into movement features.
- `PerformanceController` and `MemoryManager` tune quality and memory usage.
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
let samples = generateMockPoseFrames(repetitions: 3)
let detector = RepetitionDetector()
for frame in samples {
    if let rep = detector.process(frame: frame) {
        print("rep from", rep.start, "to", rep.end)
    }
}

// Learn a simple pattern
let learner = PatternLearner()
learner.startLearningSession()
learner.recordPositiveExample(poses: samples.map { $0.toPoseSample() })
let pattern = learner.generatePattern()

// Score a new repetition using the learned pattern
let testRep = generateMockPoseFrames(repetitions: 1).map { $0.toPoseSample() }
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

### Real-Time Streaming

```swift
import WorkoutCounter

let engine = StreamingWorkoutEngine()
let frames = generateMockPoseFrames(repetitions: 2)
for frame in frames {
    let update = engine.processFrame(frame)
    if case .repetitionLogged(let log) = update {
        print("rep from", log.startTime, "to", log.endTime)
    }
}
```

### Temporal Sequence Detection

```swift
let temporalLearner = TemporalPatternLearner()
temporalLearner.recordExampleSequence(samples.map { $0.toPoseSample() })
let template = temporalLearner.generateTemporalPattern()

let sequenceDetector = SequenceDetector(pattern: template)
var result: SequenceDetector.SequenceDetectionResult = .inProgress(phase: .rest)
let featureFrames = samples.map {
    MovementFeatures(jointVelocities: ["metric": Float($0.toPoseSample().metric)], jointAngles: [:], movementIntensity: Float($0.toPoseSample().metric), symmetry: 1)
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

### StreamingWorkoutEngine
- `processFrame(_:)` → processes a `PoseFrame` and returns workout updates.
- `shouldProcessFrame(_:, quality:)` → skips frames based on performance level.
- `recordVisionProcessingTime(_:)` → logs Vision duration for metrics.

### PatternLearner
- `startLearningSession()` – resets stored examples.
- `recordPositiveExample(poses:)` / `recordNegativeExample(poses:)` – store sample sequences.
- `generatePattern()` – returns an `ExercisePattern` representing the average features of the positives.

### SequenceDetector
- Processes `MovementFeatures` frames and determines when a full sequence has completed.
- Uses an `ExerciseTemporalPattern` created by `TemporalPatternLearner` for timing validation.

### ProductionRepetitionDetector
- State machine built on `StreamingFeatureExtractor` that filters noise and validates timing.
- Supports multiple performance levels for balancing accuracy and speed.

### PerformanceController & MemoryManager
- `PerformanceController` tracks frame rates and adjusts processing quality.
- `MemoryManager` trims buffers to maintain a steady memory footprint.

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

### Vision Integration

When running on Apple platforms you can convert `VNHumanBodyPoseObservation` values into the pose types used by WorkoutCounter:

```swift
#if canImport(Vision)
import Vision
import WorkoutCounter

let observation: VNHumanBodyPoseObservation = ... // provided by Vision
let pose = PoseObservation(visionObservation: observation)
let sample = poseSample(from: pose, at: 0)
let features = movementFeatures(from: pose)
#endif
```

### iOS Samples

Two sample targets demonstrate camera-based integration:

- `WorkoutCounterCameraSample` exposes `CameraWorkoutController` for easy embedding in an app.
- `VisionDemoApp` is a minimal executable that streams Vision poses into the engine.

You can build the demo with:

```bash
swift build --product VisionDemoApp
```

## Performance Characteristics

The algorithms are lightweight and operate on small arrays of metrics, targeting realtime analysis (~33ms per frame) when connected to camera input. Accuracy depends on the quality of pose data and the learned patterns.

## Streaming Support

The streaming engine processes frames individually using circular buffers. It
automatically scales analysis quality based on measured frame times and keeps a
constant memory footprint, making it ready for live camera input.
The production detector adds hysteresis-based movement detection, temporal
smoothing and confidence accumulation to avoid false positives. Repetition
timing is validated to ensure realistic motion before logging.
`PerformanceController` monitors frame duration to adjust quality levels, while
`MemoryManager` prunes old data to avoid leaks during long sessions.

## Contributing

Please read [AGENTS.md](AGENTS.md) for coding style, testing requirements and project guidelines before opening a pull request.
