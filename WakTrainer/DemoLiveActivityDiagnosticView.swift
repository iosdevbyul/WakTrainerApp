#if WAKTRAINER_DEMO
import ActivityKit
import SwiftUI
import WakTrainerLiveActivityModels

/// Runs a real ActivityKit request from the installed demo app, independent of
/// workout callbacks. This is intentionally unavailable in production builds.
struct DemoLiveActivityDiagnosticView: View {
    @State private var requestedActivityID: String?
    @State private var result = "No request sent yet."
    @State private var isWorking = false

    private var activeActivities: [Activity<WorkoutActivityAttributes>] {
        Activity<WorkoutActivityAttributes>.activities
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Device configuration") {
                    LabeledContent("App bundle", value: Bundle.main.bundleIdentifier ?? "unknown")
                    LabeledContent(
                        "Live Activities",
                        value: ActivityAuthorizationInfo().areActivitiesEnabled ? "Enabled" : "Disabled"
                    )
                    LabeledContent("Active workout activities", value: "\(activeActivities.count)")
                }

                Section("Real ActivityKit test") {
                    Text("This sends a real Live Activity request without starting or saving a workout. Check the Lock Screen and Dynamic Island after tapping Start Test.")
                        .font(.footnote)
                    Button("Start Test") { startTest() }
                        .disabled(isWorking || !ActivityAuthorizationInfo().areActivitiesEnabled || requestedActivityID != nil)
                    Button("Refresh Status") { refreshStatus() }
                    Button("End Test") { endTest() }
                        .disabled(isWorking || requestedActivityID == nil)
                }

                Section("Result") {
                    Text(result)
                        .textSelection(.enabled)
                    if let requestedActivityID {
                        Text("Requested activity ID: \(requestedActivityID)")
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Live Activity Test")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { refreshStatus() }
        }
    }

    private func startTest() {
        guard !isWorking else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result = "ActivityKit is disabled. Enable Live Activities in iPhone Settings for WakTrainerDemo."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let activity = try Activity<WorkoutActivityAttributes>.request(
                attributes: WorkoutActivityAttributes(name: "Demo Activity Test", kind: .strength),
                content: ActivityContent(
                    state: WorkoutActivityAttributes.ContentState(
                        phase: .running,
                        elapsedSeconds: 0,
                        runningSince: Date(),
                        heartRate: 80,
                        calories: 0,
                        distanceMeters: 0,
                        steps: 0,
                        exercise: "Demo Test",
                        completedSets: 0
                    ),
                    staleDate: nil
                ),
                pushType: nil
            )
            requestedActivityID = activity.id
            refreshStatus()
            print("WakTrainerDemo ActivityKit direct test started: \(activity.id)")
        } catch {
            result = "ActivityKit request failed: \(error.localizedDescription)"
            print("WakTrainerDemo ActivityKit direct test failed: \(error)")
        }
    }

    private func refreshStatus() {
        let ids = activeActivities.map(\.id)
        if let requestedActivityID {
            result = ids.contains(requestedActivityID)
                ? "ActivityKit accepted the request and the activity is active. Check the Lock Screen and Dynamic Island; visible rendering still requires device inspection."
                : "The requested activity is not in ActivityKit's active list. Check device logs and Live Activity settings."
        } else {
            result = "ActivityKit reports \(ids.count) active workout activities. Tap Start Test to test this demo app's widget independently."
        }
    }

    private func endTest() {
        guard let requestedActivityID, !isWorking else { return }
        isWorking = true
        Task {
            if let activity = activeActivities.first(where: { $0.id == requestedActivityID }) {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.requestedActivityID = nil
            isWorking = false
            refreshStatus()
        }
    }
}
#endif
