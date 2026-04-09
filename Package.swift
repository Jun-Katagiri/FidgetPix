// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FidgetPix",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FidgetPix",
            path: "Sources/FidgetPix"
        )
    ]
)
