// swift-tools-version:5.9
import PackageDescription

var products: [Product] = [
    .library(name: "EngineBridge", targets: ["EngineBridge"])
]

var targets: [Target] = [
    .target(
        name: "EngineBridge",
        dependencies: ["engine"],
        path: "Bridging"
    ),
    .target(
        name: "engine",
        path: "CEngine",
        publicHeadersPath: "."
    ),
    .testTarget(
        name: "EngineBridgeTests",
        dependencies: ["EngineBridge"],
        path: "Tests/EngineBridgeTests"
    )
]

#if canImport(SwiftUI)
products.append(.executable(name: "Languiny", targets: ["Languiny"]))
targets.append(
    .executableTarget(
        name: "Languiny",
        dependencies: ["engine", "EngineBridge"],
        path: ".",
        exclude: ["Resources"],
        sources: ["App", "Core", "UI"],
        resources: [ .process("Resources") ],
        linkerSettings: [
            .unsafeFlags(["-Xlinker", "-force_load", "-Xlinker", "/Users/olegpashkovsky/Projects/languiny/engine/build/libengine.a"])
        ]
    )
)
#endif

let package = Package(
    name: "LanguinyApp",
    platforms: [ .macOS(.v13) ],
    products: products,
    targets: targets
)

