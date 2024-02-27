// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSolar",
    platforms: [
        .iOS(.v16),
        .watchOS(.v8),
        .macOS(.v10_13),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftSolar",
            targets: ["SwiftSolar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SwiftSolar",
            dependencies: [.product(name: "Numerics", package: "swift-numerics")]),
        .testTarget(
            name: "SwiftSolarTests",
            dependencies: ["SwiftSolar"]),
    ]
)
