// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WorkoutCounter",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WorkoutCounter",
            targets: ["WorkoutCounter"]),
        // Sample target for iOS camera integration
        .library(
            name: "WorkoutCounterCameraSample",
            targets: ["WorkoutCounterCameraSample"]),
        // Demo executable showcasing Vision integration on iOS
        .executable(
            name: "VisionDemoApp",
            targets: ["VisionDemoApp"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WorkoutCounter"),
        .target(
            name: "WorkoutCounterCameraSample",
            dependencies: ["WorkoutCounter"]),
        .executableTarget(
            name: "VisionDemoApp",
            dependencies: ["WorkoutCounter"],
            path: "Sources/VisionDemoApp"),
        .testTarget(
            name: "WorkoutCounterTests",
            dependencies: ["WorkoutCounter"]
        ),
    ]
)
