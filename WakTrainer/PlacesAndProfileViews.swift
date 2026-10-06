import SwiftUI
import TrisPlaceRecognitionKit
import UserProfileFeature

struct PlacesTabView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Group {
            if
                let store = environment.placeStore,
                let visitManager = environment.visitManager
            {
                PlaceManagementView(
                    placeStore: store,
                    locationProvider: environment.locationProvider,
                    wifiProvider: environment.wifiProvider,
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
                    await environment.preparePlaceServices()
                }
            }
        }
    }
}

struct ProfileTabView: View {
    @ObservedObject var environment: AppEnvironment

    @State private var isShowingProfileSetup = false

    var body: some View {
        NavigationStack {
            List {
                Section("개인화") {
                    Label(
                        "성별, 생년월일, 키와 몸무게를 운동 리포트 계산에 사용합니다.",
                        systemImage: "person.text.rectangle"
                    )
                }

                Section {
                    Button("신체 정보 수정") {
                        isShowingProfileSetup = true
                    }
                }
            }
            .navigationTitle("프로필")
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
}
