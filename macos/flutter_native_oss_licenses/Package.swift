// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_native_oss_licenses",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "flutter-native-oss-licenses",
            targets: ["flutter_native_oss_licenses"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_native_oss_licenses",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
