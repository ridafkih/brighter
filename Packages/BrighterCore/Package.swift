// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrighterCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BrighterCore", targets: ["BrighterCore"])
    ],
    targets: [
        .target(name: "BrighterCore"),
        .testTarget(name: "BrighterCoreTests", dependencies: ["BrighterCore"])
    ]
)
