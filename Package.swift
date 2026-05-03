// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JourniqSDK",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "JourniqSDK",
            targets: ["JourniqSDK"]
        ),
    ],
    targets: [
        .target(
            name: "JourniqSDK",
            path: "Sources/JourniqSDK"
        ),
        .testTarget(
            name: "JourniqSDKTests",
            dependencies: ["JourniqSDK"],
            path: "Tests/JourniqSDKTests"
        ),
    ]
)
