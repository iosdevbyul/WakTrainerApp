# Workout pause Restore: end-to-end verification

## Scope

This checklist applies to WakTrainer, WakTrainerDemo (Wi-Fi-free), and WakTrainerDeviceTest. All three consume the same pinned WakTrainerFeatureWorkout product. CI validates builds for all three schemes and tests the main app. The checklist below is **manual** until device results are recorded.

## Setup

1. Install the selected scheme and start a workout. Keep the app open through the exercise, pause, resume, and completion flow.
2. Create a completed workout containing a real pause interval. For example, work out for 20 minutes, pause for 15 minutes, then resume and work out for 25 minutes. Confirm the completed workout appears in History.
3. Keep a copy of the original active, paused, and elapsed durations. For a 60-minute session with 15 minutes paused, expect 45 minutes active.

## Restore and Undo acceptance cases

| Case | Steps | Expected result |
| --- | --- | --- |
| Partial Restore | Open completed workout report, choose Restore Paused Time, select 10 minutes inside a 15-minute pause, confirm | Active time increases by 10 minutes, paused time decreases by 10 minutes, elapsed time stays unchanged |
| Remaining pause | Reopen Restore | Only the un-restored pause portions remain selectable |
| Undo | Select Undo Restore before closing report | The original session and report are restored; no duplicate activity is counted |
| Persistence | Restore, leave the report, return to History, reopen the workout | The updated active time persists and the history row reflects it |
| Session isolation | Complete a second workout and restore only the first | Second workout's timings and route remain unchanged |
| Route and HealthKit | For an outdoor workout, inspect GPS route and HR/quantity report before and after Restore | Raw samples remain intact; report recalculates using the restored active windows; no artificial GPS jump |
| Repeated restore | Restore an interval and attempt to restore the same already-restored time | The interval is not offered again and cannot be counted twice |
| Invalid range | Select identical start/end times | Restore action is disabled |
| No pause | Open a completed workout with no pause intervals | Restore action is unavailable |
| Restart | Relaunch after Restore | The restored workout remains saved. **Undo after relaunch is not yet supported.** |
| Network offline | Repeat the history flow in WakTrainerDemo with network disabled | Local history and Restore remain usable |

## Build and device checks

- CI: main WakTrainer build and tests, WakTrainerDemo build, WakTrainerDeviceTest build.
- On a real device: verify HealthKit authorization, location accuracy, pause/resume tracking, backgrounding, and delayed HealthKit delivery.
- Verify the recorded pause start/end instants across time-zone changes and daylight-saving boundaries.
- Inspect history row, report duration, route, HR chart and summary values after Restore and Undo.

## Known limitations

- Undo token currently lives in the report view model and is lost on navigation dismissal or app restart. The restored workout itself is saved.
- SwiftData compare-and-replace is coordinated within its ModelContext; independent writers are not yet covered by a database-level versioned compare-and-swap.
- Live in-progress workout totals need separate paused-GPS partition verification; the completed report uses the DomainWorkout partitioning and quantity coverage rules.
- CI build success is not proof of device-level GPS or HealthKit behavior. Do not mark device checks as passed until observed.


## Integrated real-device acceptance: workout issues (FeatureWorkout #44, App #53)

Run on a physical iPhone with the **WakTrainer** scheme after this integration is merged.
WakTrainerDemo may use simulated health data and does not establish real HealthKit behavior.

1. **Live Activity:** Enable Live Activities for WakTrainer in iOS Settings, start a workout, lock the screen and verify a WakTrainer Live Activity is visible. Check Dynamic Island, elapsed time, exercise and completed sets. If absent, capture the `WakTrainer Live Activity` console message and verify the installed widget extension and entitlements.
2. **HealthKit:** In iOS Health data access settings, allow WakTrainer to read heart rate, active energy, steps and distance. Start a real workout while a supported source is writing samples. Verify readings update, or capture the new authorization/missing-sample warning. No HealthKit samples means **not verified**, even if CI passes. iPhone alone may not provide live heart-rate samples.
3. **Completed sets:** Record several sets, tap an earlier completed set, change reps and weight, save, switch screens, return and confirm edits persist. Confirm warm-up flag and units.
4. **Exercise catalog:** Search for Leg Extension, Hip Abduction, Pec Deck and T Bar Row. Toggle favorites, filter favorites only, sort by Most used and My order, drag to reorder, close and reopen to confirm preferences persist.
5. **Crash/relaunch recovery:** Begin a strength workout and record its time. Terminate the app, wait, reopen and choose Resume. Verify the restored elapsed time includes the gap since a recent running checkpoint (for example 8 minutes recorded, 22 minutes wall-clock) and continues increasing after Resume. Repeat with a deliberately paused workout and ensure the paused gap is not counted.
6. **Persistence:** End the workout and verify completed sets and timing in History. Check Restore/Undo of paused intervals separately.

### Known constraints
- A CI build cannot confirm on-device HealthKit sample production or Live Activity visibility.
- Frequency sorting counts exercise **selections**, not completed workout sessions.
- Recovery extrapolation is bounded to recent checkpoints and assumes no unrecorded pause during app termination. Manual verification is required before claiming full recovery reliability.
