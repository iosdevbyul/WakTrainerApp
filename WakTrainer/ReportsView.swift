import SwiftUI
import WakTrainerFeatureWorkout

struct ReportsView: View {

    var body: some View {
        WorkoutHistoryView()
            .navigationTitle(
                AppL10n.string("reports.title")
            )
            .navigationBarTitleDisplayMode(.inline)
    }
}
