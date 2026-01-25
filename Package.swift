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
      targets: ["Parsley"]),
  ],
  dependencies: [
    .package(url: "https://github.com/stackotter/swift-cmark-gfm", from: "1.0.2")
  ],
  targets: [
    .target(
      name: "Parsley",
      dependencies: [
        .product(name: "CMarkGFM", package: "swift-cmark-gfm")
      ]),
    .testTarget(
      name: "ParsleyTests",
      dependencies: ["Parsley"])
  ]
)
