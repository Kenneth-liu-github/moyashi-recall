// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoyashiRecall",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MoyashiRecall", targets: ["MoyashiRecall"])
    ],
    targets: [
        .target(
            name: "MoyashiRecall",
            exclude: ["App/MoyashiRecallApp.swift"]
        ),
        .testTarget(name: "MoyashiRecallTests", dependencies: ["MoyashiRecall"])
    ]
)
