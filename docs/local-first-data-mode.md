# Local-first data mode: baseline and implementation contract

Status: Phase 1 architecture baseline. No runtime behavior changes in this phase.

## Goal

Keep a single WakTrainer app able to record, browse, and report on workouts even when the Mac-hosted server is unreachable. A hidden developer control may explicitly disable server synchronization. Switching back must reconcile pending local writes safely.

## Verified module boundaries (default branches, 2026-10-23)

- `WakTrainerFeatureWorkout` publishes a completed `WorkoutSession` to its host through the `WorkoutLauncherView` completion closure, as documented in its README.
- `WakTrainerFeatureWorkout/Package.swift` depends on `WakTrainerServiceWorkoutStorage`, `WakTrainerDomainWorkout`, and `WakTrainerCoreModels`.
- `WakTrainerServiceWorkoutStorage/Package.swift` depends on domain and core model packages, not on FeatureWorkout or the app.
- The app README describes app ownership of Home, calendar, reports, profile and orchestration.

**Not yet verified:** exact storage technology, App completion handler, report query path, calendar data source, network endpoints, online authentication restrictions, and existing upload/retry behavior. These must be inspected before implementation. Do not infer SwiftData or local persistence guarantees from module names.

## Required behavior

1. One application target; do not introduce a second app or build variant.
2. All newly completed sessions are durably committed locally before being eligible for upload.
3. Local reads must drive workout history, calendar and reports where sufficient local data exists.
4. `server` mode allows sync when the backend is reachable. `localOnly` mode forbids server sync requests, regardless of connectivity.
5. Both modes continue local capture. A server failure never prevents or deletes a local workout.
6. Pending work is durable across termination, app relaunch and network outages.
7. A stable session ID must be used as the idempotency key and deduplication identity for retry/reconciliation.
8. Mark an item synced only after confirmed remote acknowledgement; a crash during upload leaves it safely retryable.
9. Mode switching must not purge local records or bypass a required user session/authentication flow.
10. Existing online-only capabilities must explicitly disclose unavailability rather than silently present misleading figures.

## Proposed contracts (subject to repository inspection)

```swift
enum DataMode: String, Codable, Sendable {
    case server
    case localOnly
}

enum SyncState: String, Codable, Sendable {
    case pending
    case syncing
    case synced
    case failed
}
```

The app composition root should own the mode and sync orchestration. Domain models should remain presentation-agnostic. Use the existing local storage implementation if it can provide durable writes; do not add a second database without a migration reason.

## Discovery checklist before code changes

- [ ] Trace completed session handling from WorkoutLauncherView into the app.
- [ ] Inspect existing workout storage API and persistence guarantees.
- [ ] Trace Home, calendar, history and report reads to their authoritative source.
- [ ] Inventory all backend-dependent screens and services (including login, report calculations, health sync).
- [ ] Check record identity and server-side idempotency/upsert capability.
- [ ] Check existing failed-upload handling, migration and data retention behavior.
- [ ] Identify proper app-level Settings entry point for a hidden five-tap developer control.
- [ ] Document how switching modes impacts any currently in-flight request.

## Planned PR sequence

1. Audit and contract (this PR): document boundaries, invariants and unresolved dependencies. No runtime changes.
2. Local persistence read/write path and migration, plus deterministic tests.
3. Durable outbox and idempotent sync coordinator, including offline/restart tests.
4. Hidden developer control and mode persistence, including sync prohibition tests.
5. Integrate local reads into history, calendar and reports; verify real-device offline behavior.

## Release gates

- Existing CI passes for each changed repository.
- Offline workout completion and report access are manually verified with backend unavailable.
- Repeated replay creates no duplicate server workouts.
- In-flight operations, partial responses, app restarts and authentication expiration are covered.
- Keep all changes on feature branches with a PR; no direct main mutation.
