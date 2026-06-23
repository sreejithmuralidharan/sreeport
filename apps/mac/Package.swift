// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SreeportMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SreeportMac", targets: ["SreeportMac"])
    ],
    targets: [
        .executableTarget(name: "SreeportMac"),
        .testTarget(name: "SreeportMacTests", dependencies: ["SreeportMac"])
    ]
)
