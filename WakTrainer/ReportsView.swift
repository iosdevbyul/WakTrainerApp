import SwiftUI

struct ReportsView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Group {
            if environment.workoutHistory.isEmpty {
                ContentUnavailableView(
                    AppL10n.string("reports.empty.title"),
                    systemImage: "chart.xyaxis.line",
                    description: Text(
                        AppL10n.string("reports.empty.description")
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
                        WorkoutReportRow(
                            record: record
                        )
                    }
                }
            }
        }
        .navigationTitle(AppL10n.string("reports.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorkoutReportRow: View {
    let record: WorkoutSummaryRecord

    var body: some View {
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
            return AppL10n.format("duration.hours_minutes", hours, minutes)
        }

        return AppL10n.format("duration.minutes", minutes)
    }
}

struct WorkoutReportDetailView: View {
    let record: WorkoutSummaryRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                metric(
                    title: AppL10n.string("reports.duration"),
                    value: durationText
                )

                metric(
                    title: AppL10n.string("reports.calories"),
                    value: String(
                        format: "%.0f kcal",
                        record.activeCalories
                    )
                )

                metric(
                    title: AppL10n.string("reports.steps"),
                    value: String(
                        format: "%.0f",
                        record.stepCount
                    )
                )

                metric(
                    title: AppL10n.string("reports.distance"),
                    value: String(
                        format: "%.2f km",
                        record.distanceMeters / 1000
                    )
                )

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text(AppL10n.string("reports.chart.title"))
                        .font(.headline)

                    Text(
                        AppL10n.string("reports.chart.description")
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
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
            RoundedRectangle(
                cornerRadius: 16
            )
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
