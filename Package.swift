// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MouseJiggler",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "MouseJiggler", path: "Sources/MouseJiggler")
    ]
)
