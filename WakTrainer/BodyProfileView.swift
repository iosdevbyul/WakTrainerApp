import Foundation
import SwiftUI
import UserProfileFeature
import WakTrainerCoreModels

struct BodyProfileView: View {
    @State
    private var profile: UserProfile?

    @State
    private var isShowingProfileSetup = false

    private let profileManager:
        DefaultUserProfileManager

    private let onProfileUpdated:
        @MainActor () -> Void

    init(
        profileManager:
            DefaultUserProfileManager = .shared,
        onProfileUpdated:
            @escaping @MainActor () -> Void = {}
    ) {
        self.profileManager =
            profileManager

        self.onProfileUpdated =
            onProfileUpdated
    }

    var body: some View {
        Group {
            if let profile {
                List {
                    Section("신체 정보") {
                        informationRow(
                            title: "성별",
                            value: profile.gender.rawValue
                        )

                        informationRow(
                            title: "생년월일",
                            value:
                                profile.birthDate.formatted(
                                    date: .numeric,
                                    time: .omitted
                                )
                        )

                        informationRow(
                            title: "나이",
                            value: "\(profile.age)세"
                        )

                        informationRow(
                            title: "키",
                            value:
                                String(
                                    format:
                                        "%.1f cm",
                                    profile.heightCm
                                )
                        )

                        informationRow(
                            title: "몸무게",
                            value:
                                String(
                                    format:
                                        "%.1f kg",
                                    profile.weightKg
                                )
                        )
                    }

                    Section {
                        Button("신체 정보 수정") {
                            isShowingProfileSetup =
                                true
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label(
                        "신체 정보가 없습니다",
                        systemImage:
                            "person.crop.circle.badge.questionmark"
                    )
                } description: {
                    Text(
                        "운동 리포트를 위해 신체 정보를 설정해 주세요."
                    )
                } actions: {
                    Button("신체 정보 설정") {
                        isShowingProfileSetup =
                            true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("신체 정보")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reloadProfile()
        }
        .sheet(
            isPresented:
                $isShowingProfileSetup,
            onDismiss: {
                reloadProfile()
                onProfileUpdated()
            }
        ) {
            ProfileSetupView()
        }
    }
}

private extension BodyProfileView {
    func reloadProfile() {
        profile =
            profileManager.loadProfile()
    }

    func informationRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
