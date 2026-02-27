// swift-tools-version:5.4

import PackageDescription

let package = Package(
  name: "Parsley",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
  ],
  products: [
    .library(
      name: "Parsley",
      targets: ["Parsley"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-cmark.git", from: "0.7.1"),
  ],
  targets: [
    .target(
      name: "Parsley",
      dependencies: [
        .product(name: "cmark-gfm", package: "swift-cmark"),
        .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
      ]
    ),
    .testTarget(
      name: "ParsleyTests",
      dependencies: ["Parsley"]
    ),
  ]
)
