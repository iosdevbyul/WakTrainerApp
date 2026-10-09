import SwiftUI
import UserProfileFeature
import WakTrainerDesignSystem
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
        .preferredColorScheme(.dark)
        .tint(WakColor.primary)
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
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            WakCard(
                padding: WakSpacing.large
            ) {
                VStack(
                    spacing: WakSpacing.large
                ) {
                    ZStack {
                        Circle()
                            .fill(
                                WakColor.primary
                                    .opacity(0.16)
                            )

                        Image(
                            systemName:
                                "figure.strengthtraining.traditional"
                        )
                        .font(
                            .system(
                                size: 36,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            WakColor.primary
                        )
                    }
                    .frame(
                        width: 80,
                        height: 80
                    )

                    Text("WakTrainer")
                        .font(WakTypography.screenTitle)
                        .foregroundStyle(
                            WakColor.textPrimary
                        )

                    Text(
                        AppL10n.string(
                            "profile.required.description"
                        )
                    )
                    .font(WakTypography.body)
                    .foregroundStyle(
                        WakColor.textSecondary
                    )
                    .multilineTextAlignment(.center)

                    WakPrimaryButton(
                        "profile.body.setup"
                    ) {
                        isShowingProfileSetup = true
                    }
                }
            }
            .padding(WakSpacing.large)
        }
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
                onShowCalendar: {
                    path.append(.calendar)
                },
                onShowPlaces: {
                    path.append(.places)
                }
            )
            .toolbar {
                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {
                    toolbarButton(
                        systemImage: "calendar",
                        accessibilityKey:
                            "common.calendar"
                    ) {
                        path.append(.calendar)
                    }

                    toolbarButton(
                        systemImage:
                            "person.crop.circle",
                        accessibilityKey:
                            "common.profile"
                    ) {
                        path.append(.profile)
                    }
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
        .background(WakColor.background)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 92)
        }
        .wakTrainerWorkoutLauncher(
            bottomPadding: 16,
            onFinished: { _ in
                WorkoutLiveActivityController.shared.finish()
                Task {
                    await environment.refreshWorkoutHistory()
                }
            },
            onWorkoutUpdate: { snapshot in
                WorkoutLiveActivityController.shared.receive(snapshot)
            }
        )
    }

    private func toolbarButton(
        systemImage: String,
        accessibilityKey: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    WakColor.textPrimary
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(WakColor.surface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            AppL10n.string(
                accessibilityKey
            )
        )
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
