// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "DungeonBattleRoyale",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        
        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        .package(url: "https://github.com/BrettRToomey/Jobs.git", from: "1.1.1"),
        // 👤 Authentication and Authorization layer for Fluent.
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Authentication", "FluentSQLite", "Vapor", "Jobs"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)



