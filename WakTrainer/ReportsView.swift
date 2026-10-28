import SwiftUI
import UserProfileFeature
import WakTrainerCoreModels
import WakTrainerDesignSystem
import WakTrainerFeatureWorkout

struct ReportsView: View {
    let ownerUserID: UUID?

    private var estimatedMaximumHeartRate: Double? {
        let persisted = DefaultUserProfileManager.shared.loadProfile()
        let cached = DefaultUserProfileManager.shared.profile
        guard let profile = persisted ?? cached else {
#if WAKTRAINER_DEVICE_TEST
            print("[WakTrainer][HeartZone][workout-history] profileMissing persisted=\(persisted != nil) cached=\(cached != nil) maximumHeartRate=nil")
#endif
            return nil
        }
        guard (1...100).contains(profile.age) else {
#if WAKTRAINER_DEVICE_TEST
            print("[WakTrainer][HeartZone][workout-history] invalidAge=\(profile.age) maximumHeartRate=nil")
#endif
            return nil
        }
        let maximumHeartRate = Double(220 - profile.age)
#if WAKTRAINER_DEVICE_TEST
        print("[WakTrainer][HeartZone][workout-history] persisted=\(persisted != nil) cached=\(cached != nil) age=\(profile.age) maximumHeartRate=\(maximumHeartRate)")
#endif
        return maximumHeartRate
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
