import SwiftUI
import TrisCalendarKit

struct WorkoutCalendarView: View {
    @ObservedObject var environment: AppEnvironment

    @State
    private var displayedMonth = Date()

    @State
    private var selectedDate: Date?

    private var highlightedDates: Set<Date> {
        WorkoutHistoryCalendar
            .highlightedDates(
                from:
                    environment.workoutHistory
            )
    }

    private var selectedRecords:
        [WorkoutSummaryRecord] {

        WorkoutHistoryCalendar.records(
            on: selectedDate,
            from:
                environment.workoutHistory
        )
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

                if selectedRecords.isEmpty {
                    ContentUnavailableView(
                        AppL10n.string("calendar.no_records.title"),
                        systemImage:
                            "figure.run",
                        description: Text(
                            AppL10n.string("calendar.no_records.description")
                        )
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(
                            selectedRecords
                        ) { record in
                            NavigationLink {
                                WorkoutReportDetailView(
                                    record: record
                                )
                            } label: {
                                WorkoutReportRow(
                                    record: record
                                )
                                .frame(
                                    maxWidth:
                                        .infinity,
                                    alignment:
                                        .leading
                                )
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            if record.id
                                != selectedRecords
                                    .last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .background(
                        .regularMaterial
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
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
