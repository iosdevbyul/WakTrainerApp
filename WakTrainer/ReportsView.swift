import SwiftUI
import UserProfileFeature
import WakTrainerCoreModels
import WakTrainerDesignSystem
import WakTrainerFeatureWorkout

struct ReportsView: View {
    let ownerUserID: UUID?

    private var estimatedMaximumHeartRate: Double? {
        guard let profile = DefaultUserProfileManager.shared.profile,
              (1...100).contains(profile.age) else { return nil }
        return Double(220 - profile.age)
    }

    var body: some View {
        WorkoutHistoryView(maximumHeartRate: estimatedMaximumHeartRate, ownerUserID: ownerUserID)
            .scrollContentBackground(.hidden)
            .background(
                WakColor.background
                    .ignoresSafeArea()
            )
            .tint(WakColor.primary)
            .navigationTitle(
                AppL10n.string(
                    "reports.title"
                )
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
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
