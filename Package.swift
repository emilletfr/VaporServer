import PackageDescription

let package = Package(
    name: "VaporApp",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 3),
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3)
      ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources"
    ]
)
