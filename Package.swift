// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SVGKit",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "SVGKit",
      targets: ["SVGKit"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/behlulKusaslan/CocoaLumberjack", branch: "main")
//    .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5")
  ],
  targets: [
    .target(
      name: "SVGKit",
      dependencies: ["CocoaLumberjack"],
      publicHeadersPath: "include"
    ),
    .testTarget(
      name: "SVGKitTests",
      dependencies: ["SVGKit"]
    ),
  ],
  swiftLanguageVersions: [.v5]
)
