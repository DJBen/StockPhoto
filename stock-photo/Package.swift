// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "stock-photo",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "AppCore", targets: ["AppCore"]),
        .library(name: "AppUI", targets: ["AppUI"]),
        .library(name: "ImageCaptureCore", targets: ["ImageCaptureCore"]),
        .library(name: "ImageCaptureUI", targets: ["ImageCaptureUI"]),
        .library(name: "CoreMLHelpers", targets: ["CoreMLHelpers"]),
        .library(name: "ImageSegmentationClient", targets: ["ImageSegmentationClient"]),
        .library(name: "ImageSegmentationClientImpl", targets: ["ImageSegmentationClientImpl"]),
        .library(name: "DeviceExtension", targets: ["DeviceExtension"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: Version(0, 47, 2)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: Version(1, 10, 0)
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AppCore",
            dependencies: [
                "ImageSegmentationClient",
                "ImageCaptureCore",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: [
                "AppCore"
            ]
        ),
        .target(
            name: "AppUI",
            dependencies: [
                "AppCore",
                "ImageCaptureCore",
                "ImageCaptureUI"
            ]
        ),
        .target(
            name: "ImageCaptureCore",
            dependencies: [
                "ImageSegmentationClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ImageCaptureUI",
            dependencies: [
                "DeviceExtension",
                "ImageCaptureCore"
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "CoreMLHelpers",
            dependencies: [
            ]
        ),
        .target(
            name: "ImageSegmentationClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ImageSegmentationClientImpl",
            dependencies: [
                "ImageSegmentationClient",
                "CoreMLHelpers",
            ]
        ),
        .testTarget(
            name: "ImageSegmentationClientImplTests",
            dependencies: [
                "ImageSegmentationClientImpl",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            sources: ["Sources"],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "DeviceExtension",
            dependencies: []
        ),
    ]
)

// Opt-out image capture UI from concurrency checks
for target in package.targets where target.name != "ImageCaptureUI" {
    target.swiftSettings = [
        .unsafeFlags([
            "-Xfrontend", "-enable-actor-data-race-checks",
            "-Xfrontend", "-warn-concurrency",
        ])
    ]
}
