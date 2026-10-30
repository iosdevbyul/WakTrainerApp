import ActivityKit
import SwiftUI
import WidgetKit
import WakTrainerLiveActivityModels

// Matches WakTrainerDesignSystem's semantic dark palette without pulling
// the full UI package into the widget extension.
private enum WorkoutActivityPalette {
    static let background = Color(red: 11 / 255, green: 14 / 255, blue: 17 / 255)
    static let surface = Color(red: 23 / 255, green: 27 / 255, blue: 32 / 255)
    static let primary = Color(red: 140 / 255, green: 246 / 255, blue: 108 / 255)
    static let text = Color(red: 247 / 255, green: 248 / 255, blue: 249 / 255)
    static let secondary = Color(red: 154 / 255, green: 163 / 255, blue: 173 / 255)
}

struct WorkoutLiveActivityWidget: Widget {
    private var workoutURL: URL? {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let scheme = bundleID.contains("DeviceTest") ? "waktrainer-device-test"
            : (bundleID.contains("Demo") ? "waktrainer-demo" : "waktrainer")
        return URL(string: "\(scheme)://workout/resume")
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    elapsed(context.state)
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Spacer(minLength: 0)

                    Text("WakTrainer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WorkoutActivityPalette.text)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(2)
                    brandLogo(size: 33)
                }

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(WorkoutActivityPalette.primary)
                    Text(context.state.heartRate > 0 ? "\(context.state.heartRate)" : "--")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WorkoutActivityPalette.primary)
                        .lineLimit(1)
                    Text("bpm")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer(minLength: 0)
                    Text(context.state.heartRateZone.map { "Zone \($0)" } ?? "Zone --")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(WorkoutActivityPalette.primary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(context.state.exercise ?? context.attributes.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WorkoutActivityPalette.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                    Spacer(minLength: 0)
                    Text("\(context.state.calories) Active")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                    if let totalCalories = context.state.totalCalories {
                        Text("\(totalCalories) Total")
                            .font(.system(size: 14, weight: .medium))
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(WorkoutActivityPalette.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .foregroundStyle(WorkoutActivityPalette.text)
            .environment(\.colorScheme, .dark)
            .widgetURL(workoutURL)
            .activityBackgroundTint(WorkoutActivityPalette.background)
            .activitySystemActionForegroundColor(WorkoutActivityPalette.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.name)
                    } icon: {
                        brandLogo(size: 20)
                    }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WorkoutActivityPalette.primary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    elapsed(context.state)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WorkoutActivityPalette.text)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 14) {
                        prominentMetric("HEART RATE", value: context.state.heartRate > 0 ? "\(context.state.heartRate)" : "--", unit: "bpm", symbol: "heart.fill")
                        if context.attributes.kind == .strength {
                            prominentMetric("SETS DONE", value: "\(context.state.completedSets)", unit: "sets", symbol: "checkmark.circle.fill")
                        } else {
                            prominentMetric("DISTANCE", value: String(format: "%.2f", context.state.distanceMeters / 1000), unit: "km", symbol: "location.fill")
                        }
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                brandLogo(size: 20)
            } compactTrailing: {
                compactElapsed(context.state)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 48, alignment: .trailing)
                    .foregroundStyle(WorkoutActivityPalette.text)
            } minimal: {
                brandLogo(size: 20)
            }
        }
    }

    // Bundle.main is the widget extension, not the containing app. Keep the
    // source asset at 24 pt (1x/2x/3x); a frame alone does not downsample the
    // image archived by ActivityKit. Preserve the existing brand colors on
    // both the fixed dark Lock Screen surface and the black Dynamic Island.
    private func brandLogo(size: CGFloat) -> some View {
        Image("WakTrainerAppLogo", bundle: .main)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("WakTrainer")
    }

    @ViewBuilder
    private func elapsed(_ state: WorkoutActivityAttributes.ContentState) -> some View {
        if let runningSince = state.runningSince, state.phase == .running {
            // Timer text must always be numeric and include seconds.
            // Avoid Date's adaptive timer/relative-unit presentation.
            Text(
                timerInterval: runningSince...Date.distantFuture,
                countsDown: false,
                showsHours: true
            )
        } else {
            Text(
                Duration.seconds(max(0, state.elapsedSeconds))
                    .formatted(.time(pattern: .hourMinuteSecond))
            )
        }
    }

    @ViewBuilder
    private func compactElapsed(_ state: WorkoutActivityAttributes.ContentState) -> some View {
        if let runningSince = state.runningSince, state.phase == .running {
            Text(
                timerInterval: runningSince...Date.distantFuture,
                countsDown: false,
                showsHours: false
            )
        } else {
            Text(
                Duration.seconds(max(0, state.elapsedSeconds))
                    .formatted(.time(pattern: .minuteSecond))
            )
        }
    }

    private func compactMetric(_ title: String, value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WorkoutActivityPalette.secondary)
            Spacer(minLength: 1)
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(WorkoutActivityPalette.primary)
                .minimumScaleFactor(0.6)
            Text(unit)
                .font(.system(size: 10, weight: .medium))
        }
        .lineLimit(1)
    }

    private func largeMetric(_ title: String, value: String, unit: String, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11 * scale, weight: .bold))
                .foregroundStyle(WorkoutActivityPalette.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 54 * scale, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WorkoutActivityPalette.primary)
                    .minimumScaleFactor(0.65)
                Text(unit)
                    .font(.system(size: 12 * scale, weight: .bold))
                    .foregroundStyle(WorkoutActivityPalette.text)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prominentMetric(_ title: String, value: String, unit: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(WorkoutActivityPalette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WorkoutActivityPalette.primary)
                    .minimumScaleFactor(0.7)
                Text(unit)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WorkoutActivityPalette.text)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func secondaryMetric(_ symbol: String, _ value: String) -> some View {
        Label(value, systemImage: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WorkoutActivityPalette.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }
}

@main
struct WakTrainerWorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}
