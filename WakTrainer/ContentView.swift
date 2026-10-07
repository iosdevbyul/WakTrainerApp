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
                AppL10n.string("profile.required.description")
            )
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button(AppL10n.string("profile.body.setup")) {
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
                workoutHistoryStore:
                    environment.workoutHistoryStore,
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
                    .accessibilityLabel(AppL10n.string("common.calendar"))

                    Button {
                        path.append(.profile)
                    } label: {
                        Image(
                            systemName:
                                "person.crop.circle"
                        )
                        .font(.title2)
                    }
                    .accessibilityLabel(AppL10n.string("common.profile"))
                }
            }
            .navigationDestination(
                for: MainRoute.self
            ) { route in
                switch route {
                case .reports:
                    ReportsView()

                case .calendar:
                    WorkoutCalendarView(
                        workoutHistoryStore:
                            environment.workoutHistoryStore
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
        ) { _ in
            Task {
                await environment
                    .refreshWorkoutHistory()
            }
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
