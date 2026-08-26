// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Pilp",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Pilp", targets: ["Pilp"])
    ],
    targets: [
        .target(name: "PilpCore"),
        .executableTarget(
            name: "Pilp",
            dependencies: ["PilpCore"]
        ),
        .testTarget(
            name: "PilpCoreTests",
            dependencies: ["PilpCore"]
        )
    ]
)
