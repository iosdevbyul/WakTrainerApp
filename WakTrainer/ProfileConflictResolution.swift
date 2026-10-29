import Foundation
import WakTrainerCoreModels

/// Explicit choice required before changing either profile store.
/// This pure planner never writes, deletes, or sends any user data.
enum ProfileConflictChoice: Equatable {
    case keepLocal
    case useServer
    case postpone
}

enum ProfileResolutionPlan: Equatable {
    case noAction
    case uploadLocal(UserProfile)
    case restoreServer(UserProfile)
    case requiresUserChoice
    case unavailable
}

enum ProfileConflictResolver {
    static func plan(
        local: UserProfile?,
        remote: UserProfile?,
        remoteReachable: Bool,
        choice: ProfileConflictChoice? = nil
    ) -> ProfileResolutionPlan {
        let decision = ProfileSyncDecision.evaluate(
            local: local, remote: remote, remoteReachable: remoteReachable
        )
        switch decision {
        case .remoteUnavailable: return .unavailable
        case .noProfile, .matching: return .noAction
        case .localOnly:
            guard let local else { return .noAction }
            return .uploadLocal(local)
        case .remoteOnly:
            guard let remote else { return .noAction }
            return .restoreServer(remote)
        case .conflict:
            guard let choice else { return .requiresUserChoice }
            switch choice {
            case .keepLocal:
                guard let local else { return .requiresUserChoice }
                return .uploadLocal(local)
            case .useServer:
                guard let remote else { return .requiresUserChoice }
                return .restoreServer(remote)
            case .postpone:
                return .noAction
            }
        }
    }
}
