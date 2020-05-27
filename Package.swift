// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Package",
    products: [
        .library(name: "LibCore", targets: ["Core"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.0.0")
    ],
    targets: [
        .target(name: "Core", dependencies: ["BigInt"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
