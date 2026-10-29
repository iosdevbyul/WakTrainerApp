import Combine
import AuthenticationKit
import Foundation
import HealthKit
import Network
import WakTrainerServiceHealthKit
import TrisLocationKit
import TrisNotificationKit
import TrisPlaceRecognitionKit
import UserProfileFeature
import WakTrainerFeatureWorkout

enum RemoteProfileCheck: Equatable {
    case notChecked
    case checking
    case available
    case notFound
    case unavailable
}

enum WorkoutDataMode: String, CaseIterable {
    case server
    case localOnly
}

@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var isProfileConfigured: Bool
    @Published private(set) var placeStore: (any PlaceStoring)?
    @Published private(set) var visitManager: PlaceVisitManager?
    @Published private(set) var isPreparingPlaces = false
    @Published private(set) var isPlaceRecognitionRequested: Bool
    @Published private(set) var placeStatusMessage: String?
    @Published private(set) var placeErrorMessage: String?

    @Published private(set) var workoutDataMode: WorkoutDataMode
    private let workoutDataModeKey = "WakTrainer.workoutDataMode"
    @Published private(set) var workoutHistoryStore: WorkoutHistoryStore
    private(set) var workoutOwnerUserID: UUID?
    private var workoutSync: WorkoutServerSync?
    private var workoutSyncTask: Task<Void, Never>?
    private var workoutSyncGeneration = 0
    private let networkMonitor = NWPathMonitor()
    private var hasStartedNetworkMonitor = false
    let locationProvider: CoreLocationProvider
    let wifiProvider: any WiFiProviding

    private let notificationService: LocalNotificationService
    private let healthKitManager = HealthKitManager()
    private var didRequestHealthKitAuthorization = false
    private let profileManager: DefaultUserProfileManager
    @Published private(set) var remoteProfileCheck: RemoteProfileCheck = .notChecked
    @Published private(set) var profileSyncDecision: ProfileSyncDecision?
    @Published private(set) var profileConflictSnapshot: ProfileConflictSnapshot?
    private var remoteProfileCheckTask: Task<Void, Never>?
    private var remoteProfileCheckGeneration = 0

    private let backgroundRecognitionPreferenceKey =
        "WakTrainer.backgroundPlaceRecognitionEnabled"

    init() {
        let profileManager = DefaultUserProfileManager.shared

        self.workoutDataMode = WorkoutDataMode(
            rawValue: UserDefaults.standard.string(forKey: "WakTrainer.workoutDataMode") ?? ""
        ) ?? .server
        self.workoutHistoryStore = WorkoutHistoryStore()
        self.locationProvider = CoreLocationProvider()
#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
        self.wifiProvider = DemoWiFiProvider()
#else
        self.wifiProvider = SystemWiFiProvider()
#endif
        self.notificationService = LocalNotificationService()
        self.profileManager = profileManager
        self.isProfileConfigured = profileManager.loadProfile() != nil
        self.isPlaceRecognitionRequested = UserDefaults.standard.bool(
            forKey: backgroundRecognitionPreferenceKey
        )
    }

    func handleApplicationLaunch() async {
        refreshProfile()
        await workoutHistoryStore.reload()
        await preparePlaceServices()

        guard isPlaceRecognitionRequested else {
            return
        }

        await resumeRequestedPlaceRecognition()
    }

    func handleSceneBecameActive() async {
        refreshProfile()
        await workoutHistoryStore.reload()
        await preparePlaceServices()

        guard isPlaceRecognitionRequested else {
            return
        }

        await resumeRequestedPlaceRecognition()
    }

    func refreshProfile() {
        isProfileConfigured = profileManager.loadProfile() != nil
    }

    func preparePlaceServices() async {
        guard placeStore == nil, visitManager == nil else {
            return
        }

        guard !isPreparingPlaces else {
            return
        }

        isPreparingPlaces = true
        placeErrorMessage = nil

        defer {
            isPreparingPlaces = false
        }

        do {
            let store = try await PlaceStoreFactory.makeDefaultStore()

            let recognitionService = PlaceRecognitionService(
                locationProvider: locationProvider,
                wifiProvider: wifiProvider,
                placeStore: store
            )

#if WAKTRAINER_DEMO
            let recognitionPolicy: PlaceRecognitionPolicy = .gpsConstrained
#else
            let recognitionPolicy: PlaceRecognitionPolicy = .wifiFirst
#endif

            let manager = try PlaceVisitManager(
                recognitionService: recognitionService,
                recognitionPolicy: recognitionPolicy,
                placeVisitNotificationsEnabled: true
            )

            _ = try await manager.restore()

            placeStore = store
            visitManager = manager
        } catch {
            placeErrorMessage = error.localizedDescription
        }
    }

    func enablePlaceRecognition() async {
        placeErrorMessage = nil

        let authorization = await locationProvider
            .requestWhenInUseAuthorization()

        switch authorization {
        case .authorizedWhenInUse, .authorizedAlways:
            break

        case .notDetermined:
            placeErrorMessage = AppL10n.string("place.permission.not_selected")
            return

        case .restricted:
            placeErrorMessage = AppL10n.string("place.permission.restricted")
            return

        case .denied:
            placeErrorMessage = AppL10n.string("place.permission.required")
            return

        case .unknown:
            placeErrorMessage = AppL10n.string("place.permission.unknown")
            return
        }

        await requestNotificationPermissionIfNeeded()
        await preparePlaceServices()

        guard let visitManager else {
            placeErrorMessage = AppL10n.string("place.service.prepare_failed")
            return
        }

        isPlaceRecognitionRequested = true
        UserDefaults.standard.set(
            true,
            forKey: backgroundRecognitionPreferenceKey
        )

        do {
            try await visitManager.start()
            try await visitManager.startBackgroundRecognition()

            placeStatusMessage =
                AppL10n.string("place.status.background_active")
        } catch let error as BackgroundRecognitionManagerError {
            handleBackgroundRecognitionError(error)
        } catch {
            placeErrorMessage = error.localizedDescription
        }
    }

    func disablePlaceRecognition() async {
        visitManager?.stop()
        await visitManager?.stopBackgroundRecognition()

        isPlaceRecognitionRequested = false
        UserDefaults.standard.set(
            false,
            forKey: backgroundRecognitionPreferenceKey
        )

        placeStatusMessage = AppL10n.string("place.status.disabled")
        placeErrorMessage = nil
    }

    func requestHealthKitAuthorizationIfNeeded() async {
        guard !didRequestHealthKitAuthorization else { return }

        // Request Motion & Fitness access during the same initial
        // authorization flow as HealthKit, before workout navigation.
        // The sensor is optional and its denial must not block HealthKit.
        await WorkoutMotionAuthorization.prepareIfAvailable()

        do {
            // iOS 26 AirPods heart-rate collection starts an HKWorkoutSession,
            // which requires workout-sharing consent. Request that consent
            // alongside heart-rate reading on home entry, never after Start.
            if #available(iOS 26.0, *), HKHealthStore.isHealthDataAvailable() {
                let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
                let workout = HKObjectType.workoutType()
                try await HKHealthStore().requestAuthorization(
                    toShare: [workout],
                    read: [heartRate, workout]
                )
            }
            _ = try await healthKitManager.requestAuthorization()
            didRequestHealthKitAuthorization = true
        } catch {
            // A failed request can be retried on the next home entry.
            // HealthKit is optional: never block a workout.
            print("HealthKit authorization request failed: \(error)")
        }
    }

    func configureWorkoutSync(ownerUserID: UUID?) {
        guard workoutOwnerUserID != ownerUserID else { return }
        cancelWorkoutSync()
        workoutOwnerUserID = ownerUserID
        remoteProfileCheckGeneration += 1
        remoteProfileCheckTask?.cancel()
        remoteProfileCheckTask = nil
        remoteProfileCheck = .notChecked
        profileSyncDecision = nil
        profileConflictSnapshot = nil
        if let ownerUserID {
            checkRemoteProfile(ownerUserID: ownerUserID)
        }
        // Replace the published store immediately so old-account rows
        // cannot remain visible during the next asynchronous reload.
        workoutHistoryStore = WorkoutHistoryStore(ownerUserID: ownerUserID)
        workoutSync = nil

        guard let ownerUserID,
              let urlString = Bundle.main.object(
                  forInfoDictionaryKey: "WORKOUT_API_BASE_URL"
              ) as? String,
              let baseURL = URL(string: urlString),
              ["http", "https"].contains(baseURL.scheme?.lowercased() ?? "") else {
            return
        }

        workoutSync = try? WorkoutServerSync(
            baseURL: baseURL,
            ownerUserID: ownerUserID,
            accessToken: {
                guard let session = AuthenticationService.shared.currentSession,
                      UUID(uuidString: session.user.id) == ownerUserID else {
                    return nil
                }
                return session.accessToken
            }
        )
        startWorkoutNetworkMonitoringIfNeeded()
    }

    /// A read-only server probe: it must never replace or remove the persisted local profile.
    private func checkRemoteProfile(ownerUserID: UUID) {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "WORKOUT_API_BASE_URL") as? String,
              let url = URL(string: string),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            return
        }

        let generation = remoteProfileCheckGeneration
        remoteProfileCheck = .checking
        remoteProfileCheckTask = Task { [weak self] in
            let result: RemoteProfileCheck
            let decision: ProfileSyncDecision
            var snapshot: ProfileConflictSnapshot?
            do {
                let remote = try await ProfileServerTransport(
                    baseURL: url, ownerUserID: ownerUserID
                ).fetchProfile()
                result = remote == nil ? .notFound : .available
                let local = self?.profileManager.loadProfile()
                decision = ProfileSyncDecision.evaluate(local: local, remote: remote, remoteReachable: true)
                if decision == .conflict, let local, let remote {
                    snapshot = ProfileConflictSnapshot(ownerUserID: ownerUserID, local: local, remote: remote)
                }
            } catch is CancellationError {
                return
            } catch {
                result = .unavailable
                decision = .remoteUnavailable
            }
            guard !Task.isCancelled, let self,
                  generation == self.remoteProfileCheckGeneration,
                  self.workoutOwnerUserID == ownerUserID else { return }
            self.remoteProfileCheck = result
            self.profileSyncDecision = decision
            self.profileConflictSnapshot = snapshot
            self.remoteProfileCheckTask = nil
        }
    }

    private func startWorkoutNetworkMonitoringIfNeeded() {
        guard !hasStartedNetworkMonitor else { return }
        hasStartedNetworkMonitor = true

        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }

            Task { @MainActor [weak self] in
                await self?.syncPendingWorkouts()
            }
        }
        networkMonitor.start(
            queue: DispatchQueue(label: "WakTrainer.WorkoutNetworkMonitor")
        )
    }

    func setWorkoutDataMode(_ mode: WorkoutDataMode) {
        guard workoutDataMode != mode else { return }
        if mode == .localOnly {
            cancelWorkoutSync()
        }
        workoutDataMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: workoutDataModeKey)
        if mode == .server {
            Task { await syncPendingWorkouts() }
        }
    }

    private func cancelWorkoutSync() {
        workoutSyncGeneration += 1
        workoutSyncTask?.cancel()
        workoutSyncTask = nil
    }

    func syncPendingWorkouts() async {
        guard workoutDataMode == .server else { return }
        if let workoutSyncTask {
            await workoutSyncTask.value
            return
        }
        guard let workoutSync else { return }
        let generation = workoutSyncGeneration
        let task = Task {
            await workoutSync.syncPendingSessions()
        }
        workoutSyncTask = task
        await task.value
        if generation == workoutSyncGeneration {
            workoutSyncTask = nil
        }
    }

    func refreshWorkoutHistory() async {
        await workoutHistoryStore.reload()
    }

    private func resumeRequestedPlaceRecognition() async {
        guard let visitManager else {
            return
        }

        switch locationProvider.authorizationStatus {
        case .authorizedAlways:
            do {
                try await visitManager.start()
                try await visitManager.startBackgroundRecognition()

                placeStatusMessage =
                    AppL10n.string("place.status.background_active")
                placeErrorMessage = nil
            } catch {
                placeErrorMessage = error.localizedDescription
            }

        case .authorizedWhenInUse:
            do {
                try await visitManager.start()

                placeStatusMessage =
                    AppL10n.string("place.status.always_permission_needed")
                placeErrorMessage = nil
            } catch {
                placeErrorMessage = error.localizedDescription
            }

        case .notDetermined:
            placeStatusMessage =
                AppL10n.string("place.status.will_request_permission")

        case .denied:
            placeErrorMessage =
                AppL10n.string("place.status.settings_permission_needed")

        case .restricted:
            placeErrorMessage =
                AppL10n.string("place.status.device_restricted")

        case .unknown:
            placeErrorMessage =
                AppL10n.string("place.permission.unknown")
        }
    }

    private func requestNotificationPermissionIfNeeded() async {
        let status = await notificationService.permissionStatus()

        guard status == .notDetermined else {
            return
        }

        do {
            _ = try await notificationService.requestPermission()
        } catch {
            placeErrorMessage =
                AppL10n.string("place.notification.permission_failed")
        }
    }

    private func handleBackgroundRecognitionError(
        _ error: BackgroundRecognitionManagerError
    ) {
        switch error {
        case .alwaysAuthorizationRequired:
            placeStatusMessage =
                AppL10n.string("place.background.always_requested")
            placeErrorMessage = nil

        case .authorizationDenied:
            placeErrorMessage =
                AppL10n.string("place.background.denied")

        case .authorizationRestricted:
            placeErrorMessage =
                AppL10n.string("place.background.restricted")

        case .authorizationUnknown:
            placeErrorMessage =
                AppL10n.string("place.permission.unknown")

        case .unacceptableLocationSnapshot:
            placeErrorMessage =
                AppL10n.string("place.background.inaccurate_location")
        }
    }


}

#if WAKTRAINER_DEMO || WAKTRAINER_DEVICE_TEST
/// A Wi-Fi-free implementation for Personal Team demo builds.
private struct DemoWiFiProvider: WiFiProviding {
    func currentNetwork() async -> WiFiNetwork? { nil }
}
#endif
