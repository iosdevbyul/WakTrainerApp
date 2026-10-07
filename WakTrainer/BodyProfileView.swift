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
                    Section(AppL10n.string("profile.body.title")) {
                        informationRow(
                            title: AppL10n.string("profile.body.gender"),
                            value: localizedGender(profile.gender)
                        )

                        informationRow(
                            title: AppL10n.string("profile.body.birth_date"),
                            value:
                                AppL10n.date(
                                    profile.birthDate,
                                    dateStyle: .medium
                                )
                        )

                        informationRow(
                            title: AppL10n.string("profile.body.age"),
                            value: AppL10n.format("profile.body.age_value", profile.age)
                        )

                        informationRow(
                            title: AppL10n.string("profile.body.height"),
                            value:
                                String(
                                    format:
                                        "%.1f cm",
                                    profile.heightCm
                                )
                        )

                        informationRow(
                            title: AppL10n.string("profile.body.weight"),
                            value:
                                String(
                                    format:
                                        "%.1f kg",
                                    profile.weightKg
                                )
                        )
                    }

                    Section {
                        Button(AppL10n.string("profile.body.edit")) {
                            isShowingProfileSetup =
                                true
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label(
                        AppL10n.string("profile.body.empty"),
                        systemImage:
                            "person.crop.circle.badge.questionmark"
                    )
                } description: {
                    Text(
                        AppL10n.string("profile.body.empty_description")
                    )
                } actions: {
                    Button(AppL10n.string("profile.body.setup")) {
                        isShowingProfileSetup =
                            true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(AppL10n.string("profile.body.title"))
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
    func localizedGender(
        _ gender: UserProfile.Gender
    ) -> String {
        switch gender {
        case .male:
            return AppL10n.string(
                "profile.gender.male"
            )

        case .female:
            return AppL10n.string(
                "profile.gender.female"
            )

        case .other:
            return AppL10n.string(
                "profile.gender.other"
            )
        }
    }

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
