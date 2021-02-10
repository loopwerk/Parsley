// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "Parsley",
  products: [
    .library(
      name: "Parsley",
      targets: ["Parsley"]),
  ],
  dependencies: [
    .package(name:"cmark", url: "https://github.com/brokenhandsio/cmark-gfm.git", from: "2.0.0"),
  ],
  targets: [
    .target(
      name: "Parsley",
      dependencies: [
        "cmark"
      ]),
    .testTarget(
      name: "ParsleyTests",
      dependencies: ["Parsley"]),
  ]
)
