import SwiftUI
import TrisPlaceRecognitionKit
import UserProfileFeature
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
