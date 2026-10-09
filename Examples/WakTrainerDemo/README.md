# WakTrainerDemo

The `WakTrainerDemo` Xcode target runs directly from the repository's `main` branch.

- Select the `WakTrainerDemo` scheme in `WakTrainer.xcodeproj`.
- Reuses app UI and workout implementation in `WakTrainer/`.
- Uses `WAKTRAINER_DEMO` to inject a no-network Wi-Fi provider and GPS-constrained place recognition.
- Uses a separate app bundle ID, HealthKit capability, and demo Widget Extension bundle ID.
- Does **not** request Access Wi-Fi Information entitlement.
- Build both targets before merging PRs.
- For Personal Team signing, select your development team for the demo app and Widget Extension. Entitlements and provisioning eligibility must be validated on your device.

The production app retains its normal Wi-Fi recognition behavior.
