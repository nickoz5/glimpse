// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Glimpse",
    platforms: [
        .macOS("26.0")
    ],
    targets: [
        .executableTarget(
            name: "Glimpse",
            path: "Sources/Glimpse",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "GlimpseTests",
            dependencies: ["Glimpse"],
            path: "Tests/GlimpseTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
