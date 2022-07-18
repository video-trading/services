// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "common",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "common",
            targets: ["common"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/soto-project/soto", from: "6.0.0"),
        .package(url: "https://github.com/swift-server-community/mqtt-nio", from: "2.6.0"),
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "common",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "MQTTNIO", package: "mqtt-nio"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "JWT", package: "jwt")
            ]
        ),
        .testTarget(
            name: "commonTests",
            dependencies: ["common"]
        ),
    ]
)
