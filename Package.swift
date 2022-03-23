// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "Parsley",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "Parsley",
      targets: ["Parsley"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "cmark",
      dependencies: [],
      path: "Sources/cmark",
      exclude: [
          "case_fold_switch.inc",
          "entities.inc",
          "COPYING"
      ],
      publicHeadersPath: "."),
    .target(
      name: "Parsley",
      dependencies: [
        "cmark"
      ]),
    .testTarget(
      name: "ParsleyTests",
      dependencies: ["Parsley"])
  ]
)
