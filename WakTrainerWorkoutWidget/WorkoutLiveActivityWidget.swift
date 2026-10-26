import ActivityKit
import SwiftUI
import WidgetKit
import WakTrainerLiveActivityModels

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(context.attributes.name, systemImage: context.attributes.kind == .strength ? "dumbbell.fill" : "figure.run")
                        .font(.headline)
                    Spacer()
                    Text(context.state.phase == .paused ? "Paused" : "In Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline) {
                    elapsed(context.state)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Spacer()
                    if context.attributes.kind == .strength {
                        Text("\(context.state.completedSets) sets")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                HStack(spacing: 16) {
                    metric("Heart Rate", "\(context.state.heartRate) bpm")
                    metric("Calories", "\(context.state.calories) kcal")
                }
                if context.attributes.kind == .strength {
                    HStack(spacing: 16) {
                        metric("Current Exercise", context.state.exercise ?? "Choose exercise")
                        metric("Sets Done", "\(context.state.completedSets)")
                    }
                } else {
                    HStack(spacing: 16) {
                        metric("Distance", String(format: "%.2f km", context.state.distanceMeters / 1000))
                        metric("Steps", context.state.steps.formatted())
                    }
                }
            }
            .padding()
            // The Live Activity uses a fixed dark surface even in light appearance.
            // Explicitly pair it with light foreground colors for legibility.
            .foregroundStyle(.white)
            .environment(\.colorScheme, .dark)
            .activityBackgroundTint(Color(red: 0.09, green: 0.10, blue: 0.14))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.exercise ?? context.attributes.name, systemImage: context.attributes.kind == .strength ? "dumbbell" : "figure.run")
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    elapsed(context.state).monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        metric("Heart Rate", "\(context.state.heartRate) bpm")
                        metric("Calories", "\(context.state.calories) kcal")
                        if context.attributes.kind == .strength {
                            metric("Sets", "\(context.state.completedSets)")
                        } else {
                            metric("Distance", String(format: "%.2f km", context.state.distanceMeters / 1000))
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.kind == .strength ? "dumbbell" : "figure.run")
            } compactTrailing: {
                elapsed(context.state).font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: context.attributes.kind == .strength ? "dumbbell.fill" : "figure.run")
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

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct WakTrainerWorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}
