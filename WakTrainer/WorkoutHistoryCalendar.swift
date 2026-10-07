import Foundation

enum WorkoutHistoryCalendar {
    static func highlightedDates(
        from records: [WorkoutSummaryRecord],
        calendar: Calendar = .current
    ) -> Set<Date> {
        Set(
            records.map {
                calendar.startOfDay(
                    for: $0.startedAt
                )
            }
        )
    }

    static func records(
        on selectedDate: Date?,
        from records: [WorkoutSummaryRecord],
        calendar: Calendar = .current
    ) -> [WorkoutSummaryRecord] {
        guard let selectedDate else {
            return records
        }

        return records.filter {
            calendar.isDate(
                $0.startedAt,
                inSameDayAs: selectedDate
            )
        }
    }
}
