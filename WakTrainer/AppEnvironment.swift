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
    @Published private(set) var workoutHistory: [WorkoutSummaryRecord]

    let locationProvider: CoreLocationProvider
    let wifiProvider: any WiFiProviding

    private let notificationService: LocalNotificationService
    private let profileManager: DefaultUserProfileManager

    private let backgroundRecognitionPreferenceKey =
        "WakTrainer.backgroundPlaceRecognitionEnabled"

    private let workoutHistoryStorageKey =
        "WakTrainer.workoutHistory"

    init() {
        let profileManager = DefaultUserProfileManager.shared

        self.locationProvider = CoreLocationProvider()
        self.wifiProvider = SystemWiFiProvider()
        self.notificationService = LocalNotificationService()
        self.profileManager = profileManager
        self.isProfileConfigured = profileManager.loadProfile() != nil
        self.isPlaceRecognitionRequested = UserDefaults.standard.bool(
            forKey: backgroundRecognitionPreferenceKey
        )
        self.workoutHistory = Self.loadWorkoutHistory(
            storageKey: workoutHistoryStorageKey
        )
    }

    func handleApplicationLaunch() async {
        refreshProfile()
        await preparePlaceServices()

        guard isPlaceRecognitionRequested else {
            return
        }

        await resumeRequestedPlaceRecognition()
    }

    func handleSceneBecameActive() async {
        refreshProfile()
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
            placeErrorMessage = "위치 권한 선택이 완료되지 않았습니다."
            return

        case .restricted:
            placeErrorMessage = "위치 사용이 제한되어 있습니다."
            return

        case .denied:
            placeErrorMessage = "헬스장 도착과 이탈을 감지하려면 위치 권한이 필요합니다."
            return

        case .unknown:
            placeErrorMessage = "현재 위치 권한 상태를 확인할 수 없습니다."
            return
        }

        await requestNotificationPermissionIfNeeded()
        await preparePlaceServices()

        guard let visitManager else {
            placeErrorMessage = "장소 인식 서비스를 준비하지 못했습니다."
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
                "헬스장 도착과 이탈을 백그라운드에서 감지하고 있습니다."
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

        placeStatusMessage = "헬스장 자동 감지를 껐습니다."
        placeErrorMessage = nil
    }

    func recordWorkout(_ result: WorkoutFeatureResult) {
        let endedAt = Date()
        let startedAt = endedAt.addingTimeInterval(-result.duration)

        let record = WorkoutSummaryRecord(
            workoutID: result.workoutID,
            workoutName: result.workoutName,
            startedAt: startedAt,
            endedAt: endedAt,
            duration: result.duration,
            distanceMeters: result.distanceMeters,
            activeCalories: result.activeCalories,
            stepCount: result.stepCount
        )

        workoutHistory.insert(record, at: 0)
        persistWorkoutHistory()
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
                    "헬스장 도착과 이탈을 백그라운드에서 감지하고 있습니다."
                placeErrorMessage = nil
            } catch {
                placeErrorMessage = error.localizedDescription
            }

        case .authorizedWhenInUse:
            do {
                try await visitManager.start()

                placeStatusMessage =
                    "앱을 닫은 뒤에도 감지하려면 위치 접근을 '항상'으로 허용해 주세요."
                placeErrorMessage = nil
            } catch {
                placeErrorMessage = error.localizedDescription
            }

        case .notDetermined:
            placeStatusMessage =
                "헬스장 자동 감지를 켜면 위치 권한을 요청합니다."

        case .denied:
            placeErrorMessage =
                "설정에서 위치 권한을 허용해야 헬스장 자동 감지를 다시 시작할 수 있습니다."

        case .restricted:
            placeErrorMessage =
                "이 기기에서는 위치 사용이 제한되어 있습니다."

        case .unknown:
            placeErrorMessage =
                "현재 위치 권한 상태를 확인할 수 없습니다."
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
                "알림 권한을 요청하지 못했습니다. 장소 감지는 계속 사용할 수 있습니다."
        }
    }

    private func handleBackgroundRecognitionError(
        _ error: BackgroundRecognitionManagerError
    ) {
        switch error {
        case .alwaysAuthorizationRequired:
            placeStatusMessage =
                "백그라운드 감지를 위해 '항상 허용' 권한을 요청했습니다. 권한을 선택하면 자동으로 이어집니다."
            placeErrorMessage = nil

        case .authorizationDenied:
            placeErrorMessage =
                "위치 권한이 거부되어 백그라운드 감지를 시작할 수 없습니다."

        case .authorizationRestricted:
            placeErrorMessage =
                "위치 사용이 제한되어 백그라운드 감지를 시작할 수 없습니다."

        case .authorizationUnknown:
            placeErrorMessage =
                "현재 위치 권한 상태를 확인할 수 없습니다."

        case .unacceptableLocationSnapshot:
            placeErrorMessage =
                "현재 위치 정확도가 충분하지 않습니다. 잠시 후 다시 시도해 주세요."
        }
    }

    private func persistWorkoutHistory() {
        guard let data = try? JSONEncoder().encode(workoutHistory) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: workoutHistoryStorageKey
        )
    }

    private static func loadWorkoutHistory(
        storageKey: String
    ) -> [WorkoutSummaryRecord] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let history = try? JSONDecoder().decode(
                [WorkoutSummaryRecord].self,
                from: data
            )
        else {
            return []
        }

        return history.sorted {
            $0.endedAt > $1.endedAt
        }
    }
}
