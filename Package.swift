// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Auralink",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "Auralink", targets: ["Auralink"])
    ],
    targets: [
        .target(name: "Auralink", path: "Sources/Auralink"),
        .testTarget(name: "AuralinkTests", dependencies: ["Auralink"], path: "Tests")
    ]
)
