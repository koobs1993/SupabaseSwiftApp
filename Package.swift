// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SupabaseSwiftApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SupabaseSwiftApp",
            targets: ["SupabaseSwiftApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.3"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1")
    ],
    targets: [
        .target(
            name: "SupabaseSwiftApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SupabaseSwiftAppTests",
            dependencies: ["SupabaseSwiftApp"],
            path: "Tests"
        ),
    ]
) 