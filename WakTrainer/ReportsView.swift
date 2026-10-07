import SwiftUI
import WakTrainerDesignSystem
import WakTrainerFeatureWorkout

struct ReportsView: View {

    var body: some View {
        WorkoutHistoryView()
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
