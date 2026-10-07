import SwiftUI
import TrisCalendarKit
import WakTrainerFeatureWorkout

struct WorkoutCalendarView: View {
    @ObservedObject var workoutHistoryStore:
        WorkoutHistoryStore

    @State
    private var displayedMonth = Date()

    @State
    private var selectedDate: Date?

    private var highlightedDates: Set<Date> {
        workoutHistoryStore
            .highlightedDates()
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                MonthCalendarView(
                    displayedMonth:
                        $displayedMonth,
                    selectedDate:
                        $selectedDate,
                    highlightedDates:
                        highlightedDates,
                    configuration:
                        CalendarConfiguration(
                            locale: .custom(AppL10n.locale),
                            timeZone: .system,
                            weekStart: .system
                        )
                )

                workoutSection
            }
            .padding()
        }
        .navigationTitle(AppL10n.string("common.calendar"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var workoutSection: some View {
        if let selectedDate {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text(
                    AppL10n.date(
                        selectedDate,
                        dateStyle: .long
                    )
                )
                .font(.headline)

                WorkoutHistoryView(
                    selectedDate: selectedDate
                )
            }
        } else {
            ContentUnavailableView(
                AppL10n.string("calendar.select_date.title"),
                systemImage: "calendar",
                description: Text(
                    AppL10n.string("calendar.select_date.description")
                )
            )
        }
    }
}
