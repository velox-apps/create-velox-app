// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "CreateVeloxApp",
  products: [
    .executable(
      name: "create-velox-app",
      targets: ["CreateVeloxApp"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0")
  ],
  targets: [
    .executableTarget(
      name: "CreateVeloxApp",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      resources: [
        .copy("Resources/Templates")
      ]
    )
  ]
)
