// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MenuBarGate",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MenuBarGate", targets: ["MenuBarGate"])
    ],
    targets: [
        .executableTarget(name: "MenuBarGate"),
        .testTarget(name: "MenuBarGateTests", dependencies: ["MenuBarGate"])
    ]
)
