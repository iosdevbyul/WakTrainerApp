import Foundation
import Testing
import WakTrainerCoreModels
@testable import WakTrainer

@Suite("Profile sync decision")
struct ProfileSyncDecisionTests {
    private func profile(
        gender: UserProfile.Gender = .male,
        birthday: Date = Date(timeIntervalSince1970: 1_125_014_400),
        weight: Double = 70
    ) -> UserProfile {
        UserProfile(gender: gender, birthDate: birthday, heightCm: 175, weightKg: weight)
    }

    @Test("Missing profiles are not treated as conflicts")
    func missing() {
        #expect(ProfileSyncDecision.evaluate(local: nil, remote: nil, remoteReachable: true) == .noProfile)
        #expect(ProfileSyncDecision.evaluate(local: profile(), remote: nil, remoteReachable: true) == .localOnly)
        #expect(ProfileSyncDecision.evaluate(local: nil, remote: profile(), remoteReachable: true) == .remoteOnly)
    }

    @Test("Equal profiles match and changes are detected")
    func comparison() {
        #expect(ProfileSyncDecision.evaluate(local: profile(), remote: profile(), remoteReachable: true) == .matching)
        #expect(ProfileSyncDecision.evaluate(local: profile(), remote: profile(weight: 72), remoteReachable: true) == .conflict)
        #expect(ProfileSyncDecision.evaluate(local: profile(), remote: profile(gender: .female), remoteReachable: true) == .conflict)
    }

    @Test("Offline state does not imply profile deletion or absence")
    func unavailable() {
        #expect(ProfileSyncDecision.evaluate(local: profile(), remote: nil, remoteReachable: false) == .remoteUnavailable)
    }
}
