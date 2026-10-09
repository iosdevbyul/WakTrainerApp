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

    init(service: any LiveActivityServiceProtocol = LiveActivityService()) {
        self.service = service
    }

    func receive(_ snapshot: WorkoutLiveSnapshot) {
        if snapshot.phase == .finished {
            finish()
            return
        }
        guard service.areActivitiesEnabled else { return }

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
              now.timeIntervalSince(lastUpdateDate) >= 10 else { return }

        guard !isProcessing else { return }
        isProcessing = true
        Task {
            defer { isProcessing = false }
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
            } catch {
                // A Live Activity failure must never interrupt a workout.
                print("Live Activity update failed: \(error)")
            }
        }
    }

    func finish() {
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
