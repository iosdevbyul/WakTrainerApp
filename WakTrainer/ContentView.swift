import SwiftUI
import UserProfileFeature
import WakTrainerFeatureWorkout

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var environment: AppEnvironment

    @State private var isShowingProfileSetup = false

    var body: some View {
        Group {
            if environment.isProfileConfigured {
                MainOrbNavigationView(
                    environment: environment
                )
            } else {
                profileRequiredView
            }
        }
        .task {
            await environment.handleSceneBecameActive()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await environment.handleSceneBecameActive()
            }
        }
        .sheet(
            isPresented: $isShowingProfileSetup,
            onDismiss: {
                environment.refreshProfile()
            }
        ) {
            ProfileSetupView()
        }
    }

    private var profileRequiredView: some View {
        VStack(spacing: 20) {
            Image(
                systemName:
                    "figure.strengthtraining.traditional"
            )
            .font(.system(size: 54))

            Text("WakTrainer")
                .font(.largeTitle.bold())

            Text(
                "운동 리포트를 개인화하기 위해 성별, 생년월일, 키와 몸무게를 먼저 설정합니다."
            )
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button("신체 정보 설정") {
                isShowingProfileSetup = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}

private struct MainOrbNavigationView: View {
    @ObservedObject var environment: AppEnvironment

    @State
    private var path: [MainRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                environment: environment,
                onShowReports: {
                    path.append(.reports)
                },
                onShowPlaces: {
                    path.append(.places)
                }
            )
            .toolbar {
                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {
                    Button {
                        path.append(.calendar)
                    } label: {
                        Image(
                            systemName: "calendar"
                        )
                        .font(.title2)
                    }
                    .accessibilityLabel("캘린더")

                    Button {
                        path.append(.profile)
                    } label: {
                        Image(
                            systemName:
                                "person.crop.circle"
                        )
                        .font(.title2)
                    }
                    .accessibilityLabel("프로필")
                }
            }
            .navigationDestination(
                for: MainRoute.self
            ) { route in
                switch route {
                case .reports:
                    ReportsView(
                        environment: environment
                    )

                case .calendar:
                    WorkoutCalendarView(
                        environment: environment
                    )

                case .places:
                    PlacesView(
                        environment: environment
                    )

                case .profile:
                    ProfileView(
                        environment: environment
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 92)
        }
        .wakTrainerWorkoutLauncher(
            bottomPadding: 16
        ) { session in
            environment.recordWorkout(session)
        }
    }
}

private enum MainRoute: Hashable {
    case reports
    case calendar
    case places
    case profile
}

#Preview {
    ContentView(
        environment: AppEnvironment()
    )
}
