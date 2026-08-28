// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KLAdaptivePalette",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "KLAdaptivePalette", targets: ["KLAdaptivePalette"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            from: "1.4.0"
        ),
    ],
    targets: [
        .target(name: "KLAdaptivePalette"),
        .testTarget(
            name: "KLAdaptivePaletteTests",
            dependencies: ["KLAdaptivePalette"]
        ),
    ]
)
