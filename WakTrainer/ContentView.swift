import SwiftUI
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
import MapKit
#endif
import UserProfileFeature
import WakTrainerCoreModels
import WakTrainerDesignSystem
import WakTrainerFeatureWorkout

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var environment: AppEnvironment
    @ObservedObject private var liveActivityController = WorkoutLiveActivityController.shared
    var ownerUserID: UUID? = nil

    @State private var isShowingProfileSetup = false
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
    @State private var showingProfileMapDemo = false
#endif

    var body: some View {
        Group {
            if environment.isProfileConfigured {
                MainOrbNavigationView(
                    environment: environment,
                    ownerUserID: ownerUserID
                )
            } else {
                profileRequiredView
            }
        }
        .alert(item: $liveActivityController.failure) { failure in
            Alert(
                title: Text("Live Activity Could Not Start"),
                message: Text(failure.message),
                dismissButton: .default(Text("OK"))
            )
        }
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
        .sheet(isPresented: $showingProfileMapDemo) {
            RunningMapModesDemoView()
        }
#endif
        .preferredColorScheme(.dark)
        .tint(WakColor.primary)
        .task {
            environment.configureWorkoutSync(ownerUserID: ownerUserID)
            await environment.handleSceneBecameActive()
            await environment.syncPendingWorkouts()
            await environment.requestHealthKitAuthorizationIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await environment.handleSceneBecameActive()
                await environment.syncPendingWorkouts()
            }
        }
        .sheet(
            isPresented: $isShowingProfileSetup,
            onDismiss: {
                environment.refreshProfile()
            }
        ) {
            ProfileSetupView()
        }
    }

    private var profileRequiredView: some View {
        ZStack {
            WakColor.background
                .ignoresSafeArea()

            WakCard(
                padding: WakSpacing.large
            ) {
                VStack(
                    spacing: WakSpacing.large
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
                                size: 36,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            WakColor.primary
                        )
                    }
                    .frame(
                        width: 80,
                        height: 80
                    )

                    Text("WakTrainer")
                        .font(WakTypography.screenTitle)
                        .foregroundStyle(
                            WakColor.textPrimary
                        )

                    Text(
                        AppL10n.string(
                            "profile.required.description"
                        )
                    )
                    .font(WakTypography.body)
                    .foregroundStyle(
                        WakColor.textSecondary
                    )
                    .multilineTextAlignment(.center)

                    WakPrimaryButton(
                        "profile.body.setup"
                    ) {
                        isShowingProfileSetup = true
                    }
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
                    Button("3D Map Demo · 4 Modes") {
                        showingProfileMapDemo = true
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("demo.map3D.profile")
#endif
                }
            }
            .padding(WakSpacing.large)
        }
    }
}

private struct MainOrbNavigationView: View {
    @ObservedObject var environment: AppEnvironment
    @ObservedObject private var liveActivityController = WorkoutLiveActivityController.shared
    let ownerUserID: UUID?

    @State
    private var path: [MainRoute] = []
#if WAKTRAINER_DEMO
    @State private var showingLiveActivityTest = false
#endif
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
    @State private var showing3DMapDemo = false
#endif

    private var estimatedMaximumHeartRate: Double? {
        guard let profile = DefaultUserProfileManager.shared.profile,
              (1...100).contains(profile.age) else { return nil }
        return Double(220 - profile.age)
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                environment: environment,
                workoutHistoryStore:
                    environment.workoutHistoryStore,
                onShowReports: {
                    path.append(.reports)
                },
                onShowCalendar: {
                    path.append(.calendar)
                },
                onShowPlaces: {
                    path.append(.places)
                }
            )
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 92)
            }
            .wakTrainerWorkoutLauncher(
                maximumHeartRate: estimatedMaximumHeartRate,
                bottomPadding: 16,
                ownerUserID: ownerUserID,
                resumeRequestID: liveActivityController.resumeRequestID,
                onFinished: { _ in
                    WorkoutLiveActivityController.shared.finish()
                    Task {
                        await environment.refreshWorkoutHistory()
                        await environment.syncPendingWorkouts()
                    }
                },
                onWorkoutUpdate: { snapshot in
                    WorkoutLiveActivityController.shared.receive(snapshot)
                }
            )
            .toolbar {
#if WAKTRAINER_DEMO
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Activity Test") {
                        showingLiveActivityTest = true
                    }
                    .accessibilityIdentifier("demo.liveActivityTest")
                }
