import AuthenticationKit
import SwiftUI

@main
struct WakTrainerApp: App {
    @UIApplicationDelegateAdaptor(
        WakTrainerAppDelegate.self
    )
    private var appDelegate

    init() {
        guard
            let baseURLString = Bundle.main.object(
                forInfoDictionaryKey: "API_BASE_URL"
            ) as? String,
            let baseURL = URL(string: baseURLString)
        else {
            fatalError(
                "API_BASE_URL is missing or invalid."
            )
        }

        AuthenticationConfiguration.shared.configure(
            baseURL: baseURL
        )
    }

    var body: some Scene {
        WindowGroup {
            AuthenticationRootView(
                environment: appDelegate.environment
            )
        }
    }
}
