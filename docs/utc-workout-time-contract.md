# Workout time contract (UTC canonical, viewer-local presentation)

## Immutable instants
- Every workout start/end, sensor sample, GPS fix, HR sample, workout stage, and point-in-time measurement must retain its original absolute timestamp. Persist as a Swift `Date` (absolute instant), or serialize an unambiguous UTC Unix timestamp / ISO 8601 with `Z`; define and enforce milliseconds vs seconds per API field.
- Store **measuredAt / collectedAt** separately from **receivedAt / ingestedAt / uploadedAt**. A server receiving historical samples later must never replace their acquisition time with its receive time.
- Sorting, elapsed durations, deduplication, server synchronization, and replay use the immutable instants; never add/subtract a timezone offset from the original timestamp.
- Durations are actual elapsed intervals, not wall-clock date differences.

## Viewer-local display
- Dates and clock labels in calendar, workout details, charts, and reports are derived from the **current viewing device timezone**. Changing from Asia/Seoul to America/Vancouver may legitimately move the same workout onto the previous calendar date.
- Day/week/month aggregations and selection filters must compute local boundaries with the same viewing timezone. Rebuild derived date buckets when the timezone changes. Never persist a timezone-derived day key as the only source of truth.
- Respect DST: a civil day can span 23 or 25 hours. Do not use `24 * 3600` to advance calendar days or build local-day filters.
- A workout spanning local midnight must have a documented allocation policy (start-day or segmented duration); aggregation must not silently drop its measurements.

## Validation matrix
1. Seoul to Vancouver and back, with events close to midnight in each zone.
2. Vancouver and Toronto timezones, including DST spring-forward and fall-back.
3. Sensor measurement and delayed server ingestion separated by one or more days; original measurement time unchanged.
4. Local Only: capture offline, restart, move timezone, then replay pending records with the original UTC timestamps and stable record identity.
5. Calendar highlighted dates, date selection, workout history, charts, and week/month summaries agree for the same current timezone.
6. API request/response formats document timestamp units and timezone semantics; reject ambiguous local-time strings.

## Implementation scope
This PR introduces explicit policy documentation, small Foundation date helpers, and DST/timezone regression tests. It does **not** yet certify every field in external SPMs or the backend. Follow-up audits and fixes must cover WakTrainerCoreModels, WakTrainerFeatureWorkout/WorkoutHistoryStore, WakTrainerServer and storage/API serialization before claiming end-to-end compliance.
