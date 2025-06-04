# Contributor Guide

## Project Overview
This is a Swift package for workout repetition detection using computer vision and machine learning. The core library is platform-agnostic and focuses on algorithmic logic rather than iOS-specific implementations.

## Repository Structure
```
├── Package.swift                           # Swift package manifest
├── README.md                              # Project documentation
├── AGENTS.md                              # This file
├── Sources/WorkoutCounter/                # Main library code
│   ├── Models.swift                       # Data structures and types
│   ├── PoseFrame.swift                    # Time stamped pose samples
│   ├── PoseObservation.swift              # Vision/pose utilities
│   ├── RepetitionDetector.swift           # Baseline detector algorithms
│   ├── ProductionRepetitionDetector.swift # Streaming detection with validation
│   ├── StreamingWorkoutEngine.swift       # High level engine for real time use
│   ├── StreamingFeatureExtractor.swift    # Sliding window feature extraction
│   ├── PerformanceController.swift        # Adaptive quality logic
│   ├── MemoryManager.swift                # Memory usage monitoring
│   ├── PatternLearner.swift               # Machine learning components
│   ├── SequenceMatching.swift             # Temporal analysis algorithms
│   ├── SessionAnalytics.swift             # Performance metrics
│   ├── SignalProcessing.swift             # Utility filters
│   └── MockPoseData.swift                 # Test data generators
├── Sources/WorkoutCounterCameraSample/    # iOS sample library
│   └── CameraWorkoutController.swift      # Camera/Vision integration example
├── Sources/VisionDemoApp/                 # Demo executable for iOS
│   └── DemoApp.swift                      # Simple Vision processing app
└── Tests/WorkoutCounterTests/             # Test suite
    ├── RepetitionTests.swift              # Functional tests
    └── PerformanceBenchmarks.swift        # Performance benchmarks
```

## Development Guidelines

### Where to Work
- **Core algorithms**: Extend detection logic in `RepetitionDetector.swift` and `ProductionRepetitionDetector.swift`
- **Data models**: Update types in `Models.swift`, `PoseFrame.swift` and `PoseObservation.swift`
- **Streaming pipeline**: Modify real time processing in `StreamingWorkoutEngine.swift` and `StreamingFeatureExtractor.swift`
- **Performance utilities**: Tune `PerformanceController.swift` and `MemoryManager.swift` for profiling
- **Analytics**: Extend workout metrics in `SessionAnalytics.swift`
- **Testing**: Add unit tests in `RepetitionTests.swift` and performance cases in `PerformanceBenchmarks.swift`

### Code Style
- Use Swift naming conventions (camelCase for functions/variables, PascalCase for types)
- Keep functions focused and single-purpose
- Add inline documentation for public APIs
- Prefer value types (structs) over reference types (classes) when possible
- Use meaningful variable names that describe the data they hold

### Testing Requirements
- **Run tests**: `swift test` (must pass before any changes)
- **Add tests**: Every new feature must include corresponding test cases
- **Test naming**: Use descriptive test function names like `testTemporalSequenceDetection`
- **Mock data**: Use `MockPoseData` generators for realistic test scenarios
- **Coverage**: Test both happy path and edge cases, including performance benchmarks

### Platform Considerations
- **Keep iOS-agnostic**: Core algorithms should work without UIKit/Vision/CoreData
- **Mock external dependencies**: Use test doubles for camera/pose detection
- **Separate concerns**: Business logic separate from platform-specific code
- **Future iOS integration**: Design APIs that will easily integrate with Vision framework

### Contribution Workflow
1. **Understand the context**: Read existing code and tests before making changes
2. **Write tests first**: Define expected behavior with tests, then implement
3. **Validate continuously**: Run `swift test` frequently during development
4. **Document changes**: Update README.md if adding new features
5. **Keep commits focused**: One logical change per commit

### Key Algorithms to Understand
- **Repetition Detection**: Multi-stage state machine (monitoring → in-progress → validation)
- **Pattern Learning**: Averages features from example repetitions for template matching
- **Temporal Analysis**: Tracks movement phases and sequence timing
- **Sequence Matching**: Uses Dynamic Time Warping for temporal alignment

### Common Tasks
- **Adding new exercise support**: Extend `ExercisePattern` and update learning algorithms
- **Improving detection accuracy**: Enhance feature extraction in `MovementFeatures`
- **Streaming improvements**: Tune buffer sizes and validation logic in the streaming detectors
- **Performance optimization**: Profile and adapt quality levels with `PerformanceController`
- **Analytics enhancement**: Add new metrics to `SessionAnalytics`

### Validation Checklist
- [ ] `swift test` passes with no failures
- [ ] New code includes appropriate test coverage
- [ ] Public APIs have documentation comments
- [ ] No hardcoded values (use configuration constants)
- [ ] Performance-critical code is optimized
- [ ] Memory usage is reasonable (no obvious leaks)

### Error Handling
- Use Swift's error handling (`throws`, `Result`) for recoverable errors
- Fail fast with assertions for programming errors
- Provide meaningful error messages for user-facing issues
- Log important events for debugging (but avoid excessive logging)

### Performance Considerations
- Target real-time processing (≤33ms per frame when integrated with camera)
- Use lazy evaluation where appropriate
- Minimize memory allocations in hot paths
- Profile before optimizing, measure after changes

### Future iOS Integration Notes
- Current code designed to integrate with Vision framework's `VNHumanBodyPoseObservation`
- `PoseSample` will map to Vision's joint detection results
- `MovementFeatures` extraction will use real joint positions and confidence scores
- Session management will integrate with Core Data for persistence

## Change Documentation
When making significant changes:
- Update README.md with new features or API changes
- Add usage examples for new public APIs
- Document breaking changes clearly
- Include performance impact notes for algorithmic changes
