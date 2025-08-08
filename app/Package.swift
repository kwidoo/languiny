// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LanguinyApp",
    platforms: [ .macOS(.v13) ],
    products: [ .executable(name: "Languiny", targets: ["Languiny"]) ],
    targets: [
        .executableTarget(
            name: "Languiny",
            dependencies: ["engine"],
            path: ".",
            exclude: ["Resources", "Tests", "CEngine"],
            sources: ["App", "Core", "UI", "Bridging"],
            resources: [ .process("Resources") ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-force_load", "-Xlinker", "/Users/olegpashkovsky/Projects/languiny/engine/build/libengine.a"]) 
            ]
        ),
        // Clang module exposing C headers for the engine
        .target(
            name: "engine",
            path: "CEngine",
            exclude: ["engine.c"],
            publicHeadersPath: "."
        )
    ]
)
