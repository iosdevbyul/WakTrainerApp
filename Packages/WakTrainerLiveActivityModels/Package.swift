// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WakTrainerLiveActivityModels",
    platforms: [.iOS(.v17)],
    products: [.library(name: "WakTrainerLiveActivityModels", targets: ["WakTrainerLiveActivityModels"])],
    targets: [.target(name: "WakTrainerLiveActivityModels")]
)
