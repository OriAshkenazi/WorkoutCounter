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
│   ├── RepetitionDetector.swift          # Core detection algorithms
│   ├── PatternLearner.swift              # Machine learning components
│   ├── SequenceMatching.swift            # Temporal analysis algorithms
│   ├── SessionAnalytics.swift            # Performance metrics
│   └── MockPoseData.swift                # Test data generators
└── Tests/WorkoutCounterTests/             # Test suite
    └── RepetitionTests.swift              # All test cases
```

## Development Guidelines

### Where to Work
- **Core algorithms**: Add new detection logic to `Sources/WorkoutCounter/RepetitionDetector.swift`
- **Data models**: Extend types in `Sources/WorkoutCounter/Models.swift`
- **ML components**: Enhance pattern learning in `Sources/WorkoutCounter/PatternLearner.swift`
- **Analytics**: Add metrics to `Sources/WorkoutCounter/SessionAnalytics.swift`
- **Testing**: All tests go in `Tests/WorkoutCounterTests/RepetitionTests.swift`

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
- **Coverage**: Test both happy path and edge cases

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
- **Performance optimization**: Profile timing-critical sections with instruments
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
