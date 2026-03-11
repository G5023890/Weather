// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Weather",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WeatherCore",
            targets: ["WeatherCore"]
        )
    ],
    targets: [
        .target(
            name: "WeatherCore",
            path: "Sources/WeatherCore"
        ),
        .testTarget(
            name: "WeatherCoreTests",
            dependencies: ["WeatherCore"],
            path: "Tests/WeatherCoreTests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
