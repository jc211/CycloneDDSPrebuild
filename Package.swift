// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CycloneDDS",
    products: [
        .library(name: "CycloneDDS", targets: ["CycloneDDS"])
    ],
    targets: [
        .binaryTarget(name: "CycloneDDS",
                      url: "https://github.com/jc211/CycloneDDSPrebuild/releases/download/0.10.2/cyclonedds.xcframework.zip",
                      checksum: "35193ae9ba6bcceb3f2dcbcf2afe292d02bbb6bcc5e547167542a15c0a55be36")
    ]
)
