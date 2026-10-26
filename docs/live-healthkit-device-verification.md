# Live HealthKit workout verification (real iPhone)

## Scope

This is a **manual device verification plan**, not a claim that a real-device run has already passed.
The app now consumes the merged WakTrainerFeatureWorkout and WakTrainerServiceHealthKit changes for original measurement timestamps, anchored-query duplicate/deletion reconciliation, and observation-session isolation.

Use a signed **WakTrainer** build on an iPhone with Health access enabled. The simulator and Wi-Fi-free demo cannot validate real HealthKit delivery timing.

## Preparation

1. Install the branch build on an iPhone and grant the requested Health read permissions.
2. Record the current device timezone and date; keep the Health app available to inspect measurements.
3. Use an exercise that provides live heart rate and steps. Do not change or delete personal Health records merely to perform this test.
4. Note the initial steps/calories and current time before each run.

## Scenarios

| ID | Action | Expected result |
| --- | --- | --- |
| HK-01 | Start walking or running; observe heart rate, steps, calories and distance | Values update from live HealthKit samples; measurement timestamps represent acquisition time, not UI refresh time |
| HK-02 | End the workout; wait for late HealthKit delivery | Ended workout values do not continue to change |
| HK-03 | Immediately start a second workout after HK-02 | New session starts without carrying over previous workout live totals or stale heart rate |
| HK-04 | Repeat start → end → start rapidly at least three times | No previous observation stream terminates the newest workout; no cross-session callback contamination |
| HK-05 | Pause and resume an active workout | No duplicate accumulation attributable to repeated anchored-query callbacks; check existing pause semantics separately |
| HK-06 | Allow HealthKit samples to arrive late or out of order | Latest heart rate follows latest sample acquisition end date, not callback arrival order |
| HK-07 | Change device timezone after saving a workout; reopen the calendar | Original stored instants remain unchanged; calendar day grouping follows current timezone |
| HK-08 | Save a workout, restart the app and open workout history | Saved timestamps and recorded values remain stable |

### Important limits

- Deletion reconciliation and UUID deduplication have automated accumulator tests. Real HealthKit deletion events are **not** verified by this checklist unless a naturally occurring event can be observed safely.
- The app may combine live values with recovered checkpoint baselines. Verify each workout against its own starting baseline rather than assuming a global zero.
- Do not infer UTC correctness from a formatted clock alone: compare the same absolute instant before/after timezone changes.
- Any CI build/test success only proves simulator/build integration; it does not prove HK-01 through HK-08.

## Reporting

For each scenario record **PASS / FAIL / NOT TESTED**, device model, iOS version, app commit SHA, Health permissions, timezone, observed vs expected values, and reproducible steps for failures.

If a scenario fails, preserve the test details and address it in a separate feature branch and PR. Do not modify merged branches directly.
