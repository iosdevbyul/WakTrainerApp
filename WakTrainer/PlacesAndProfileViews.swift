import SwiftUI
import TrisPlaceRecognitionKit
import UserProfileFeature

struct PlacesView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
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
                ProgressView(AppL10n.string("places.service.preparing"))
            } else {
                ContentUnavailableView(
                    AppL10n.string("places.service.unavailable_title"),
                    systemImage: "location.slash",
                    description: Text(
                        environment.placeErrorMessage
                            ?? AppL10n.string("common.try_again_later")
                    )
                )
                .task {
                    await environment
                        .preparePlaceServices()
                }
            }
        }
        .navigationTitle(AppL10n.string("common.places"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        List {
            Section(AppL10n.string("profile.body.title")) {
                NavigationLink {
                    BodyProfileView(
                        onProfileUpdated: {
                            environment.refreshProfile()
                        }
                    )
                } label: {
                    Label(
                        AppL10n.string("profile.body.view"),
                        systemImage:
                            "person.text.rectangle"
                    )
                }
            }

            Section(AppL10n.string("profile.info.section")) {
                Text(
                    AppL10n.string("profile.info.description")
                )
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(AppL10n.string("common.profile"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
