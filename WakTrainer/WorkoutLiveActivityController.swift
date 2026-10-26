import ActivityKit
import Foundation
import TrisLiveActivityKit
import WakTrainerFeatureWorkout
import WakTrainerLiveActivityModels

@MainActor
final class WorkoutLiveActivityController {
    static let shared = WorkoutLiveActivityController()

    private let service: any LiveActivityServiceProtocol
    private var activityID: String?
    private var lastState: WorkoutActivityAttributes.ContentState?
    private var lastUpdateDate: Date = .distantPast
    private var isProcessing = false
    private var pendingSnapshot: WorkoutLiveSnapshot?
    private(set) var lastFailureDescription: String?

    init(service: any LiveActivityServiceProtocol = LiveActivityService()) {
        self.service = service
    }

    func receive(_ snapshot: WorkoutLiveSnapshot) {
        if snapshot.phase == .finished {
            finish()
            return
        }
        guard service.areActivitiesEnabled else {
            lastFailureDescription = "Live Activities are disabled for WakTrainer in iOS settings."
            print("WakTrainer Live Activity: \(lastFailureDescription!)")
            return
        }

        let now = Date()
        let state = WorkoutActivityAttributes.ContentState(
            phase: snapshot.phase == .running ? .running : .paused,
            elapsedSeconds: max(0, snapshot.elapsedSeconds),
            runningSince: snapshot.phase == .running ? now.addingTimeInterval(-max(0, snapshot.elapsedSeconds)) : nil,
            heartRate: Int(max(0, snapshot.heartRateBPM)),
            calories: Int(max(0, snapshot.activeCalories)),
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
                    activityID = try service.start(
                        attributes: WorkoutActivityAttributes(
                            name: snapshot.workoutName,
                            kind: snapshot.kind == .strength ? .strength : .cardio
                        ),
                        state: state,
                        staleDate: now.addingTimeInterval(60)
                    )
                }
                lastState = state
                lastUpdateDate = now
                lastFailureDescription = nil
            } catch {
                // A Live Activity failure must never interrupt a workout.
                lastFailureDescription = error.localizedDescription
                activityID = nil
                print("WakTrainer Live Activity request failed: \(error)")
            }
        }
    }

    func finish() {
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
