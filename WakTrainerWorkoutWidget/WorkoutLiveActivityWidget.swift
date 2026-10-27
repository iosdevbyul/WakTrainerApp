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
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            GeometryReader { proxy in
                let scale = min(1.0, max(0.55, proxy.size.height / 205.0))
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.kind == .strength ? "dumbbell.fill" : "figure.run")
                            .foregroundStyle(WorkoutActivityPalette.primary)
                        Text(context.attributes.name)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(context.state.phase == .paused ? "PAUSED" : "LIVE")
                            .foregroundStyle(WorkoutActivityPalette.primary)
                    }
                    .font(.system(size: 12 * scale, weight: .bold))

                    elapsed(context.state)
                        .font(.system(size: 86 * scale, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WorkoutActivityPalette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .firstTextBaseline, spacing: 10 * scale) {
                        largeMetric("HR",
                            value: context.state.heartRate > 0 ? "\(context.state.heartRate)" : "--",
                            unit: "bpm", scale: scale)
                        if context.attributes.kind == .strength {
                            largeMetric("SETS", value: "\(context.state.completedSets)", unit: "sets", scale: scale)
                        } else {
                            largeMetric("DISTANCE",
                                value: String(format: "%.2f", context.state.distanceMeters / 1000),
                                unit: "km", scale: scale)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .foregroundStyle(WorkoutActivityPalette.text)
            .environment(\.colorScheme, .dark)
            .activityBackgroundTint(WorkoutActivityPalette.background)
            .activitySystemActionForegroundColor(WorkoutActivityPalette.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.name, systemImage: context.attributes.kind == .strength ? "dumbbell.fill" : "figure.run")
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
                Image(systemName: context.attributes.kind == .strength ? "dumbbell.fill" : "figure.run")
                    .foregroundStyle(WorkoutActivityPalette.primary)
            } compactTrailing: {
                elapsed(context.state)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WorkoutActivityPalette.text)
            } minimal: {
                Image(systemName: context.attributes.kind == .strength ? "dumbbell.fill" : "figure.run")
                    .foregroundStyle(WorkoutActivityPalette.primary)
            }
        }
    }

    @ViewBuilder
    private func elapsed(_ state: WorkoutActivityAttributes.ContentState) -> some View {
        if let runningSince = state.runningSince, state.phase == .running {
            Text(runningSince, style: .timer)
        } else {
            Text(Duration.seconds(state.elapsedSeconds).formatted(.time(pattern: .hourMinuteSecond)))
        }
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
                .font(.system(size: 10, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(WorkoutActivityPalette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 27, weight: .heavy, design: .rounded))
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
