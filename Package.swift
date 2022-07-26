// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Diffable",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Diffable",
            targets: ["Diffable"]),
        .library(
            name: "DiffableTree",
            targets: ["DiffableTree"]),
        .library(
            name: "DiffableUI",
            targets: ["DiffableUI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/allegro/swift-junit.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Diffable",
            dependencies: []),
        .target(
            name: "DiffableTree",
            dependencies: ["Diffable"]),
        .target(
            name: "DiffableUI",
            dependencies: ["DiffableTree"]),
        .testTarget(
            name: "DiffableTests",
            dependencies: [
                "Diffable",
                .product(name: "SwiftTestReporter", package: "swift-junit")
            ]),
        .testTarget(
            name: "DiffableTreeTests",
            dependencies: [
                "DiffableTree",
                .product(name: "SwiftTestReporter", package: "swift-junit")
            ])
    ]
)
