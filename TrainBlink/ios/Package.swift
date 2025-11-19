// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrainBlink",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TrainBlink",
            targets: ["TrainBlink"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "10.20.0"
        )
    ],
    targets: [
        .target(
            name: "TrainBlink",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebasePerformance", package: "firebase-ios-sdk")
            ],
            path: "TrainBlink"
        )
    ]
)
