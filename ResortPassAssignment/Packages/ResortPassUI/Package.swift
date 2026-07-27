// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ResortPassUI",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "ResortPassUI", targets: ["ResortPassUI"])
    ],
    targets: [
        .target(name: "ResortPassUI"),
        .testTarget(name: "ResortPassUITests", dependencies: ["ResortPassUI"])
    ]
)
