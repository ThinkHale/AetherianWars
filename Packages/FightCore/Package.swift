// swift-tools-version: 5.10
import PackageDescription

// The fight itself: rules, frame data, the roster and the CPU opponent.
// Pure Swift with no UIKit or SpriteKit, so it runs (and is tested) on macOS.
let package = Package(
    name: "FightCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "FightCore", targets: ["FightCore"])],
    targets: [
        .target(name: "FightCore"),
        .testTarget(name: "FightCoreTests", dependencies: ["FightCore"]),
    ]
)
