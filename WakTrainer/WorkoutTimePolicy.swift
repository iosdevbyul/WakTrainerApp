import Foundation

/// Time policy for recorded workouts. Date values are absolute instants:
/// never apply a timezone offset before persisting or uploading them.
enum WorkoutTimePolicy {
    static func unixMilliseconds(for instant: Date) -> Int64 {
        Int64((instant.timeIntervalSince1970 * 1_000).rounded())
    }

    static func date(
        for instant: Date,
        in timeZone: TimeZone = .autoupdatingCurrent
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: instant)
    }

    static func calendar(
        in timeZone: TimeZone = .autoupdatingCurrent
    ) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// Collected time and server ingestion time are different events.
    /// A late upload must never rewrite the original measurement instant.
    static func originalMeasurementTime(
        measuredAt: Date,
        receivedAt _: Date
    ) -> Date {
        measuredAt
    }
}
