# FiScore Mobile App Identity

This document records the V1 mobile identity decisions for App Store Connect,
Google Play, and Firebase mobile app configuration.

## Environments

FiScore mobile supports separate dev and production identities. Daily app work
should continue against `fiscore-dev` until the production Firebase mobile apps
are created.

| Environment | Purpose | Android application ID | iOS bundle ID | Display name | Firebase |
| --- | --- | --- | --- | --- | --- |
| Dev | Daily development and internal testing | `com.pioneeritworks.fiscore.dev` | `com.pioneeritworks.fiscore.dev` | FiScore Dev | `fiscore-dev` |
| Prod | Store release | `com.pioneeritworks.fiscore` | `com.pioneeritworks.fiscore` | FiScore | Future Firebase prod mobile apps |

## Shared App Identity

| Platform | Value |
| --- | --- |
| Android namespace | `com.pioneeritworks.fiscore` |
| Initial version | `1.0.0+1` |
| Primary orientation | Portrait |

## Branding Assets

| Usage | Asset |
| --- | --- |
| Sign-in and setup brand lockup | `apps/fiscore_app/assets/branding/fiscore_lockup.png` |
| App header wordmark | `apps/fiscore_app/assets/branding/fiscore_header.png` |
| Launcher icon source and compact mark | `apps/fiscore_app/assets/branding/fiscore_mark.png` |

The generated iOS and Android launcher icon assets are derived from the FiScore
mark with a white background so the icon renders cleanly across platform masks.

## Follow-Up

The Firebase Android and iOS app configuration files must be generated for the
production IDs above before store builds are submitted. The existing Android dev
config lives at:

`apps/fiscore_app/android/app/src/dev/google-services.json`

iOS dev/prod Firebase plist wiring should be completed in the Firebase mobile
setup issue.

## Useful Commands

Run the Android dev app:

```powershell
flutter run --flavor dev -t lib/main.dart
```

Build Android for production after Firebase prod mobile config exists:

```powershell
flutter build appbundle --flavor prod -t lib/main.dart
```

For iOS, the current Xcode Debug configuration uses the dev bundle ID and the
Release/Profile configurations use the production bundle ID. Dedicated iOS
schemes and Firebase plist selection should be completed in the Firebase mobile
setup issue.
