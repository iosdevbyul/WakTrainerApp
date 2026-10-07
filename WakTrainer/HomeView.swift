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
        .navigationTitle(AppL10n.string("home.title"))
    }

    private var introCard: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text(AppL10n.string("home.workout.title"))
                .font(.title2.bold())

            Text(
                AppL10n.string("home.workout.description")
            )
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private var placeCard: some View {
        PlaceRecognitionCard(
            configuration:
                PlaceRecognitionCardConfiguration(
                    title:
                        AppL10n.string("home.place.title"),
                    registrationPrompt:
                        AppL10n.string("home.place.registration_prompt"),
                    registrationButtonTitle:
                        AppL10n.string("home.place.register_button"),
                    registrationNavigationTitle:
                        AppL10n.string("home.place.registration_title"),
                    enableButtonTitle:
                        AppL10n.string("home.place.enable"),
                    disableButtonTitle:
                        AppL10n.string("home.place.disable"),
                    manageButtonTitle:
                        AppL10n.string("home.place.manage"),
                    registeredPlaceSummaryTitle:
                        AppL10n.string("home.place.registered"),
                    preparingMessage:
                        AppL10n.string("home.place.preparing"),
                    unavailableMessage:
                        AppL10n.string("home.place.unavailable"),
                    unregisteredMessage:
                        AppL10n.string("home.place.unregistered")
                ),
            placeStore:
                environment.placeStore,
            locationProvider:
                environment.locationProvider,
            wifiProvider:
                environment.wifiProvider,
            visitManager:
                environment.visitManager,
            isPreparing:
                environment.isPreparingPlaces,
            isRecognitionRequested:
                environment.isPlaceRecognitionRequested,
            statusMessage:
                environment.placeStatusMessage,
            errorMessage:
                environment.placeErrorMessage,
            onEnableRecognition: {
                await environment
                    .enablePlaceRecognition()
            },
            onDisableRecognition: {
                await environment
                    .disablePlaceRecognition()
            },
            onManagePlaces: {
                onShowPlaces()
            }
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
                    AppL10n.string("home.history.title"),
                    systemImage: "chart.xyaxis.line"
                )
                .font(.headline)

                Spacer()

                Button(AppL10n.string("common.view_all")) {
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
                    AppL10n.string("home.history.empty")
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
            return AppL10n.format("duration.hours_minutes", hours, minutes)
        }

        return AppL10n.format("duration.minutes", minutes)
    }
}
