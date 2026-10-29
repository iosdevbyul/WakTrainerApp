import Foundation
import WakTrainerCoreModels

/// Ephemeral comparison only. Never persisted or shared between accounts.
struct ProfileConflictSnapshot: Identifiable {
    let ownerUserID: UUID
    let local: UserProfile
    let remote: UserProfile
    var id: UUID { ownerUserID }
}
