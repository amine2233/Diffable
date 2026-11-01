// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Diffable",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other
        // packages.
        .library(
            name: "Diffable",
            targets: ["Diffable"]
        ),
        .library(
            name: "DiffableUI",
            targets: ["DiffableUI"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package
        // depends on.
        .target(
            name: "Diffable",
            dependencies: []
        ),
        .target(
            name: "DiffableUI",
            dependencies: ["Diffable"]
        ),
        .testTarget(
            name: "DiffableTests",
            dependencies: ["Diffable"]
        ),
        .testTarget(
            name: "DiffableUITests",
            dependencies: ["Diffable", "DiffableUI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
