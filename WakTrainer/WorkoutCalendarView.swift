import SwiftUI
import UserProfileFeature
import WakTrainerCoreModels
import TrisCalendarKit
import WakTrainerDesignSystem
import WakTrainerFeatureWorkout

struct WorkoutCalendarView: View {
    @ObservedObject var workoutHistoryStore:
        WorkoutHistoryStore
    let ownerUserID: UUID?

    @State
    private var displayedMonth = Date()

    @State
    private var viewingTimeZone = CalendarTimeZone.system

    @State
    private var selectedDate: Date?

    private var estimatedMaximumHeartRate: Double? {
        guard let profile = DefaultUserProfileManager.shared.loadProfile() ?? DefaultUserProfileManager.shared.profile,
              (1...100).contains(profile.age) else { return nil }
        return Double(220 - profile.age)
    }

    private var highlightedDates: Set<Date> {
        workoutHistoryStore
            .highlightedDates()
    }

    var body: some View {
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: WakSpacing.large
                ) {
                    WakCard {
                        MonthCalendarView(
                            displayedMonth:
                                $displayedMonth,
                            selectedDate:
                                $selectedDate,
                            highlightedDates:
                                highlightedDates,
                            configuration:
                                CalendarConfiguration(
                                    locale:
                                        .custom(
                                            AppL10n.locale
                                        ),
                                    timeZone: viewingTimeZone,
                                    weekStart: .system
                                )
                        )
                        .tint(WakColor.primary)
                    }

                    workoutSection
                }
                .padding(WakSpacing.regular)
            }
        }
        .task {
            await workoutHistoryStore.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)) { _ in
            viewingTimeZone = .system
            selectedDate = nil
            displayedMonth = Date()
        }
        .navigationTitle(
            AppL10n.string(
                "common.calendar"
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
    }

    @ViewBuilder
    private var workoutSection: some View {
        if let selectedDate {
            VStack(
                alignment: .leading,
                spacing: WakSpacing.medium
            ) {
                Text(
                    AppL10n.date(
                        selectedDate,
                        dateStyle: .long
                    )
                )
                .font(WakTypography.sectionTitle)
                .foregroundStyle(
                    WakColor.textPrimary
                )

                WorkoutHistoryView(
                    selectedDate: selectedDate,
                    maximumHeartRate: estimatedMaximumHeartRate,
                    ownerUserID: ownerUserID
                )
                .scrollContentBackground(.hidden)
            }
        } else {
            VStack(alignment: .leading, spacing: WakSpacing.medium) {
                Text("Workout History")
                    .font(WakTypography.sectionTitle)
                    .foregroundStyle(WakColor.textPrimary)
                WorkoutHistoryView(maximumHeartRate: estimatedMaximumHeartRate, ownerUserID: ownerUserID)
                    .scrollContentBackground(.hidden)
            }
        }
    }
}
