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
                ProgressView("장소 서비스 준비 중")
            } else {
                ContentUnavailableView(
                    "장소 서비스를 준비하지 못했습니다",
                    systemImage: "location.slash",
                    description: Text(
                        environment.placeErrorMessage
                            ?? "잠시 후 다시 시도해 주세요."
                    )
                )
                .task {
                    await environment
                        .preparePlaceServices()
                }
            }
        }
        .navigationTitle("장소")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        List {
            Section("신체 정보") {
                NavigationLink {
                    BodyProfileView(
                        onProfileUpdated: {
                            environment.refreshProfile()
                        }
                    )
                } label: {
                    Label(
                        "신체 정보 보기",
                        systemImage:
                            "person.text.rectangle"
                    )
                }
            }

            Section("안내") {
                Text(
                    "성별, 생년월일, 키와 몸무게를 운동 리포트 계산에 사용합니다."
                )
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
    }
}
