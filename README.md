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


## Free Personal Team Preview

The `preview/free-personal-team` branch mirrors the current `main` app UI and feature integration while keeping a signing configuration that can be installed with a free Personal Team.

In this preview branch:

- Access Wi-Fi Information is not requested.
- Place recognition uses GPS-only behavior through a no-op Wi-Fi provider.
- New place registrations are saved without Wi-Fi identity information.
- The preview entitlement file remains empty for free Personal Team signing.
- Production `main` keeps the full Wi-Fi-enabled configuration unchanged.
