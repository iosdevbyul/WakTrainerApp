import SwiftUI
import UserProfileFeature

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var environment: AppEnvironment

    @State private var isShowingProfileSetup = false

    var body: some View {
        Group {
            if environment.isProfileConfigured {
                MainTabView(
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
            Image(systemName: "figure.strengthtraining.traditional")
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

private struct MainTabView: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        TabView {
            HomeView(
                environment: environment
            )
            .tabItem {
                Label(
                    "홈",
                    systemImage: "house.fill"
                )
            }

            ReportsView(
                environment: environment
            )
            .tabItem {
                Label(
                    "리포트",
                    systemImage: "chart.xyaxis.line"
                )
            }

            PlacesTabView(
                environment: environment
            )
            .tabItem {
                Label(
                    "장소",
                    systemImage: "mappin.and.ellipse"
                )
            }

            ProfileTabView(
                environment: environment
            )
            .tabItem {
                Label(
                    "프로필",
                    systemImage: "person.crop.circle"
                )
            }
        }
    }
}

#Preview {
    ContentView(
        environment: AppEnvironment()
    )
}
