// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "video_upload_service",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
        .package(url: "https://github.com/soto-project/soto", from: "6.0.0"),
        .package(url: "https://github.com/sirily11/env-checker", from: "1.0.0" ),
        .package(url: "https://github.com/swift-server-community/mqtt-nio", from: "2.6.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(path: "../../../packages/model"),
        .package(path: "../../../packages/common"),
        .package(path: "../../../packages/client"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "MQTTNIO", package: "mqtt-nio"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "model", package: "model"),
                .product(name: "common", package: "common"),
                .product(name: "env", package: "env-checker"),
                .product(name: "client", package: "client"),
                
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
