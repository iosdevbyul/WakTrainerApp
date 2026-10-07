import Foundation
import SwiftUI
import UserProfileFeature
import WakTrainerCoreModels
import WakTrainerDesignSystem

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
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            if let profile {
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: WakSpacing.large
                    ) {
                        WakSectionHeader(
                            "profile.body.title"
                        )

                        WakCard {
                            VStack(
                                spacing: 0
                            ) {
                                informationRow(
                                    title:
                                        AppL10n.string(
                                            "profile.body.gender"
                                        ),
                                    value:
                                        localizedGender(
                                            profile.gender
                                        )
                                )

                                divider

                                informationRow(
                                    title:
                                        AppL10n.string(
                                            "profile.body.birth_date"
                                        ),
                                    value:
                                        AppL10n.date(
                                            profile.birthDate,
                                            dateStyle: .medium
                                        )
                                )

                                divider

                                informationRow(
                                    title:
                                        AppL10n.string(
                                            "profile.body.age"
                                        ),
                                    value:
                                        AppL10n.format(
                                            "profile.body.age_value",
                                            profile.age
                                        )
                                )

                                divider

                                informationRow(
                                    title:
                                        AppL10n.string(
                                            "profile.body.height"
                                        ),
                                    value:
                                        String(
                                            format: "%.1f cm",
                                            profile.heightCm
                                        )
                                )

                                divider

                                informationRow(
                                    title:
                                        AppL10n.string(
                                            "profile.body.weight"
                                        ),
                                    value:
                                        String(
                                            format: "%.1f kg",
                                            profile.weightKg
                                        )
                                )
                            }
                        }

                        WakSecondaryButton(
                            "profile.body.edit"
                        ) {
                            isShowingProfileSetup =
                                true
                        }
                    }
                    .padding(WakSpacing.regular)
                }
            } else {
                WakCard(
                    padding: WakSpacing.large
                ) {
                    VStack(
                        spacing: WakSpacing.large
                    ) {
                        Image(
                            systemName:
                                "person.crop.circle.badge.questionmark"
                        )
                        .font(
                            .system(size: 42)
                        )
                        .foregroundStyle(
                            WakColor.primary
                        )

                        Text(
                            AppL10n.string(
                                "profile.body.empty"
                            )
                        )
                        .font(
                            WakTypography.sectionTitle
                        )
                        .foregroundStyle(
                            WakColor.textPrimary
                        )

                        Text(
                            AppL10n.string(
                                "profile.body.empty_description"
                            )
                        )
                        .font(WakTypography.body)
                        .foregroundStyle(
                            WakColor.textSecondary
                        )
                        .multilineTextAlignment(
                            .center
                        )

                        WakPrimaryButton(
                            "profile.body.setup"
                        ) {
                            isShowingProfileSetup =
                                true
                        }
                    }
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .padding(WakSpacing.large)
            }
        }
        .navigationTitle(
            AppL10n.string(
                "profile.body.title"
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
    var divider: some View {
        Divider()
            .overlay(WakColor.divider)
    }

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
                .font(WakTypography.body)
                .foregroundStyle(
                    WakColor.textPrimary
                )

            Spacer()

            Text(value)
                .font(WakTypography.body)
                .foregroundStyle(
                    WakColor.textSecondary
                )
        }
        .padding(
            .vertical,
            WakSpacing.medium
        )
    }
}
