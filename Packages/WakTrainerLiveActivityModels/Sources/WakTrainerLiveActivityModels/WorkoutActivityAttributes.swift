import ActivityKit
import Foundation

public struct WorkoutActivityAttributes: ActivityAttributes {
    public enum Kind: String, Codable, Hashable {
        case cardio
        case strength
    }

    public enum Phase: String, Codable, Hashable {
        case running
        case paused
    }

    public struct ContentState: Codable, Hashable {
        public var phase: Phase
        public var elapsedSeconds: TimeInterval
        public var runningSince: Date?
        public var heartRate: Int
        public var calories: Int
        public var distanceMeters: Double
        public var steps: Int
        public var exercise: String?
        public var completedSets: Int

        public init(
            phase: Phase,
            elapsedSeconds: TimeInterval,
            runningSince: Date?,
            heartRate: Int,
            calories: Int,
            distanceMeters: Double,
            steps: Int,
            exercise: String?,
            completedSets: Int
        ) {
            self.phase = phase
            self.elapsedSeconds = elapsedSeconds
            self.runningSince = runningSince
            self.heartRate = heartRate
            self.calories = calories
            self.distanceMeters = distanceMeters
            self.steps = steps
            self.exercise = exercise
            self.completedSets = completedSets
        }
    }

    public var name: String
    public var kind: Kind

    public init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }
}
