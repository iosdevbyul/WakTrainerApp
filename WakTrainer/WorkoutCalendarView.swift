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
                            locale: .system,
                            timeZone: .system,
                            weekStart: .system
                        )
                )

                workoutSection
            }
            .padding()
        }
        .navigationTitle("캘린더")
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
                    selectedDate.formatted(
                        date: .long,
                        time: .omitted
                    )
                )
                .font(.headline)

                if selectedRecords.isEmpty {
                    ContentUnavailableView(
                        "운동 기록이 없습니다",
                        systemImage:
                            "figure.run",
                        description: Text(
                            "선택한 날짜에 저장된 운동이 없습니다."
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
                "날짜를 선택해 주세요",
                systemImage: "calendar",
                description: Text(
                    "운동한 날짜는 캘린더에 표시됩니다."
                )
            )
        }
    }
}
