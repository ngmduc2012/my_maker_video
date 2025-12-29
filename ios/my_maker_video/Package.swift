// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "my_maker_video",
  platforms: [
    .iOS("12.0"),
  ],
  products: [
    .library(name: "my_maker_video", targets: ["my_maker_video"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "my_maker_video",
      dependencies: [],
      resources: [
        .process("PrivacyInfo.xcprivacy"),
      ]
    ),
  ]
)
