# Local-first integration: account isolation and storage audit

Status: implementation blocker identified; no runtime changes in this audit.

## Evidence

- WakTrainerFeatureWorkout PR #25 states workout checkpoints and completed sessions are persisted via SwiftData.
- WakTrainerFeatureWorkout PR #26 describes provisional `WorkoutServerSync` using completed pending/failed SwiftData sessions and PUT `/v1/workouts/{UUID}`; only HTTP 2xx transitions to synced.
- PR #26 explicitly warns that `WorkoutSessionEntity` has no owning account/user ID. Replaying records under a different signed-in user's token could leak workout details across accounts.
- WakTrainerApp PR #34 configures distinct local authentication and workout API endpoints for Debug. Do not derive production workout API URL from the auth endpoint.
- WakTrainerApp PR #39 pins merged workout dependencies to specific revisions. Review pinned versions before integration; `Package.resolved` alone may not override the Xcode project package revision.

## Required safety contract

1. Every workout written while signed in must be associated with a stable, authenticated account identifier. Never use a mutable display name or email as the ownership key.
2. Repository read queries, report/history queries and sync candidate selection must be scoped by account ID.
3. Upon logout/account change, stop in-flight uploads and invalidate callbacks from the previous session. Confirm account identity again immediately before sending.
4. Preexisting unowned workouts must not be silently assigned to the next account. Migrate only with evidence of original ownership; otherwise quarantine locally and expose an explicit recovery decision later.
5. Keep stable workout UUID, local content and pending/sync status intact during migration.
6. Server must apply idempotency/upsert for the same workout UUID within the authenticated account; duplicate replay should not create another workout.
7. Sync failures and auth expiration leave records local; no deletion or reassignment.
8. Local-only mode must issue zero upload requests. Server mode can request synchronization only for authenticated account-owned pending records.

## Implementation ordering

A. Inspect the storage entity, schemas, repository methods, app composition root, and the precise authentication identity source.
B. Add account ownership to the owning storage layer and explicit migration handling with tests.
C. Add account-scoped history/report/calendar query access and backward-compatible APIs.
D. Revisit provisional WorkoutServerSync from PR #26; add MockURLProtocol tests for 2xx, 401, timeout, duplicate replay, account switch and mode disable.
E. Only then wire app-level `DataMode` persistence and hidden developer switch.

## Regression cases

- A records workout 1 offline; B signs in. B sees neither workout 1 nor upload candidates for A.
- Legacy unowned record remains retained but cannot upload to B.
- A signs in again; A's attributed pending record is still available for retry.
- Crash after server accepts PUT but before marking local synced: replay is idempotent.
- Repeated mode switching does not reset pending state or duplicate a record.
- No server connectivity: new workout + calendar + report remain accessible locally.
- Logout during a request cannot mutate the next account's record status.

## Open verification items

- Exact current source signatures for `WorkoutSessionEntity` and repository.
- Which auth/session public API provides stable account ownership.
- Exact calendar/report fetch paths and offline readiness.
- Workout server's actual authorization and per-account idempotency contract.
- Existing migration schema and tests.
- CI build, runtime and real-device verification.

## References

- https://github.com/iosdevbyul/WakTrainerFeatureWorkout/pull/25
- https://github.com/iosdevbyul/WakTrainerFeatureWorkout/pull/26
- https://github.com/iosdevbyul/WakTrainerApp/pull/34
- https://github.com/iosdevbyul/WakTrainerApp/pull/39
- https://github.com/iosdevbyul/WakTrainerApp/pull/41
