import Combine
import Foundation
import TrisLocationKit
import TrisNotificationKit
import TrisPlaceRecognitionKit
import UserProfileFeature
import WakTrainerFeatureWorkout

@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var isProfileConfigured: Bool
    @Published private(set) var placeStore: (any PlaceStoring)?
    @Published private(set) var visitManager: PlaceVisitManager?
    @Published private(set) var isPreparingPlaces = false
    @Published private(set) var isPlaceRecognitionRequested: Bool
    @Published private(set) var placeStatusMessage: String?
    @Published private(set) var placeErrorMessage: String?

    let workoutHistoryStore: WorkoutHistoryStore
    let locationProvider: CoreLocationProvider
    let wifiProvider: any WiFiProviding

    private let notificationService: LocalNotificationService
    private let profileManager: DefaultUserProfileManager

    private let backgroundRecognitionPreferenceKey =
        "WakTrainer.backgroundPlaceRecognitionEnabled"

    init() {
        let profileManager = DefaultUserProfileManager.shared

        self.workoutHistoryStore = WorkoutHistoryStore()
        self.locationProvider = CoreLocationProvider()
        self.wifiProvider = SystemWiFiProvider()
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

            let manager = try PlaceVisitManager(
                recognitionService: recognitionService,
                recognitionPolicy: .wifiFirst,
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
