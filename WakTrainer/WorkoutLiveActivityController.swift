import ActivityKit
import Combine
import Foundation
import SwiftUI
import TrisLiveActivityKit
import WakTrainerFeatureWorkout
import WakTrainerLiveActivityModels
import UserProfileFeature

@MainActor
final class WorkoutLiveActivityController: ObservableObject {
    struct Failure: Identifiable {
        let id = UUID()
        let message: String
    }

    @Published var failure: Failure?
    @Published private(set) var resumeRequestID: UUID?

    func handleActivityURL(_ url: URL) {
        print("WakTrainer Live Activity URL received: scheme=\(url.scheme ?? "none"), host=\(url.host ?? "none"), path=\(url.path), bundle=\(Bundle.main.bundleIdentifier ?? "unknown")")
        guard ["waktrainer", "waktrainer-demo", "waktrainer-device-test"].contains(url.scheme ?? ""),
              url.host == "workout", url.path == "/resume" else {
            print("WakTrainer Live Activity URL rejected: invalid workout resume route")
            return
        }
        resumeRequestID = UUID()
        print("WakTrainer Live Activity direct resume requested")
    }

    static let shared = WorkoutLiveActivityController()

    private let service: any LiveActivityServiceProtocol
    private var activityID: String?
    private var lastState: WorkoutActivityAttributes.ContentState?
    private var lastUpdateDate: Date = .distantPast
    private var isProcessing = false
    private var pendingSnapshot: WorkoutLiveSnapshot?
    private var lifecycleGeneration = 0
    private var hasObservedWorkoutSnapshot = false
    private(set) var lastFailureDescription: String?

    init(service: any LiveActivityServiceProtocol = LiveActivityService()) {
        self.service = service

        // ActivityKit preserves a running Live Activity even when the app
        // process is terminated. Reopen the matching saved workout before
        // SwiftUI's normal Resume/Delete recovery presentation begins.
        // Do not rely on the Live Activity URL reaching a cold scene first.
        let activeWorkoutIDs = service.activeIDs(for: WorkoutActivityAttributes.self)
        if !activeWorkoutIDs.isEmpty {
            resumeRequestID = UUID()
            print("WakTrainer Live Activity cold launch: active workout activity found; requesting direct workout screen")
        }
    }

    func receive(_ snapshot: WorkoutLiveSnapshot) {
        if !hasObservedWorkoutSnapshot {
            hasObservedWorkoutSnapshot = true
            print("WakTrainer Live Activity received first workout snapshot: phase=\(snapshot.phase), enabled=\(service.areActivitiesEnabled), bundle=\(Bundle.main.bundleIdentifier ?? "unknown")")
        }
        if snapshot.phase == .finished {
            finish()
            return
        }
        guard service.areActivitiesEnabled else {
            reportFailure("Live Activities are disabled for this app. Check Settings > Apps > WakTrainerDemo > Live Activities, and Settings > Face ID & Passcode > Live Activities. Then try starting a workout again.")
            return
        }

        let now = Date()
        let maximumHeartRate: Double? = {
            guard let profile = DefaultUserProfileManager.shared.loadProfile() ?? DefaultUserProfileManager.shared.profile,
                  (1...100).contains(profile.age) else { return nil }
            return Double(220 - profile.age)
        }()
        let zone: Int? = {
            guard let maximumHeartRate, snapshot.heartRateBPM > 0 else { return nil }
            let proportion = snapshot.heartRateBPM / maximumHeartRate
            if proportion < 0.5 { return nil }
            if proportion < 0.6 { return 1 }
            if proportion < 0.7 { return 2 }
            if proportion < 0.8 { return 3 }
            if proportion < 0.9 { return 4 }
            return 5
        }()
        let state = WorkoutActivityAttributes.ContentState(
            phase: snapshot.phase == .running ? .running : .paused,
            elapsedSeconds: max(0, snapshot.elapsedSeconds),
            runningSince: snapshot.phase == .running ? now.addingTimeInterval(-max(0, snapshot.elapsedSeconds)) : nil,
            heartRate: Int(max(0, snapshot.heartRateBPM)),
            calories: Int(max(0, snapshot.activeCalories)),
            heartRateZone: zone,
            totalCalories: nil,
            distanceMeters: max(0, snapshot.distanceMeters),
            steps: Int(max(0, snapshot.steps)),
            exercise: snapshot.currentExerciseName,
            completedSets: snapshot.completedSets
        )

        // Avoid a new ActivityKit update every second. Always propagate state transitions.
        guard state.phase != lastState?.phase ||
              state.exercise != lastState?.exercise ||
              state.completedSets != lastState?.completedSets ||
              activityID == nil ||
              now.timeIntervalSince(lastUpdateDate) >= 10 else { return }

        guard !isProcessing else {
            pendingSnapshot = snapshot
            return
        }
        isProcessing = true
        let generation = lifecycleGeneration
        Task {
            defer {
                isProcessing = false
                if let pending = pendingSnapshot {
                    pendingSnapshot = nil
                    receive(pending)
                }
            }
            do {
                if activityID == nil {
                    // Reconcile a still-existing activity after a scene restart.
                    activityID = service.activeIDs(for: WorkoutActivityAttributes.self).first
                }
                if let activityID {
                    try await service.update(
                        id: activityID,
                        as: WorkoutActivityAttributes.self,
                        state: state,
                        staleDate: now.addingTimeInterval(60)
                    )
                } else {
                    let startedID = try service.start(
                        attributes: WorkoutActivityAttributes(
                            name: snapshot.workoutName,
                            kind: snapshot.kind == .strength ? .strength : .cardio
                        ),
                        state: state,
                        staleDate: now.addingTimeInterval(60)
                    )
                    if generation != lifecycleGeneration {
                        try? await service.end(
                            id: startedID,
                            as: WorkoutActivityAttributes.self,
                            finalState: nil,
                            dismissalPolicy: .immediate
                        )
                        return
                    }
                    activityID = startedID
                    print("WakTrainer Live Activity started: \(startedID) [\(Bundle.main.bundleIdentifier ?? "unknown bundle")]")
                }
                guard generation == lifecycleGeneration else { return }
                lastState = state
                lastUpdateDate = now
                lastFailureDescription = nil
            } catch {
                // A Live Activity failure must never interrupt a workout.
                guard generation == lifecycleGeneration else { return }
                activityID = nil
                reportFailure("ActivityKit request failed: \(error.localizedDescription). App: \(Bundle.main.bundleIdentifier ?? "unknown"). Confirm Live Activities are enabled and the app's widget extension is installed.")
                print("WakTrainer Live Activity request failed: \(error)")
            }
        }
    }

    private func reportFailure(_ message: String) {
        guard lastFailureDescription != message else { return }
        lastFailureDescription = message
        failure = Failure(message: message)
        print("WakTrainer Live Activity: \(message)")
    }

    func finish() {
        print("WakTrainer Live Activity finish requested; snapshotObserved=\(hasObservedWorkoutSnapshot), activityID=\(activityID ?? "none")")
        lifecycleGeneration += 1
        pendingSnapshot = nil
        let id = activityID ?? service.activeIDs(for: WorkoutActivityAttributes.self).first
        guard let id else { return }
        activityID = nil
        lastState = nil
        Task {
            try? await service.end(
                id: id,
                as: WorkoutActivityAttributes.self,
                finalState: nil,
                dismissalPolicy: .immediate
            )
        }
    }
}
