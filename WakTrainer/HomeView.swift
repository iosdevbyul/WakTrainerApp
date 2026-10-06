import SwiftUI
import TrisPlaceRecognitionKit

struct HomeView: View {
    @ObservedObject var environment: AppEnvironment

    let onShowReports: () -> Void
    let onShowPlaces: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                introCard
                placeCard
                reportCard
            }
            .padding()
        }
        .navigationTitle("오늘")
    }

    private var introCard: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("오늘의 운동")
                .font(.title2.bold())

            Text(
                "화면 아래 운동 버튼을 눌러 원하는 운동을 바로 시작할 수 있습니다."
            )
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    @ViewBuilder
    private var placeCard: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Label(
                "헬스장 자동 감지",
                systemImage: "location.fill"
            )
            .font(.headline)

            if let visitManager = environment.visitManager {
                PlaceRecognitionStatusView(
                    visitManager: visitManager
                )
            } else if environment.isPreparingPlaces {
                ProgressView("장소 인식 준비 중")
            } else {
                Text(
                    "장소 인식 서비스를 준비하고 있습니다."
                )
                .foregroundStyle(.secondary)
            }

            if let message =
                environment.placeStatusMessage
            {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error =
                environment.placeErrorMessage
            {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack {
                if environment
                    .isPlaceRecognitionRequested
                {
                    Button("자동 감지 끄기") {
                        Task {
                            await environment
                                .disablePlaceRecognition()
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("헬스장 감지 켜기") {
                        Task {
                            await environment
                                .enablePlaceRecognition()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()

                Button("장소 관리") {
                    onShowPlaces()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    @ViewBuilder
    private var reportCard: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack {
                Label(
                    "운동 기록",
                    systemImage: "chart.xyaxis.line"
                )
                .font(.headline)

                Spacer()

                Button("전체 보기") {
                    onShowReports()
                }
                .font(.subheadline)
            }

            if let latest =
                environment.workoutHistory.first
            {
                Button {
                    onShowReports()
                } label: {
                    HStack {
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text(latest.workoutName)
                                .font(.title3.bold())
                                .foregroundStyle(
                                    .primary
                                )

                            Text(
                                latest.endedAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.footnote)
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Spacer()

                        Text(
                            formattedDuration(
                                latest.duration
                            )
                        )
                        .font(
                            .title3
                                .monospacedDigit()
                        )
                        .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(
                    "아직 완료한 운동이 없습니다. 첫 운동을 시작해 보세요."
                )
                .foregroundStyle(.secondary)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private func formattedDuration(
        _ duration: TimeInterval
    ) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes =
            (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        return "\(minutes)분"
    }
}

private struct PlaceRecognitionStatusView: View {
    @ObservedObject var visitManager: PlaceVisitManager

    var body: some View {
        if let place =
            visitManager.recognizedPlaces.first?.place
        {
            Label(
                "\(place.name.value)에 있습니다.",
                systemImage:
                    "checkmark.circle.fill"
            )
            .font(.title3.bold())
        } else if !visitManager.activeVisits.isEmpty {
            Label(
                "등록된 장소에 있습니다.",
                systemImage:
                    "checkmark.circle.fill"
            )
            .font(.title3.bold())
        } else {
            Text(
                "현재 등록된 장소에 있지 않습니다."
            )
            .foregroundStyle(.secondary)
        }
    }
}
