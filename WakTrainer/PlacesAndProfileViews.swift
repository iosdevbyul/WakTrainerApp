import SwiftUI
import TrisPlaceRecognitionKit
import UserProfileFeature
import WakTrainerServiceHealthKit
import WakTrainerDesignSystem

struct PlacesView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            Group {
                if
                    let store = environment.placeStore,
                    let visitManager =
                        environment.visitManager
                {
                    PlaceManagementView(
                        placeStore: store,
                        locationProvider:
                            environment.locationProvider,
                        wifiProvider:
                            environment.wifiProvider,
                        visitManager: visitManager
                    )
                } else if environment.isPreparingPlaces {
                    ProgressView(
                        AppL10n.string(
                            "places.service.preparing"
                        )
                    )
                    .tint(WakColor.primary)
                } else {
                    ContentUnavailableView(
                        AppL10n.string(
                            "places.service.unavailable_title"
                        ),
                        systemImage: "location.slash",
                        description: Text(
                            environment.placeErrorMessage
                                ?? AppL10n.string(
                                    "common.try_again_later"
                                )
                        )
                    )
                }
            }
        }
        .tint(WakColor.primary)
        .navigationTitle(
            AppL10n.string(
                "common.places"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            WakColor.background,
            for: .navigationBar
        )
        .toolbarBackground(
            .visible,
            for: .navigationBar
        )
        .toolbarColorScheme(
            .dark,
            for: .navigationBar
        )
        .task {
            guard
                environment.placeStore == nil,
                !environment.isPreparingPlaces
            else {
                return
            }

            await environment
                .preparePlaceServices()
        }
    }
}

struct ProfileView: View {
    @ObservedObject var environment: AppEnvironment
    @State private var developerTapCount = 0
    @State private var showDeveloperSettings = false
    @State private var showServerResumeConfirmation = false
    @State private var showFitnessHistoryDeletionConfirmation = false
    @State private var deletingFitnessHistory = false
    @State private var fitnessHistoryDeletionResult: String?

