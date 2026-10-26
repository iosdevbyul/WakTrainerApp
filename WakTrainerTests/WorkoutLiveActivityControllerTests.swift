import ActivityKit
import Foundation
import TrisLiveActivityKit
import WakTrainerFeatureWorkout
import XCTest
@testable import WakTrainer

final class WorkoutLiveActivityControllerTests: XCTestCase {
    @MainActor
    func testDisabledActivitiesExposeActionableFailure() {
        let service = StubLiveActivityService(enabled: false)
        let controller = WorkoutLiveActivityController(service: service)

        controller.receive(snapshot)

        XCTAssertNotNil(controller.failure)
        XCTAssertTrue(controller.lastFailureDescription?.contains("Settings") == true)
        XCTAssertEqual(service.startCount, 0)
    }

    @MainActor
    func testStartingAndFinishingUsesActivityService() async throws {
        let service = StubLiveActivityService(enabled: true)
        let controller = WorkoutLiveActivityController(service: service)

        controller.receive(snapshot)
        for _ in 0..<40 where service.startCount == 0 {
            await Task.yield()
        }
        XCTAssertEqual(service.startCount, 1)
        XCTAssertNil(controller.lastFailureDescription)

        controller.finish()
        for _ in 0..<40 where service.endCount == 0 {
            await Task.yield()
        }
        XCTAssertEqual(service.endCount, 1)
    }

    private var snapshot: WorkoutLiveSnapshot {
        WorkoutLiveSnapshot(
            kind: .strength,
            phase: .running,
            workoutName: "Strength Training",
            elapsedSeconds: 10,
            heartRateBPM: 0,
            activeCalories: 0,
            distanceMeters: 0,
            steps: 0,
            currentExerciseName: "Bench Press",
            completedSets: 1
        )
    }
}

private final class StubLiveActivityService: LiveActivityServiceProtocol {
    let enabled: Bool
    var startCount = 0
    var endCount = 0

    init(enabled: Bool) { self.enabled = enabled }
    var areActivitiesEnabled: Bool { enabled }

    func start<Attributes: ActivityAttributes>(
        attributes: Attributes,
        state: Attributes.ContentState,
        staleDate: Date?
    ) throws -> String {
        startCount += 1
        return "test-activity"
    }

    func update<Attributes: ActivityAttributes>(
        id: String,
        as type: Attributes.Type,
        state: Attributes.ContentState,
        staleDate: Date?
    ) async throws {}

    func end<Attributes: ActivityAttributes>(
        id: String,
        as type: Attributes.Type,
        finalState: Attributes.ContentState?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async throws {
        endCount += 1
    }

    func activeIDs<Attributes: ActivityAttributes>(for type: Attributes.Type) -> [String] { [] }
}
