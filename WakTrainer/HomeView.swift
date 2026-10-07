import SwiftUI
import TrisPlaceRecognitionKit
import WakTrainerCoreModels
import WakTrainerDesignSystem
import WakTrainerFeatureWorkout

struct HomeView: View {
    @ObservedObject var environment: AppEnvironment
    @ObservedObject var workoutHistoryStore:
        WorkoutHistoryStore

    let onShowReports: () -> Void
    let onShowCalendar: () -> Void
    let onShowPlaces: () -> Void

    var body: some View {
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: WakSpacing.large
                ) {
                    header
                    workoutHero
                    weeklySummarySection
                    calendarPreviewSection
                    recentWorkoutSection
                    placeCard
                }
                .padding(.horizontal, WakSpacing.regular)
                .padding(.top, WakSpacing.small)
                .padding(.bottom, 120)
            }
        }
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

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: WakSpacing.small
        ) {
            Text(
                AppL10n.date(
                    Date(),
                    dateStyle: .full
                )
            )
            .font(WakTypography.caption)
            .foregroundStyle(WakColor.textSecondary)
            .textCase(.uppercase)

            Text(
                AppL10n.string(
                    "home.greeting.title"
                )
            )
            .font(WakTypography.screenTitle)
            .foregroundStyle(WakColor.textPrimary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private var workoutHero: some View {
        WakCard(
            padding: WakSpacing.large
        ) {
            VStack(
                alignment: .leading,
                spacing: WakSpacing.regular
            ) {
                HStack(
                    alignment: .top,
                    spacing: WakSpacing.medium
                ) {
                    ZStack {
                        Circle()
                            .fill(
                                WakColor.primary
                                    .opacity(0.16)
                            )

                        Image(
                            systemName:
                                "figure.strengthtraining.traditional"
                        )
                        .font(
                            .system(
                                size: 24,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            WakColor.primary
                        )
                    }
                    .frame(
                        width: 52,
                        height: 52
                    )

                    VStack(
                        alignment: .leading,
                        spacing: WakSpacing.xSmall
                    ) {
                        Text(
                            AppL10n.string(
                                "home.workout.title"
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
                                "home.workout.description"
                            )
                        )
                        .font(WakTypography.body)
                        .foregroundStyle(
                            WakColor.textSecondary
                        )
                    }
                }

                Divider()
                    .overlay(WakColor.divider)

                Label(
                    AppL10n.string(
                        "home.workout.launcher_hint"
                    ),
                    systemImage:
                        "arrow.down.circle.fill"
                )
                .font(WakTypography.caption)
                .foregroundStyle(WakColor.primary)
            }
        }
    }

    private var weeklySummarySection: some View {
        VStack(
            alignment: .leading,
            spacing: WakSpacing.medium
        ) {
            WakSectionHeader("home.week.title")

            WakCard {
                HStack(
                    alignment: .top,
                    spacing: WakSpacing.small
                ) {
                    WakMetricView(
                        value:
                            "\(currentWeekSessions.count)",
                        label:
                            LocalizedStringKey(
                                "home.summary.workouts"
                            )
                    )

                    WakMetricView(
                        value:
                            compactDuration(
                                currentWeekDuration
                            ),
                        label:
                            LocalizedStringKey(
                                "home.summary.time"
                            )
                    )

                    WakMetricView(
                        value:
                            "\(currentWeekCalories)",
                        label:
                            LocalizedStringKey(
                                "home.summary.calories"
                            ),
                        unit: "kcal"
                    )
                }
            }
        }
    }

    private var calendarPreviewSection: some View {
        VStack(
            alignment: .leading,
            spacing: WakSpacing.medium
        ) {
            sectionHeader(
                titleKey:
                    "home.calendar_preview.title",
                action: onShowCalendar
            )

            WakCard {
                HStack(spacing: WakSpacing.small) {
                    ForEach(
                        currentWeekDates,
                        id: \.self
                    ) { date in
                        Button {
                            onShowCalendar()
                        } label: {
                            VStack(
                                spacing: WakSpacing.small
                            ) {
                                Text(
                                    weekdaySymbol(
                                        for: date
                                    )
                                )
                                .font(WakTypography.caption)
                                .foregroundStyle(
                                    WakColor.textSecondary
                                )

                                Text(
                                    date.formatted(
                                        .dateTime.day()
                                    )
                                )
                                .font(
                                    .system(
                                        size: 16,
                                        weight:
                                            Calendar
                                                .autoupdatingCurrent
                                                .isDateInToday(
                                                    date
                                                )
                                                ? .bold
                                                : .medium,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(
                                    Calendar
                                        .autoupdatingCurrent
                                        .isDateInToday(
                                            date
                                        )
                                        ? Color.black
                                        : WakColor.textPrimary
                                )
                                .frame(
                                    width: 34,
                                    height: 34
                                )
                                .background(
                                    Calendar
                                        .autoupdatingCurrent
                                        .isDateInToday(
                                            date
                                        )
                                        ? WakColor.primary
                                        : Color.clear
                                )
                                .clipShape(Circle())

                                Circle()
                                    .fill(
                                        hasWorkout(
                                            on: date
                                        )
                                        ? WakColor.primary
                                        : Color.clear
                                    )
                                    .frame(
                                        width: 5,
                                        height: 5
                                    )
                            }
                            .frame(
                                maxWidth: .infinity
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentWorkoutSection: some View {
        VStack(
            alignment: .leading,
            spacing: WakSpacing.medium
        ) {
            sectionHeader(
                titleKey: "home.recent.title",
                action: onShowReports
            )

            if let latest =
                workoutHistoryStore.latestSession
            {
                Button {
                    onShowReports()
                } label: {
                    WakCard {
                        HStack(
                            spacing: WakSpacing.medium
                        ) {
                            ZStack {
                                Circle()
                                    .fill(
                                        WakColor.primary
                                            .opacity(0.14)
                                    )

                                Image(
                                    systemName:
                                        "figure.strengthtraining.traditional"
                                )
                                .font(
                                    .system(
                                        size: 20,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    WakColor.primary
                                )
                            }
                            .frame(
                                width: 46,
                                height: 46
                            )

                            VStack(
                                alignment: .leading,
                                spacing:
                                    WakSpacing.xSmall
                            ) {
                                Text(
                                    verbatim:
                                        latest.workout.name
                                )
                                .font(
                                    WakTypography
                                        .sectionTitle
                                )
                                .foregroundStyle(
                                    WakColor.textPrimary
                                )

                                Text(
                                    "\(AppL10n.date(latest.timing.endDate ?? latest.timing.startDate, dateStyle: .medium)) · \(formattedDuration(latest.timing.activeDuration))"
                                )
                                .font(
                                    WakTypography.caption
                                )
                                .foregroundStyle(
                                    WakColor.textSecondary
                                )
                            }

                            Spacer()

                            Image(
                                systemName:
                                    "chevron.right"
                            )
                            .font(
                                .system(
                                    size: 13,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                WakColor.textSecondary
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                WakCard {
                    Text(
                        AppL10n.string(
                            "home.history.empty"
                        )
                    )
                    .font(WakTypography.body)
                    .foregroundStyle(
                        WakColor.textSecondary
                    )
                }
            }
        }
    }

    private var placeCard: some View {
        PlaceRecognitionCard(
            configuration:
                PlaceRecognitionCardConfiguration(
                    title:
                        AppL10n.string("home.place.title"),
                    registrationPrompt:
                        AppL10n.string("home.place.registration_prompt"),
                    registrationButtonTitle:
                        AppL10n.string("home.place.register_button"),
                    registrationNavigationTitle:
                        AppL10n.string("home.place.registration_title"),
                    enableButtonTitle:
                        AppL10n.string("home.place.enable"),
                    disableButtonTitle:
                        AppL10n.string("home.place.disable"),
                    manageButtonTitle:
                        AppL10n.string("home.place.manage"),
                    registeredPlaceSummaryTitle:
                        AppL10n.string("home.place.registered"),
                    preparingMessage:
                        AppL10n.string("home.place.preparing"),
                    unavailableMessage:
                        AppL10n.string("home.place.unavailable"),
                    unregisteredMessage:
                        AppL10n.string("home.place.unregistered")
                ),
            placeStore:
                environment.placeStore,
            locationProvider:
                environment.locationProvider,
            wifiProvider:
                environment.wifiProvider,
            visitManager:
                environment.visitManager,
            isPreparing:
                environment.isPreparingPlaces,
            isRecognitionRequested:
                environment.isPlaceRecognitionRequested,
            statusMessage:
                environment.placeStatusMessage,
            errorMessage:
                environment.placeErrorMessage,
            onEnableRecognition: {
                await environment
                    .enablePlaceRecognition()
            },
            onDisableRecognition: {
                await environment
                    .disablePlaceRecognition()
            },
            onManagePlaces: {
                onShowPlaces()
            }
        )
        .tint(WakColor.primary)
    }

    private func sectionHeader(
        titleKey: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(AppL10n.string(titleKey))
                .font(WakTypography.sectionTitle)
                .foregroundStyle(
                    WakColor.textPrimary
                )

            Spacer()

            Button(
                AppL10n.string(
                    "common.view_all"
                ),
                action: action
            )
            .font(WakTypography.caption)
            .foregroundStyle(WakColor.primary)
        }
    }

    private var currentWeekSessions:
        [WorkoutSession]
    {
        let calendar =
            Calendar.autoupdatingCurrent

        guard
            let interval =
                calendar.dateInterval(
                    of: .weekOfYear,
                    for: Date()
                )
        else {
            return []
        }

        return workoutHistoryStore
            .sessions
            .map(\.session)
            .filter {
                interval.contains(
                    $0.timing.startDate
                )
            }
    }

    private var currentWeekDuration:
        TimeInterval
    {
        currentWeekSessions.reduce(0) {
            $0 + $1.timing.activeDuration
        }
    }

    private var currentWeekCalories: Int {
        Int(
            currentWeekSessions
                .compactMap {
                    $0.health.summary
                        .activeCalories
                }
                .reduce(0, +)
                .rounded()
        )
    }

    private var currentWeekDates: [Date] {
        let calendar =
            Calendar.autoupdatingCurrent

        guard
            let interval =
                calendar.dateInterval(
                    of: .weekOfYear,
                    for: Date()
                )
        else {
            return []
        }

        return (0..<7).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: interval.start
            )
        }
    }

    private func hasWorkout(
        on date: Date
    ) -> Bool {
        let calendar =
            Calendar.autoupdatingCurrent

        return workoutHistoryStore
            .highlightedDates(
                calendar: calendar
            )
            .contains(
                calendar.startOfDay(
                    for: date
                )
            )
    }

    private func weekdaySymbol(
        for date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppL10n.locale
        formatter.setLocalizedDateFormatFromTemplate(
            "EEE"
        )

        return formatter
            .string(from: date)
            .uppercased(
                with: AppL10n.locale
            )
    }

    private func compactDuration(
        _ duration: TimeInterval
    ) -> String {
        let totalMinutes =
            max(0, Int(duration) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return AppL10n.format(
                "duration.compact_hours_minutes",
                hours,
                minutes
            )
        }

        return AppL10n.format(
            "duration.compact_minutes",
            minutes
        )
    }

    private func formattedDuration(
        _ duration: TimeInterval
    ) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes =
            (totalSeconds % 3600) / 60

        if hours > 0 {
            return AppL10n.format(
                "duration.hours_minutes",
                hours,
                minutes
            )
        }

        return AppL10n.format(
            "duration.minutes",
            minutes
        )
    }
}
