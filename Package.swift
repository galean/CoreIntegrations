// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreIntegrations",
    platforms: [
            .iOS(.v15)
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CoreIntegrations",
            targets: ["CoreIntegrations"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk", from: "17.3.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Dynamic", from: "6.0.0"),
        .package(url: "https://github.com/amplitude/analytics-connector-ios.git", from: "1.0.0"),
        .package(url: "https://github.com/amplitude/Amplitude-iOS", from: "8.0.0"),
        .package(url: "https://github.com/amplitude/experiment-ios-client", from: "1.13.5"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.35.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "CoreIntegrations",
                dependencies: [
                    "AppsflyerIntegration",
                    "FacebookIntegration",
                    "AnalyticsIntegration",
                    "FirebaseIntegration",
                    "PurchasesIntegration",
                    "AttributionServerIntegration",
                    "SentryIntegration",
                ],
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "AppsflyerIntegration",
                dependencies: [
                    .product(name: "AppsFlyerLib-Dynamic", package: "AppsFlyerFramework-Dynamic")
                ],
                path: "Sources/AppsflyerIntegration",
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "FacebookIntegration",
                dependencies: [
                    .product(name: "FacebookCore", package: "facebook-ios-sdk")
                ],
                path: "Sources/FacebookIntegration",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "AnalyticsIntegration",
                dependencies: [
                    .product(name: "Amplitude", package: "Amplitude-iOS")
                ],
                path: "Sources/AnalyticsIntegration",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "FirebaseIntegration",
                dependencies: [
                    .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                    .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                    .product(name: "Experiment", package: "experiment-ios-client"),
                ],
                path: "Sources/FirebaseIntegration",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "PurchasesIntegration",
                path: "Sources/PurchasesIntegration",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "AttributionServerIntegration",
                path: "Sources/AttributionServerIntegration",
                linkerSettings: [
                    .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
        .target(name: "SentryIntegration",
                dependencies: [
                    .product(name: "Sentry", package: "sentry-cocoa")
                ],
                path: "Sources/SentryIntegration",
                linkerSettings: [
                  .linkedFramework("UIKit", .when(platforms: [.iOS])),
                ]
        ),
    ]
)
