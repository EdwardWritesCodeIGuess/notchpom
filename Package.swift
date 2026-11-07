// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchPom",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "NotchPom", targets: ["NotchPom"])],
    targets: [
        .target(name: "TimerCore"),
        .executableTarget(name: "NotchPom", dependencies: ["TimerCore"]),
        .executableTarget(name: "TimerCoreChecks", dependencies: ["TimerCore"], path: "Tests/TimerCoreTests")
    ]
)
