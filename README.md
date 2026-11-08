# WakTrainer App

WakTrainer is the iOS application target that composes the WakTrainer feature, domain, service, calendar, place-recognition, authentication, and profile packages.

## Design System

The app uses [WakTrainerDesignSystem](https://github.com/iosdevbyul/WakTrainerDesignSystem) as the shared presentation foundation.

App-owned screens use the design system for:

- semantic colors
- typography
- spacing and corner radii
- cards and metric presentation
- shared primary and secondary buttons

The initial app integration applies the WakTrainer dark visual language to Home, calendar, reports, profile, body profile, navigation chrome, and the app accent color while preserving the existing workout, persistence, location, authentication, and domain flows.

Feature-specific behavior remains in its owning package. The app consumes reusable presentation primitives without moving business logic into the design system.

## Localization

English remains the source/default language. Korean strings are supplied through the app localization resources and are shown when the user selects Korean for WakTrainer in iOS language settings.

## Share workout history to TrisDashboard

The app's navigation toolbar now has an **Export workout history as JSON** action. Tapping it reloads the current signed-in owner's completed workouts from local persistence, validates their durations and summary distances, and creates a private temporary `waktrainer-dashboard-*.json` file in TrisDashboard v2 format. A native iOS share sheet lets you save it to Files or AirDrop it to your MacBook. The app never automatically uploads workout data, and the export intentionally excludes detailed GPS tracks, heart-rate samples and owner profile identifiers. After dismissing the share sheet the temporary file is deleted; save a copy before closing it.

On the MacBook, run `.venv/bin/python -m macos.preview_workouts --input ~/Downloads/waktrainer-dashboard.json --output ~/tris-private/fitness.json` and then `.venv/bin/python -m macos.import_waktrainer --input ~/Downloads/waktrainer-dashboard.json --output ~/tris-private/fitness.json --merge` using the actual received file path. The export keeps the stable workout UUID so repeated imports deduplicate correctly. No background transfer or iCloud permissions are added by this feature.
