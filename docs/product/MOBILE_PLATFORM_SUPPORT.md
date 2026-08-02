# FiScore Mobile Platform Support

## Purpose

This document defines the recommended platform support policy for the FiScore mobile application.

It covers:

- Android support policy
- iPhone and iPad support policy
- recommended Flutter version
- team version pinning approach
- practical version 1 guidance for QA and release management

The goal is to keep FiScore support practical and stable for a business application rather than trying to maximize theoretical device reach.

## Recommendation Summary

For FiScore version 1, the recommended mobile support policy is:

- **Android:** Android 10 and above
- **iOS/iPadOS:** iOS 16 and above
- **Flutter:** Flutter `3.41.6` stable
- **Version pinning:** use `FVM` for local development and CI

This is the recommended product support range, not merely the broadest technical range Flutter can build for.

## Technical Support vs Product Support

There is an important difference between:

- what Flutter can technically build for
- what FiScore should officially support as a product

Flutter may technically support older operating system versions, but supporting those older versions increases:

- testing scope
- plugin compatibility risk
- UI inconsistency
- device-performance issues
- bug triage cost

FiScore is a professional operational app, so the support policy should favor stability and consistency over maximum backward compatibility.

## Recommended Version 1 OS Support

### Android

Recommended minimum supported version:

- **Android 10**
- **API level 29**

Why:

- reduces fragmentation from older Android behavior
- keeps permission, storage, and background behavior more consistent
- better fit for business-managed and newer restaurant devices
- lowers QA burden for offline-first and media workflows

### iPhone and iPad

Recommended minimum supported version:

- **iOS 16**

Why:

- strong current-device coverage
- simpler plugin and platform behavior
- fewer edge cases around permissions, media handling, and web authentication
- better long-term support position for a new product

## Alternative Broader Support Option

If the team later learns that many real customers are on older hardware, a broader compatibility policy could be:

- **Android 8 or 9 and above**
- **iOS 15 and above**

That is acceptable if market reality requires it, but it should be treated as a conscious product decision rather than the default.

For version 1, the cleaner recommendation remains:

- Android 10+
- iOS 16+

## Device Strategy Implications

This platform policy aligns well with the FiScore device strategy:

- phone-first for execution
- tablet-strong for audits and operational review
- browser-friendly for management workflows

See:

- [DEVICE_STRATEGY.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\DEVICE_STRATEGY.md)

## Flutter Version Recommendation

Recommended Flutter version:

- **Flutter `3.41.6` stable**

Why:

- current stable release guidance is the safest production choice
- stable channel reduces framework churn risk
- better team consistency than letting each machine choose its own version
- avoids accidental mismatch between developer machines and CI

## Version Pinning Recommendation

The team should pin Flutter with:

- **FVM**

Why:

- predictable local setup
- easy onboarding
- consistent CI builds
- easier future upgrades with explicit project versioning

Recommended policy:

- project pins one Flutter version
- all local developers use that pinned version
- CI uses the same pinned version
- upgrades happen intentionally, not ad hoc

## Suggested Version 1 Tooling Policy

### Flutter

- use `Flutter 3.41.6`
- use the stable channel
- pin through FVM

### Dart

- use the Dart SDK bundled with the pinned Flutter version

### Android

- compile with the current recommended Android SDK for the pinned Flutter release
- support product minimum at Android 10 / API 29

### iOS

- support product minimum at iOS 16
- keep Xcode aligned with the Flutter version in active use

## Windows vs macOS Development Note

FiScore development can be split across platforms, but iOS build realities remain important.

### Windows

Good for:

- Flutter development
- Android development
- web development
- Firebase and local app workflows

Not sufficient for:

- building and signing iOS apps
- running Xcode-based iOS workflows

### macOS

Required for:

- iOS builds
- iOS signing
- App Store submission workflows

So the practical team setup is:

- Windows can be fine for Flutter + Android work
- at least one macOS environment is still required for iOS delivery

## QA Recommendation

Version 1 QA should not try to cover a huge device matrix.

Recommended minimum QA coverage:

### Android

- one modern small phone
- one larger Android phone
- one Android tablet if tablet audit workflows matter in version 1

### iPhone/iPad

- one current iPhone size class
- one older-but-supported iPhone size class
- one iPad if tablet audit workflows are important in version 1

The goal is representative coverage, not exhaustive device coverage.

## Release Policy Recommendation

The team should define support policy in three layers:

### 1. Build support

What the codebase can technically compile and run on.

### 2. Official support

What FiScore will publicly support and QA.

### 3. Best experience target

The device and OS range where the product is expected to feel strongest.

Recommended version 1 mapping:

- build support: aligned with Flutter technical limits where practical
- official support: Android 10+, iOS 16+
- best experience target: newer phones and tablets used in active restaurant operations

## Future Review Points

This policy should be revisited when:

- real tenant device data becomes available
- field usage shows older OS dependence
- a plugin or platform dependency requires support changes
- the product expands heavily into tablet-specific workflows

## Final Recommendation

For FiScore version 1:

- support **Android 10+**
- support **iOS 16+**
- use **Flutter 3.41.6 stable**
- pin the version with **FVM**

This gives FiScore a stable, professional, and manageable foundation for mobile development without overextending QA and support effort.
