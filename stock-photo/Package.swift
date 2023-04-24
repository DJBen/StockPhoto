// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "stock-photo",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "App", targets: ["App"]),
        .library(name: "ImageCapture", targets: ["ImageCapture"]),
        .library(name: "CoreMLHelpers", targets: ["CoreMLHelpers"]),
        .library(name: "DeviceExtension", targets: ["DeviceExtension"]),
        .library(name: "ImageSegmentationClient", targets: ["ImageSegmentationClient"]),
        .library(name: "ImageSegmentationClientImpl", targets: ["ImageSegmentationClientImpl"]),
        .library(name: "NetworkClient", targets: ["NetworkClient"]),
        .library(name: "NetworkClientImpl", targets: ["NetworkClientImpl"]),
        .library(name: "StockPhotoUI", targets: ["StockPhotoUI"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            from: Version(4, 2, 2)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: Version(0, 52, 0)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies.git",
            from: Version(0, 4, 1)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: Version(1, 11, 0)
        ),
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS.git",
            from: Version(7, 0, 0)
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "App",
            dependencies: [
                "Login",
                "ImageSegmentationClient",
                "ImageCapture",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App"
            ]
        ),
        .target(
            name: "CoreMLHelpers",
            dependencies: [
            ]
        ),
        .target(
            name: "DeviceExtension",
            dependencies: []
        ),
        .target(
            name: "Login",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "KeychainAccess",
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
                "NetworkClient",
            ]
        ),
        .target(
            name: "ImageCapture",
            dependencies: [
                "DeviceExtension",
                "ImageSegmentationClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "ImageSegmentationClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .target(
            name: "ImageSegmentationClientImpl",
            dependencies: [
                "ImageSegmentationClient",
                "CoreMLHelpers",
            ]
        ),
        .target(
            name: "NetworkClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "NetworkClientImpl",
            dependencies: [
                "NetworkClient"
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
            name: "StockPhotoUI",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        )
    ]
)

let packagesIgnoringConcurrencyChecks = [
    "ImageCapture",
    "StockPhotoUI"
]

// Opt-out image capture UI from concurrency checks
for target in package.targets where !packagesIgnoringConcurrencyChecks.contains(target.name) {
    target.swiftSettings = [
        .unsafeFlags([
            "-Xfrontend", "-enable-actor-data-race-checks",
            "-Xfrontend", "-warn-concurrency",
        ])
    ]
}
