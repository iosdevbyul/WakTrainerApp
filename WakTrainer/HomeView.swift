import SwiftUI
import TrisPlaceRecognitionKit
import WakTrainerFeatureWorkout

struct HomeView: View {
    @ObservedObject var environment: AppEnvironment

    @State private var isShowingWorkout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    placeCard
                    workoutCard
                    latestWorkoutCard
                }
                .padding()
            }
            .navigationTitle("오늘")
        }
        .fullScreenCover(
            isPresented: $isShowingWorkout
        ) {
            WorkoutFeatureView { result in
                environment.recordWorkout(result)
                isShowingWorkout = false
            }
        }
    }

    @ViewBuilder
    private var placeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                Text("장소 인식 서비스를 준비하고 있습니다.")
                    .foregroundStyle(.secondary)
            }

            if let message = environment.placeStatusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error = environment.placeErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if environment.isPlaceRecognitionRequested {
                Button("자동 감지 끄기") {
                    Task {
                        await environment.disablePlaceRecognition()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button("헬스장 감지 켜기") {
                    Task {
                        await environment.enablePlaceRecognition()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private var workoutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                "운동",
                systemImage: "figure.run"
            )
            .font(.headline)

            Text(
                "운동을 선택하면 타이머와 HealthKit 수집이 함께 시작됩니다."
            )
            .foregroundStyle(.secondary)

            Button("운동 시작") {
                isShowingWorkout = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    @ViewBuilder
    private var latestWorkoutCard: some View {
        if let latest = environment.workoutHistory.first {
            VStack(alignment: .leading, spacing: 12) {
                Text("최근 운동")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(latest.workoutName)
                            .font(.title3.bold())

                        Text(
                            latest.endedAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(
                        formattedDuration(
                            latest.duration
                        )
                    )
                    .font(.title3.monospacedDigit())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
        }
    }

    private func formattedDuration(
        _ duration: TimeInterval
    ) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        return "\(minutes)분"
    }
}

private struct PlaceRecognitionStatusView: View {
    @ObservedObject var visitManager: PlaceVisitManager

    var body: some View {
        if let place = visitManager.recognizedPlaces.first?.place {
            Label(
                "\(place.name.value)에 있습니다.",
                systemImage: "checkmark.circle.fill"
            )
            .font(.title3.bold())
        } else if !visitManager.activeVisits.isEmpty {
            Label(
                "등록된 장소에 있습니다.",
                systemImage: "checkmark.circle.fill"
            )
            .font(.title3.bold())
        } else {
            Text("현재 등록된 장소에 있지 않습니다.")
                .foregroundStyle(.secondary)
        }
    }
}
