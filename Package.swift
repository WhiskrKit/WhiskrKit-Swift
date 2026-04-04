// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WhiskrKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "WhiskrKit",
            targets: ["WhiskrKit"]
        ),
    ],
    targets: [
        .target(
            name: "WhiskrKit",
            resources: [
                .process("Assets.xcassets"),
                .process("Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "WhiskrKitTests",
            dependencies: ["WhiskrKit"]
        ),
    ]
)

for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(contentsOf: [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
  ])
  target.swiftSettings = settings
}
