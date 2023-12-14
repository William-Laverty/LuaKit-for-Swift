// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "LuaKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LuaKit",
            targets: ["LuaKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-04-25-b"),
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

