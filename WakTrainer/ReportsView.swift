import SwiftUI

struct ReportsView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        NavigationStack {
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
                    List(
                        environment.workoutHistory
                    ) { record in
                        NavigationLink {
                            WorkoutReportDetailView(
                                record: record
                            )
                        } label: {
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
                    }
                }
            }
            .navigationTitle("운동 리포트")
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
                        "심박수와 칼로리의 시계열 데이터가 WorkoutFeatureResult에 포함되면 WakTrainerChart를 사용해 실제 운동 그래프를 표시합니다."
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
        let minutes = (totalSeconds % 3600) / 60
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
