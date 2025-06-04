# Co-Sport

This repository hosts simplified snippets demonstrating core ideas for the **Co-Sport** workout detection project.

## In-memory Models

`SessionManager` maintains a `WorkoutSession` and logs `RepetitionLog` values using pure Swift structs. This replaces the earlier Core Data based persistence layer and keeps everything in memory for easy cross-platform use.

```swift
let manager = SessionManager()
manager.startSession(exerciseType: "push-ups")
manager.logRepetition(startOffset: 0, endOffset: 1.2, confidence: 0.94)
manager.endSession()
```

## Repetition Detection

`RepetitionDetector` provides a tiny algorithm that detects repetitions from pose metrics. `MockPoseData` generates sample motion values so the detector can be exercised without a real camera or ML model.

```swift
let samples = generateMockPoseData(repetitions: 3)
let detector = RepetitionDetector()
for sample in samples {
    if let rep = detector.process(sample: sample) {
        print("rep from", rep.start, "to", rep.end)
    }
}
```

## Session Analytics

`SessionAnalytics` tracks the time between repetitions by monitoring movement intensity updates during a session. When a repetition is logged, the rest duration since the previous repetition is appended to `restDurations`.

```swift
let manager = SessionManager()
manager.startSession(exerciseType: "squats")
manager.updateIntensity(0.05, at: 3.0) // low intensity indicates rest
manager.logRepetition(startOffset: 5.0, endOffset: 6.0, confidence: 0.96)
print(manager.sessionAnalytics.restDurations) // [2.0]
```

These components demonstrate the core repetition counting and analytics logic without any platform specific dependencies.
