import UIKit

@MainActor
final class WakTrainerAppDelegate: NSObject, UIApplicationDelegate {
    let environment = AppEnvironment()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            await environment.handleApplicationLaunch()
        }

        return true
    }
}
