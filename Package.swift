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
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.4"
        )
    ],
    targets: [
        .target(name: "PilpCore"),
        .executableTarget(
            name: "Pilp",
            dependencies: [
                "PilpCore",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        ),
        .testTarget(
            name: "PilpCoreTests",
            dependencies: ["PilpCore"]
        )
    ]
)
