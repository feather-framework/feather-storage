// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "feather-storage",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "FeatherStorage", targets: ["FeatherStorage"]),
        .library(name: "XCTFeatherStorage", targets: ["XCTFeatherStorage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0"),
        .package(url: "https://github.com/feather-framework/feather-component", .upToNextMinor(from: "0.5.0")),
    ],
    targets: [
        .target(
            name: "FeatherStorage",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "FeatherComponent", package: "feather-component")
            ]
        ),
        .target(
            name: "XCTFeatherStorage",
            dependencies: [
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .target(name: "FeatherStorage"),
            ]
        ),
        .testTarget(
            name: "FeatherStorageTests",
            dependencies: [
                .target(name: "FeatherStorage"),
            ]
        ),
        .testTarget(
            name: "XCTFeatherStorageTests",
            dependencies: [
                .target(name: "XCTFeatherStorage"),
            ]
        ),
    ]
)