    var body: some View {
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: WakSpacing.large
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: WakSpacing.medium
                    ) {
                        WakSectionHeader(
                            "profile.body.title"
                        )

                        WakCard {
                            NavigationLink {
                                BodyProfileView(
                                    onProfileUpdated: {
                                        environment
                                            .refreshProfile()
                                    }
                                )
                            } label: {
                                HStack(
                                    spacing:
                                        WakSpacing.medium
                                ) {
                                    Image(
                                        systemName:
                                            "person.text.rectangle"
                                    )
                                    .font(
                                        .system(
                                            size: 20,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(
                                        WakColor.primary
                                    )

                                    Text(
                                        AppL10n.string(
                                            "profile.body.view"
                                        )
                                    )
                                    .font(
                                        WakTypography.body
                                    )
                                    .foregroundStyle(
                                        WakColor.textPrimary
                                    )

                                    Spacer()

                                    Image(
                                        systemName:
                                            "chevron.right"
                                    )
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(
                                        WakColor.textSecondary
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    WakCard {
                        HStack(spacing: WakSpacing.medium) {
                            Image(systemName: environment.workoutDataMode == .localOnly ? "iphone" : "arrow.triangle.2.circlepath")
                                .foregroundStyle(WakColor.primary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Workout Data Mode")
                                    .font(WakTypography.body)
                                    .foregroundStyle(WakColor.textPrimary)
                                Text(environment.workoutDataMode == .localOnly ? "Local Only · Uploads paused" : "Server · Uploads enabled")
                                    .font(.caption)
                                    .foregroundStyle(WakColor.textSecondary)
                            }
                            Spacer()
                            if environment.workoutDataMode == .localOnly {
                                Button("Resume Sync") {
                                    showServerResumeConfirmation = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .confirmationDialog(
                        "Resume Server Mode?",
                        isPresented: $showServerResumeConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Resume Server Sync") {
                            environment.setWorkoutDataMode(.server)
                        }
                    } message: {
                        Text("Pending workouts will be eligible for upload when the server is reachable. Local workout records remain on this device.")
                    }

                    WakCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Save workouts to Apple Fitness", isOn: Binding(
                                get: { environment.saveWorkoutsToAppleHealth },
                                set: { environment.setSaveWorkoutsToAppleHealth($0) }
                            ))
                            .tint(WakColor.primary)

                            Text("Your workouts are always saved in WakTrainer. Turn this off to stop saving new workout sessions to Apple Health and Fitness; heart-rate collection stays available.")
                                .font(.footnote)
                                .foregroundStyle(WakColor.textSecondary)

                            Button("Delete workouts WakTrainer saved to Apple Health", role: .destructive) {
                                showFitnessHistoryDeletionConfirmation = true
                            }
                            .disabled(deletingFitnessHistory)
                        }
                    }
                    .confirmationDialog(
                        "Delete WakTrainer workouts from Apple Health?",
                        isPresented: $showFitnessHistoryDeletionConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete Apple Health workout records", role: .destructive) {
                            deletingFitnessHistory = true
                            Task {
                                do {
                                    let count = try await WakTrainerWorkoutHealthHistory().deleteSavedWorkouts()
                                    fitnessHistoryDeletionResult = "Deleted \(count) WakTrainer workout record(s) from Apple Health."
                                } catch {
                                    fitnessHistoryDeletionResult = "Could not delete workout records: \(error.localizedDescription)"
                                }
                                deletingFitnessHistory = false
                            }
                        }
                    } message: {
                        Text("Only workouts created by WakTrainer will be deleted from Apple Health and Fitness. This cannot be undone. Local WakTrainer workout history will not be removed.")
                    }
                    .alert("Apple Health Workout Records", isPresented: Binding(
                        get: { fitnessHistoryDeletionResult != nil },
                        set: { if !$0 { fitnessHistoryDeletionResult = nil } }
                    )) {
                        Button("OK") { fitnessHistoryDeletionResult = nil }
                    } message: {
                        Text(fitnessHistoryDeletionResult ?? "")
                    }

                    Button {
                        developerTapCount += 1
                        if developerTapCount >= 5 {
                            developerTapCount = 0
                            showDeveloperSettings = true
                        }
                    } label: {
                        Text("WakTrainer")
                            .font(.caption)
                            .foregroundStyle(WakColor.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("App information")
                    .sheet(isPresented: $showDeveloperSettings) {
                        NavigationStack {
                            Form {
                                Section("Workout Data Mode") {
                                    Picker("Mode", selection: Binding(
                                        get: { environment.workoutDataMode },
                                        set: { environment.setWorkoutDataMode($0) }
                                    )) {
                                        Text("Server").tag(WorkoutDataMode.server)
                                        Text("Local Only").tag(WorkoutDataMode.localOnly)
                                    }
                                    .pickerStyle(.segmented)
                                    Text("Local Only keeps workouts on this device and pauses workout uploads. Switching back to Server resumes pending workout uploads.")
                                        .font(.footnote)
                                }
                            }
                            .navigationTitle("Developer Settings")
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { showDeveloperSettings = false }
                                }
                            }
                        }
                    }

                    VStack(
                        alignment: .leading,
                        spacing: WakSpacing.medium
                    ) {
                        WakSectionHeader(
                            "profile.info.section"
                        )

                        WakCard {
                            Text(
                                AppL10n.string(
                                    "profile.info.description"
                                )
                            )
                            .font(WakTypography.body)
                            .foregroundStyle(
                                WakColor.textSecondary
                            )
                        }
                    }
                }
                .padding(WakSpacing.regular)
            }
        }
        .navigationTitle(
            AppL10n.string(
                "common.profile"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            WakColor.background,
            for: .navigationBar
        )
        .toolbarBackground(
            .visible,
            for: .navigationBar
        )
        .toolbarColorScheme(
            .dark,
            for: .navigationBar
        )
    }
}
