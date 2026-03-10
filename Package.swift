// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "LuaKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LuaKit",
            targets: ["LuaKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .target(name: "LuaKit", dependencies: ["lua", "LuaKitMacros"]),
        .executableTarget(name: "LuaKitDemo", dependencies: ["LuaKit"]),
        .systemLibrary(name: "lua", pkgConfig: "lua", providers: [.brew(["lua"])]),
        .testTarget(name: "LuaDemoTests", dependencies: ["LuaKitDemo"]),
        .testTarget(
            name: "LuaKitTests",
            dependencies: [
                "LuaKit",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]),
        .macro(name: "LuaKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ]
)
