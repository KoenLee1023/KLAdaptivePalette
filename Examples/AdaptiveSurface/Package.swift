// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AdaptiveSurface",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "AdaptiveSurfaceApp",
            dependencies: [.product(name: "KLAdaptivePalette", package: "KLAdaptivePalette")]
        ),
    ]
)
