import Foundation
import XCTest
@testable import WakTrainer

final class WorkoutTimePolicyTests: XCTestCase {
    func testSameInstantIsGroupedByViewingTimeZone() throws {
        let instant = Date(timeIntervalSince1970: 1_782_357_600) // illustrative fixed instant
        let seoul = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        let vancouver = try XCTUnwrap(TimeZone(identifier: "America/Vancouver"))

        let koreanDay = WorkoutTimePolicy.date(for: instant, in: seoul)
        let canadianDay = WorkoutTimePolicy.date(for: instant, in: vancouver)

        let koreanComponents = WorkoutTimePolicy.calendar(in: seoul)
            .dateComponents([.year, .month, .day], from: koreanDay)
        let canadianComponents = WorkoutTimePolicy.calendar(in: vancouver)
            .dateComponents([.year, .month, .day], from: canadianDay)
        XCTAssertEqual(koreanComponents.year, 2026)
        XCTAssertEqual(canadianComponents.year, 2026)
        XCTAssertNotEqual(koreanComponents.day, canadianComponents.day)
        XCTAssertEqual(instant.timeIntervalSince1970, 1_782_357_600)
    }

    func testMeasurementTimeRemainsUnchangedWhenUploadOccursLater() {
        let measured = Date(timeIntervalSince1970: 1_782_357_600)
        let received = measured.addingTimeInterval(86_400)
        XCTAssertEqual(
            WorkoutTimePolicy.originalMeasurementTime(
                measuredAt: measured,
                receivedAt: received
            ),
            measured
        )
        XCTAssertEqual(
            WorkoutTimePolicy.unixMilliseconds(for: measured),
            1_782_357_600_000
        )
    }

    func testDSTLocalDayMayNotBeTwentyFourHours() throws {
        let vancouver = try XCTUnwrap(TimeZone(identifier: "America/Vancouver"))
        let calendar = WorkoutTimePolicy.calendar(in: vancouver)
        let day = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 3, day: 8
        )))
        let nextDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: day))
        XCTAssertEqual(nextDay.timeIntervalSince(day), 23 * 3_600)
    }
}
