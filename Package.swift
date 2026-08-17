// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VaultMaster",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VaultMaster",
            targets: ["VaultMaster"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VaultMaster",
            dependencies: [],
            path: "Sources/VaultMaster"
        ),
        .testTarget(
            name: "VaultMasterTests",
            dependencies: ["VaultMaster"],
            path: "Tests/VaultMasterTests"
        )
    ]
)
