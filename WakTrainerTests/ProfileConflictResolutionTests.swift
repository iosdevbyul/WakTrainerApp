import Foundation
import Testing
import WakTrainerCoreModels
@testable import WakTrainer

@Suite("Profile conflict resolution plan")
struct ProfileConflictResolutionTests {
    private let local = UserProfile(
        gender: .male, birthDate: Date(timeIntervalSince1970: 1_125_014_400),
        heightCm: 175, weightKg: 70
    )
    private let remote = UserProfile(
        gender: .female, birthDate: Date(timeIntervalSince1970: 946_684_800),
        heightCm: 165, weightKg: 60
    )

    @Test("Conflicting profiles require an explicit choice")
    func conflictRequiresChoice() {
        #expect(ProfileConflictResolver.plan(local: local, remote: remote, remoteReachable: true) == .requiresUserChoice)
        #expect(ProfileConflictResolver.plan(local: local, remote: remote, remoteReachable: true, choice: .keepLocal) == .uploadLocal(local))
        #expect(ProfileConflictResolver.plan(local: local, remote: remote, remoteReachable: true, choice: .useServer) == .restoreServer(remote))
        #expect(ProfileConflictResolver.plan(local: local, remote: remote, remoteReachable: true, choice: .postpone) == .noAction)
    }

    @Test("Single-sided records yield deterministic candidates, not writes")
    func missingSide() {
        #expect(ProfileConflictResolver.plan(local: local, remote: nil, remoteReachable: true) == .uploadLocal(local))
        #expect(ProfileConflictResolver.plan(local: nil, remote: remote, remoteReachable: true) == .restoreServer(remote))
        #expect(ProfileConflictResolver.plan(local: nil, remote: nil, remoteReachable: true) == .noAction)
    }

    @Test("Offline state always prevents resolution")
    func offline() {
        #expect(ProfileConflictResolver.plan(local: local, remote: remote, remoteReachable: false, choice: .useServer) == .unavailable)
    }
}
