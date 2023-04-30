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
        .library(name: "CoreMLHelpers", targets: ["CoreMLHelpers"]),
        .library(name: "DeviceExtension", targets: ["DeviceExtension"]),
        .library(name: "Home", targets: ["Home"]),
        .library(name: "HomeImpl", targets: ["HomeImpl"]),
        .library(name: "ImageCapture", targets: ["ImageCapture"]),
        .library(name: "ImageCaptureImpl", targets: ["ImageCaptureImpl"]),
        .library(name: "ImageSegmentationClient", targets: ["ImageSegmentationClient"]),
        .library(name: "ImageSegmentationClientImpl", targets: ["ImageSegmentationClientImpl"]),
        .library(name: "ImageViewer", targets: ["ImageViewer"]),
        .library(name: "NetworkClient", targets: ["NetworkClient"]),
        .library(name: "NetworkClientImpl", targets: ["NetworkClientImpl"]),
        .library(name: "Navigation", targets: ["Navigation"]),
        .library(name: "Segmentation", targets: ["Segmentation"]),
        .library(name: "SegmentationImpl", targets: ["SegmentationImpl"]),
        .library(name: "StockPhotoFoundation", targets: ["StockPhotoFoundation"]),
        .library(name: "StockPhotoUI", targets: ["StockPhotoUI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS.git",
            from: Version(7, 0, 0)
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            from: Version(4, 2, 2)
        ),
        .package(
            url: "https://github.com/kean/Nuke.git",
            from: Version(12, 1, 0)
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
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "App",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "Login",
                "Home",
                "HomeImpl",
                "ImageSegmentationClient",
                "ImageCapture",
                "ImageCaptureImpl",
                "Navigation",
                "Segmentation",
                "SegmentationImpl",
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App",
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
            name: "Home",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "StockPhotoFoundation",
            ]
        ),
        .target(
            name: "HomeImpl",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "Home",
                "Navigation",
                "Segmentation",
            ]
        ),
        .target(
            name: "ImageCapture",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "ImageCaptureImpl",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DeviceExtension",
                "ImageCapture",
                "ImageSegmentationClient",
                "ImageViewer",
                "Navigation",
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
            name: "ImageViewer",
            dependencies: [
            ]
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
            name: "NetworkClient",
            dependencies: [
                "Home",
                "Segmentation",
            ]
        ),
        .target(
            name: "NetworkClientImpl",
            dependencies: [
                "Home",
                "NetworkClient",
                .product(name: "Nuke", package: "Nuke"),
                "StockPhotoFoundation",
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
            name: "Navigation",
            dependencies: [
                "ImageCapture",
                "Home",
            ]
        ),
        .target(
            name: "Segmentation",
            dependencies: [
                "StockPhotoFoundation",
            ]
        ),
        .target(
            name: "SegmentationImpl",
            dependencies: [
                "ImageViewer",
                "NetworkClient",
                "StockPhotoFoundation",
            ]
        ),
        .target(
            name: "StockPhotoFoundation",
            dependencies: [
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
    "ImageCaptureImpl",
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
