import SwiftUI
import TrisCalendarKit
import WakTrainerDesignSystem
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
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: WakSpacing.large
                ) {
                    WakCard {
                        MonthCalendarView(
                            displayedMonth:
                                $displayedMonth,
                            selectedDate:
                                $selectedDate,
                            highlightedDates:
                                highlightedDates,
                            configuration:
                                CalendarConfiguration(
                                    locale:
                                        .custom(
                                            AppL10n.locale
                                        ),
                                    timeZone: .system,
                                    weekStart: .system
                                )
                        )
                        .tint(WakColor.primary)
                    }

                    workoutSection
                }
                .padding(WakSpacing.regular)
            }
        }
        .navigationTitle(
            AppL10n.string(
                "common.calendar"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            WakColor.background,
            for: .navigationBar
        )
        .toolbarBackground(
            .visible,
            for: .navigationBar
        )
        .toolbarColorScheme(
            .dark,
            for: .navigationBar
        )
    }

    @ViewBuilder
    private var workoutSection: some View {
        if let selectedDate {
            VStack(
                alignment: .leading,
                spacing: WakSpacing.medium
            ) {
                Text(
                    AppL10n.date(
                        selectedDate,
                        dateStyle: .long
                    )
                )
                .font(WakTypography.sectionTitle)
                .foregroundStyle(
                    WakColor.textPrimary
                )

                WorkoutHistoryView(
                    selectedDate: selectedDate
                )
                .scrollContentBackground(.hidden)
            }
        } else {
            WakCard {
                ContentUnavailableView(
                    AppL10n.string(
                        "calendar.select_date.title"
                    ),
                    systemImage: "calendar",
                    description: Text(
                        AppL10n.string(
                            "calendar.select_date.description"
                        )
                    )
                )
                .foregroundStyle(
                    WakColor.textSecondary
                )
            }
        }
    }
}
