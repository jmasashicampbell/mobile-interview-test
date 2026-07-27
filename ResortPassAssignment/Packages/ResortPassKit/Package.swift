// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ResortPassKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "ResortPassKit", targets: ["ResortPassKit"])
    ],
    targets: [
        .target(name: "ResortPassKit"),
        .testTarget(name: "ResortPassKitTests", dependencies: ["ResortPassKit"])
    ]
)
