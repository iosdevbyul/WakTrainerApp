import Foundation
import WakTrainerCoreModels

/// Pure policy for inspecting local and remote profiles before any write or migration.
/// This policy deliberately never chooses a winner for conflicting values.
enum ProfileSyncDecision: Equatable {
    case noProfile
    case localOnly
    case remoteOnly
    case matching
    case conflict
    case remoteUnavailable

    static func evaluate(
        local: UserProfile?,
        remote: UserProfile?,
        remoteReachable: Bool
    ) -> Self {
        guard remoteReachable else { return .remoteUnavailable }
        switch (local, remote) {
        case (nil, nil): return .noProfile
        case (.some, nil): return .localOnly
        case (nil, .some): return .remoteOnly
        case let (.some(local), .some(remote)):
            return equivalent(local, remote) ? .matching : .conflict
        }
    }

    private static func equivalent(_ lhs: UserProfile, _ rhs: UserProfile) -> Bool {
        // Birth dates are calendar dates, not timestamps. Server supplies midnight UTC.
        let calendar = Calendar(identifier: .gregorian)
        let first = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: lhs.birthDate)
        let second = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: rhs.birthDate)
        return lhs.gender == rhs.gender &&
            first.year == second.year &&
            first.month == second.month &&
            first.day == second.day &&
            lhs.heightCm == rhs.heightCm &&
            lhs.weightKg == rhs.weightKg
    }
}
