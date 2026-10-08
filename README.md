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
