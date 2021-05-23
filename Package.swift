// swift-tools-version:5.3
import Foundation
import PackageDescription

let package = Package(
    name: "VertexGUI",
    
    platforms: [
        .macOS(.v10_15)
    ],
    
    products: [
        .library(
            name: "VertexGUI",
            targets: ["VertexGUI"]
        ),
        /*.library(name: "ApplicationBackendSDL2", targets: ["ApplicationBackendSDL2"]),
        .library(name: "ApplicationBackendSDL2Vulkan", targets: ["ApplicationBackendSDL2Vulkan"]),*/
        .executable(name: "MinimalDemo", targets: ["MinimalDemo"]),
        .executable(name: "DevApp", targets: ["DevApp"]),
        .executable(
            name: "TaskOrganizerDemo",
            targets: ["TaskOrganizerDemo"]),
    ],

    dependencies: [
        //.package(url: "https://github.com/UnGast/CSDL2.git", .branch("master")),
        //.package(name: "Vulkan", url: "https://github.com/UnGast/SwiftVulkan.git", .branch("master")),
        .package(name: "GL", url: "https://github.com/UnGast/swift-opengl.git", .branch("master")),
        .package(name: "Swim", url: "https://github.com/t-ae/swim.git", from: "3.9.0"),
        .package(url: "https://github.com/UnGast/Cnanovg.git", .branch("master")),
        .package(name: "GfxMath", url: "https://github.com/UnGast/swift-gfx-math.git", .branch("master")),
        .package(url: "https://github.com/cx-org/CombineX.git", .branch("master")),
        .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.6.0"),
        .package(name: "Fireblade", path: "../FirebladeEngine"),
        .package(path: "../SkiaKit")
    ],

    targets: [
        .target(
            name: "Drawing",
            dependencies: ["GfxMath", .product(name: "FirebladeHID", package: "Fireblade"), "Swim"]),
        .target(
            name: "DrawingImplGL3NanoVG",
            dependencies: ["Drawing", "GfxMath", .product(name: "FirebladeHID", package: "Fireblade"), .product(name: "CnanovgGL3", package: "Cnanovg"), "GL"]),/*
        .target(
            name: "DrawingVulkan",
            dependencies: ["Drawing", "Vulkan", .product(name: "CSDL2Vulkan", package: "CSDL2")]),*/
        .target(name: "Application", dependencies: ["WidgetGUI", .product(name: "FirebladeHID", package: "Fireblade"), "Drawing", "DrawingImplGL3NanoVG", "VisualAppBase", "GfxMath"]),
        /*.target(name: "ApplicationBackendSDL2", dependencies: ["Application", "Drawing", "CSDL2", "GfxMath", "CombineX"]),
        .target(
            name: "ApplicationBackendSDL2Vulkan", 
            dependencies: ["ApplicationBackendSDL2", "DrawingVulkan", "Vulkan", .product(name: "CSDL2Vulkan", package: "CSDL2")]),*/
        .target(
            name: "VisualAppBase", dependencies: ["GfxMath", "Swim", "Drawing"]
        ),

        .target(
            name: "Events"
        ),

        .target(
            name: "WidgetGUI",
            dependencies: ["VisualAppBase", "Events", .product(name: "CXShim", package: "CombineX"), "GfxMath", "ColorizeSwift", "Drawing", "SkiaKit"],
            resources: [.process("Resources")]
        ),

        /*.target(
            name: "VisualAppBaseImplSDL2OpenGL3NanoVG",
            dependencies: ["WidgetGUI", "CSDL2", "GL", "Drawing", "Events", "Swim", .product(name: "CnanovgGL3", package: "Cnanovg"), "GfxMath"],
            resources: [.process("Resources")]),*/
       
        .target(
            name: "TaskOrganizerDemo",
            dependencies: ["VertexGUI", "Swim", .product(name: "CXShim", package: "CombineX")],
            resources: [.copy("Resources")]),

        .target(
            name: "MinimalDemo",
            dependencies: ["VertexGUI"]
        ),

        .target(
            name: "DevApp",
            dependencies: ["VertexGUI", "Swim"]
        ),

        .target(
            name: "VertexGUI",
            dependencies: ["VisualAppBase", "WidgetGUI", "Events", "GfxMath", "Application", "Drawing", "DrawingImplGL3NanoVG"],
            resources: [.process("Resources")]
        ),

        //.testTarget(name: "WidgetGUITests", dependencies: ["VertexGUI"])
    ]
)
