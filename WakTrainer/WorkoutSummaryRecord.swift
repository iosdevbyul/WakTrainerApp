import Foundation

struct WorkoutSummaryRecord: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let workoutID: String
    let workoutName: String
    let startedAt: Date
    let endedAt: Date
    let duration: TimeInterval
    let distanceMeters: Double
    let activeCalories: Double
    let stepCount: Double

    init(
        id: UUID = UUID(),
        workoutID: String,
        workoutName: String,
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        activeCalories: Double,
        stepCount: Double
    ) {
        self.id = id
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.activeCalories = activeCalories
        self.stepCount = stepCount
    }
}
