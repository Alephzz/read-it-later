// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReadItLater",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ReadItLater",
            path: "Sources/ReadItLater",
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedFramework("Carbon"),
            ]
        ),
    ]
)