#endif
                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {
                    toolbarButton(
                        systemImage: "calendar",
                        accessibilityKey:
                            "common.calendar"
                    ) {
                        path.append(.calendar)
                    }

                    toolbarButton(
                        systemImage:
                            "person.crop.circle",
                        accessibilityKey:
                            "common.profile"
                    ) {
                        path.append(.profile)
                    }
                }
            }
            .navigationDestination(
                for: MainRoute.self
            ) { route in
                switch route {
                case .reports:
                    ReportsView(ownerUserID: ownerUserID)

                case .calendar:
                    WorkoutCalendarView(
                        workoutHistoryStore:
                            environment.workoutHistoryStore,
                        ownerUserID: ownerUserID
                    )

                case .places:
                    PlacesView(
                        environment: environment
                    )

                case .profile:
                    ProfileView(
                        environment: environment
                    )
                }
            }
        }
#if WAKTRAINER_DEMO
        .sheet(isPresented: $showingLiveActivityTest) {
            DemoLiveActivityDiagnosticView()
        }
#endif
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
        .sheet(isPresented: $showing3DMapDemo) {
            RunningMapModesDemoView()
        }
#endif
        .background(WakColor.background)
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
        .safeAreaInset(edge: .top) {
            if path.isEmpty {
            Button {
                showing3DMapDemo = true
            } label: {
                Label("3D Map Demo · 4 Modes", systemImage: "map.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .accessibilityIdentifier("demo.map3D")
            }
        }
#endif
#if WAKTRAINER_DEVICE_TEST
        .safeAreaInset(edge: .top) {
            HStack(spacing: 8) {
                Text("DEVICE TEST · WT-20261027-B")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                Spacer()
                Text("Feature 8c03ae0")
                    .font(.system(size: 10, design: .monospaced))
            }
            .foregroundStyle(WakColor.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(WakColor.background)
            .accessibilityIdentifier("diagnostics.deviceTestBuild")
        }
#endif

    }

    private func toolbarButton(
        systemImage: String,
        accessibilityKey: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    WakColor.textPrimary
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(WakColor.surface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            AppL10n.string(
                accessibilityKey
            )
        )
    }
}

private enum MainRoute: Hashable {
    case reports
    case calendar
    case places
    case profile
}

#Preview {
    ContentView(
        environment: AppEnvironment()
    )
}

