import SwiftUI
import TrisCalendarKit

struct ReportsView: View {
    @ObservedObject var environment: AppEnvironment

    @State
    private var displayedMonth = Date()

    @State
    private var selectedDate: Date?

    private var filteredRecords: [WorkoutSummaryRecord] {
        WorkoutHistoryCalendar.records(
            on: selectedDate,
            from: environment.workoutHistory
        )
    }

    private var highlightedDates: Set<Date> {
        WorkoutHistoryCalendar.highlightedDates(
            from: environment.workoutHistory
        )
    }

    var body: some View {
        Group {
            if environment.workoutHistory.isEmpty {
                ContentUnavailableView(
                    "아직 운동 기록이 없습니다",
                    systemImage: "chart.xyaxis.line",
                    description: Text(
                        "운동을 완료하면 시간, 거리, 칼로리와 걸음 수가 이곳에 저장됩니다."
                    )
                )
            } else {
                List {
                    Section {
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
                        .padding(.vertical, 8)
                    }

                    if let selectedDate {
                        Section {
                            HStack {
                                Text(
                                    selectedDate.formatted(
                                        date: .long,
                                        time: .omitted
                                    )
                                )
                                .font(.headline)

                                Spacer()

                                Button("전체 보기") {
                                    self.selectedDate =
                                        nil
                                }
                                .font(.subheadline)
                            }
                        }
                    }

                    Section {
                        if filteredRecords.isEmpty {
                            Text(
                                "선택한 날짜에 운동 기록이 없습니다."
                            )
                            .foregroundStyle(.secondary)
                        } else {
                            ForEach(
                                filteredRecords
                            ) { record in
                                NavigationLink {
                                    WorkoutReportDetailView(
                                        record: record
                                    )
                                } label: {
                                    workoutRow(
                                        record
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("운동 리포트")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func workoutRow(
        _ record: WorkoutSummaryRecord
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            Text(record.workoutName)
                .font(.headline)

            Text(
                record.endedAt.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text(
                    durationText(
                        record.duration
                    )
                )

                Text(
                    String(
                        format: "%.0f kcal",
                        record.activeCalories
                    )
                )
            }
            .font(.subheadline)
        }
    }

    private func durationText(
        _ duration: TimeInterval
    ) -> String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        return "\(minutes)분"
    }
}

private struct WorkoutReportDetailView: View {
    let record: WorkoutSummaryRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                metric(
                    title: "운동 시간",
                    value: durationText
                )

                metric(
                    title: "소모 칼로리",
                    value: String(
                        format: "%.0f kcal",
                        record.activeCalories
                    )
                )

                metric(
                    title: "걸음 수",
                    value: String(
                        format: "%.0f",
                        record.stepCount
                    )
                )

                metric(
                    title: "이동 거리",
                    value: String(
                        format: "%.2f km",
                        record.distanceMeters / 1000
                    )
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("세부 운동 그래프")
                        .font(.headline)

                    Text(
                        "WorkoutSession에 수집된 심박수와 운동 시계열 데이터를 기반으로 다음 단계에서 WakTrainerChart 그래프를 표시합니다."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
            }
            .padding()
        }
        .navigationTitle(record.workoutName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metric(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var durationText: String {
        let totalSeconds = Int(record.duration)
        let hours = totalSeconds / 3600
        let minutes =
            (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(
                format: "%02d:%02d:%02d",
                hours,
                minutes,
                seconds
            )
        }

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}
