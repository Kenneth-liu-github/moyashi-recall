// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoyashiRecall",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MoyashiRecall", targets: ["MoyashiRecall"])
    ],
    targets: [
        .target(name: "MoyashiRecall"),
        .testTarget(name: "MoyashiRecallTests", dependencies: ["MoyashiRecall"])
    ]
)