#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
/// A self-contained visual prototype. All locations below are synthetic samples;
/// the demo never starts, records, or uploads a real workout.
private struct RunningMapModesDemoView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case classic = "2D"
        case follow = "3D Follow"
        case aerial = "3D Aerial"
        case runner = "Runner View"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .follow
    @State private var position: MapCameraPosition = .automatic
    @State private var sampleIndex = 0
    @State private var playing = false

    // A fixed example near central Seoul. Never tied to the user's location.
    private let sampleRoute: [CLLocationCoordinate2D] = [
        .init(latitude: 37.56650, longitude: 126.97800),
        .init(latitude: 37.56672, longitude: 126.97837),
        .init(latitude: 37.56696, longitude: 126.97877),
        .init(latitude: 37.56721, longitude: 126.97910),
        .init(latitude: 37.56747, longitude: 126.97943),
        .init(latitude: 37.56777, longitude: 126.97978),
        .init(latitude: 37.56802, longitude: 126.98008),
        .init(latitude: 37.56828, longitude: 126.98042),
        .init(latitude: 37.56858, longitude: 126.98068),
        .init(latitude: 37.56886, longitude: 126.98095)
    ]

    private var routePosition: CLLocationCoordinate2D {
        sampleRoute[min(sampleIndex, sampleRoute.count - 1)]
    }

    private var currentHeading: Double {
        let a = sampleRoute[max(0, min(sampleIndex, sampleRoute.count - 2))]
        let b = sampleRoute[min(sampleRoute.count - 1, max(1, sampleIndex + 1))]
        let radians = atan2(b.longitude - a.longitude, b.latitude - a.latitude)
        return radians * 180 / .pi
    }

    private var mapStyle: MapStyle {
        switch mode {
        case .classic: .standard(elevation: .flat)
        case .follow, .runner: .standard(elevation: .realistic)
        case .aerial: .imagery(elevation: .realistic)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Map mode", selection: $mode) {
                    ForEach(Mode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .accessibilityIdentifier("demo.map3D.mode")

                ZStack(alignment: .bottom) {
                    Map(position: $position) {
                        MapPolyline(coordinates: Array(sampleRoute.prefix(sampleIndex + 1)))
                            .stroke(WakColor.primary, lineWidth: 6)

                        Annotation("Runner", coordinate: routePosition, anchor: .center) {
                            Image(systemName: "figure.run.circle.fill")
                                .font(.system(size: mode == .runner ? 42 : 30))
                                .foregroundStyle(WakColor.primary)
                                .background(Circle().fill(.black.opacity(0.8)))
                        }
                    }
                    .mapStyle(mapStyle)
                    .mapControls {
                        MapCompass()
                        MapPitchToggle()
                        MapScaleView()
                    }

                    if mode == .runner {
                        VStack {
                            Spacer()
                            Image(systemName: "figure.run")
                                .font(.system(size: 72, weight: .medium))
                                .foregroundStyle(WakColor.primary)
                                .shadow(color: .black, radius: 6)
                                .padding(.bottom, 86)
                        }
                        .allowsHitTesting(false)
                        .accessibilityLabel("Runner viewpoint overlay")
                    }

                    HStack(spacing: 12) {
                        Button {
                            playing.toggle()
                        } label: {
                            Label(playing ? "Pause" : "Play", systemImage: playing ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("demo.map3D.play")

                        Button("Reset") {
                            playing = false
                            sampleIndex = 0
                            updateCamera()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                        Text("\(sampleIndex + 1)/\(sampleRoute.count)")
                            .monospacedDigit()
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding()
                }

                Text("Simulation only · No GPS or workout is recorded. Aerial 3D detail depends on Apple Maps coverage.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .navigationTitle("3D Running Map Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { updateCamera() }
            .onChange(of: mode) { _, _ in updateCamera() }
            .onChange(of: sampleIndex) { _, _ in updateCamera() }
            .task(id: playing) {
                guard playing else { return }
                while !Task.isCancelled && sampleIndex < sampleRoute.count - 1 {
                    do {
                        try await Task.sleep(for: .milliseconds(700))
                    } catch {
                        break
                    }
                    guard !Task.isCancelled else { break }
                    sampleIndex += 1
                }
                if !Task.isCancelled { playing = false }
            }
        }
    }

    private func updateCamera() {
        let distance: Double
        let pitch: Double
        let heading: Double
        switch mode {
        case .classic: (distance, pitch, heading) = (900, 0, 0)
        case .follow: (distance, pitch, heading) = (220, 65, currentHeading)
        case .aerial: (distance, pitch, heading) = (660, 60, currentHeading)
        case .runner: (distance, pitch, heading) = (100, 78, currentHeading)
        }
        withAnimation(.easeInOut(duration: 0.45)) {
            position = .camera(MapCamera(
                centerCoordinate: routePosition,
                distance: distance,
                heading: heading,
                pitch: pitch
            ))
        }
    }
}
#endif
