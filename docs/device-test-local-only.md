# WakTrainerDeviceTest (personal Apple development team)

This scheme runs the real **AuthenticationRootView** and account-scoped workout flows without requesting the restricted Access Wi-Fi Information entitlement. The existing WakTrainer and WakTrainerDemo targets are unchanged.

## Build and install

1. Merge this PR and update local main, or check out this PR branch for testing before merge.
2. Keep Mac and iPhone on the same trusted Wi-Fi. Start TrisAuthenticationServer on port 8080 and WakTrainerServer on port 8081 with `--hostname 0.0.0.0`.
3. In `Config/DeviceTest-Info.plist`, confirm the Mac LAN IP (currently `192.168.1.100`); change it locally if your Mac IP changes, without committing your machine-specific settings.
4. Open `WakTrainer.xcodeproj`, choose the `WakTrainerDeviceTest` scheme and a physical iPhone, select your own personal development team, and run.
5. Sign in online with **Auto Login enabled**, use Profile to activate Local Only, stop both servers, terminate and relaunch the app, then record a workout and check the calendar/reports.
6. Restart servers and select Server mode to test pending upload retries.

## Boundaries

- Uses the device-test bundle ID `com.tris.WakTrainerDeviceTest`. Its app container and authentication persistence are separate from the regular WakTrainer and Demo installations.
- Uses the existing Demo entitlements (HealthKit only); no Wi-Fi Information entitlement.
- Uses the DemoWiFiProvider only for the Wi-Fi-dependent place-recognition feature; **not** the Demo authentication bypass.
- Does not embed a workout widget extension in this target. Live Activity / widget verification requires a separate signing-capability review.
- The device-test Info.plist temporarily allows HTTP for local development, **never** use this configuration as a distribution or production build.
- CI tests simulator compilation. Physical signing, LAN connectivity, backend-off session restoration and workout sync require manual device verification.
