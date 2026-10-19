import AuthenticationKit
import SwiftUI

@main
struct WakTrainerApp: App {
    @UIApplicationDelegateAdaptor(
        WakTrainerAppDelegate.self
    )
    private var appDelegate

    init() {
#if DEBUG && targetEnvironment(simulator)
        UserDefaults.standard.set(true, forKey: "WakTrainer.debug.simulateWorkout")
#endif
        let configuredBaseURL =
            (Bundle.main.object(
                forInfoDictionaryKey: "API_BASE_URL"
            ) as? String)
            .flatMap(URL.init(string:))

        let productionBaseURL =
            URL(
                string:
                    "https://waktrainerserver-production.up.railway.app"
            )!

        AuthenticationConfiguration.shared.configure(
            baseURL:
                configuredBaseURL
                ?? productionBaseURL
        )
    }

    var body: some Scene {
        WindowGroup {
            AppStartupSplash {
#if WAKTRAINER_DEMO
            ContentView(
                environment: appDelegate.environment
            )
#else
            AuthenticationRootView(
                environment: appDelegate.environment
            )
#endif
            }
        }
    }
}
