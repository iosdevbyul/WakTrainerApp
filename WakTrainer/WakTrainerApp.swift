import SwiftUI

@main
struct WakTrainerApp: App {
    @UIApplicationDelegateAdaptor(
        WakTrainerAppDelegate.self
    )
    private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(
                environment: appDelegate.environment
            )
        }
    }
}
