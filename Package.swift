// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KhaleejiAPI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "KhaleejiAPI",
            targets: ["KhaleejiAPI"]
        )
    ],
    targets: [
        .target(
            name: "KhaleejiAPI",
            path: "Sources"
        ),
        .testTarget(
            name: "KhaleejiAPITests",
            dependencies: ["KhaleejiAPI"],
            path: "Tests"
        )
    ]
)
