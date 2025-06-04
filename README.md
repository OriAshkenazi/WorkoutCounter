# Co-Sport

This repository hosts snippets demonstrating core ideas for the **Co-Sport** workout detection project.

## Perfect Repetition Star Icon

The sample code includes `PerfectRepNotifier` which displays a star icon whenever a repetition is executed with a confidence of 0.95 or above. The star briefly appears at the top of the parent view and fades away automatically.

```swift
let notifier = PerfectRepNotifier(in: workoutView)
notifier.showIfPerfect(confidence: repConfidence)
```

This basic feature provides instant positive feedback to the user during a workout.

## Persistence Layer

`PersistenceController` manages a Core Data stack backed by SQLite. `SessionManager` wraps session state and records `WorkoutSession` and `RepetitionLog` objects. Each session is saved with its start and end time while every repetition is stored with a timestamp and confidence value.

```swift
let manager = SessionManager()
manager.startSession(exerciseType: "push-ups")
manager.logRepetition(startOffset: 0, endOffset: 1.2, confidence: 0.94)
manager.endSession()
```

These models demonstrate a simple approach to persisting workout history on device.

## Session Analytics

`SessionManager` now exposes simple rest tracking via `SessionAnalytics`. Movement
intensity updates are monitored while a session is running. When a new
repetition is logged, the time since the previous repetition is calculated and
appended to `restDurations`.

```swift
let manager = SessionManager()
manager.startSession(exerciseType: "squats")
manager.updateIntensity(0.05, at: 3.0) // low intensity indicates rest
manager.logRepetition(startOffset: 5.0, endOffset: 6.0, confidence: 0.96)
print(manager.sessionAnalytics.restDurations) // [2.0]
```

This allows basic analysis of rest timing between repetitions for a workout
session.
