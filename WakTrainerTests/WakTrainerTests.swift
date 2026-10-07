//
//  WakTrainerTests.swift
//  WakTrainerTests
//
//  Created by COMATOKI on 2026-08-01.
//

import XCTest
@testable import WakTrainer

final class WakTrainerTests: XCTestCase {
    func testWorkoutHistoryCalendarHighlightsUniqueWorkoutDates() {
        let calendar = utcCalendar
        let records = [
            record(
                id: UUID(),
                startedAt: date(
                    year: 2026,
                    month: 10,
                    day: 5,
                    hour: 9
                )
            ),
            record(
                id: UUID(),
                startedAt: date(
                    year: 2026,
                    month: 10,
                    day: 5,
                    hour: 18
                )
            ),
            record(
                id: UUID(),
                startedAt: date(
                    year: 2026,
                    month: 10,
                    day: 7,
                    hour: 7
                )
            )
        ]

        let highlighted =
            WorkoutHistoryCalendar
                .highlightedDates(
                    from: records,
                    calendar: calendar
                )

        XCTAssertEqual(
            highlighted.count,
            2
        )

        XCTAssertTrue(
            highlighted.contains(
                calendar.startOfDay(
                    for: records[0].startedAt
                )
            )
        )

        XCTAssertTrue(
            highlighted.contains(
                calendar.startOfDay(
                    for: records[2].startedAt
                )
            )
        )
    }

    func testWorkoutHistoryCalendarFiltersSelectedDay() {
        let records = [
            record(
                id: UUID(),
                startedAt: date(
                    year: 2026,
                    month: 10,
                    day: 5,
                    hour: 9
                )
            ),
            record(
                id: UUID(),
                startedAt: date(
                    year: 2026,
                    month: 10,
                    day: 6,
                    hour: 9
                )
            )
        ]

        let selected =
            date(
                year: 2026,
                month: 10,
                day: 5,
                hour: 22
            )

        let filtered =
            WorkoutHistoryCalendar.records(
                on: selected,
                from: records,
                calendar: utcCalendar
            )

        XCTAssertEqual(
            filtered.map(\.id),
            [records[0].id]
        )
    }

    func testWorkoutHistoryCalendarReturnsAllWhenNoDateSelected() {
        let records = [
            record(
                id: UUID(),
                startedAt: date(
                    year: 2026,
                    month: 10,
                    day: 5,
                    hour: 9
                )
            ),
            record(
                id: UUID(),
                startedAt: date(
                    year: 2026,
                    month: 10,
                    day: 6,
                    hour: 9
                )
            )
        ]

        XCTAssertEqual(
            WorkoutHistoryCalendar.records(
                on: nil,
                from: records,
                calendar: utcCalendar
            ),
            records
        )
    }

    private var utcCalendar: Calendar {
        var calendar =
            Calendar(
                identifier: .gregorian
            )

        calendar.timeZone =
            TimeZone(secondsFromGMT: 0)!

        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int
    ) -> Date {
        utcCalendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }

    private func record(
        id: UUID,
        startedAt: Date
    ) -> WorkoutSummaryRecord {
        WorkoutSummaryRecord(
            id: id,
            workoutID: "workout",
            workoutName: "Workout",
            startedAt: startedAt,
            endedAt:
                startedAt.addingTimeInterval(
                    3600
                ),
            duration: 3600,
            distanceMeters: 1000,
            activeCalories: 300,
            stepCount: 2000
        )
    }
}
