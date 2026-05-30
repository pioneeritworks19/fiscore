# GitHub Issues: Mobile Deployment And V1 Billing

This is a point-in-time issue breakdown for preparing FiScore for Android/iOS deployment and then implementing the V1 RevenueCat subscription slice.

## Recommended Sequence

1. Finalize mobile app identity and assets.
2. Configure Firebase mobile apps and environments.
3. Complete mobile auth readiness, including Apple Sign-In.
4. Prepare store listings and review assets.
5. Build Android internal testing and iOS TestFlight pipeline.
6. Configure Apple/Google subscription products and RevenueCat.
7. Implement provider-neutral entitlement sync and billing history.
8. Implement app paywall, site limits, and admin read-only billing status.

## Issue 1: Finalize FiScore Mobile App Identity And Assets

### Goal
Prepare the mobile app identity and visual assets needed before creating App Store Connect and Google Play app records.

### Scope
- Decide final iOS bundle ID and Android application ID.
- Set app display name to `FiScore`.
- Set initial mobile version, for example `1.0.0+1`.
- Add production app icon source and generated iOS/Android launcher assets.
- Add splash/loading mark if needed.
- Confirm portrait-first orientation.
- Confirm app header/sign-in logo assets are bundled and referenced consistently.

### Acceptance Criteria
- iOS and Android app IDs are documented.
- App displays as `FiScore` on device.
- App icon renders correctly on iOS simulator/device and Android emulator/device.
- No dev-only app names, package IDs, or visible branding remain.
- `flutter analyze` passes.

## Issue 2: Configure Firebase Mobile Apps And Environment Flavors

### Goal
Make FiScore mobile builds point cleanly to the correct Firebase project for dev and production.

### Scope
- Add iOS app to Firebase with final bundle ID.
- Add Android app to Firebase with final application ID.
- Add `GoogleService-Info.plist` and `google-services.json`.
- Introduce or finalize dev/prod environment selection.
- Ensure store/TestFlight builds can target `fiscore-prod`.
- Confirm Firestore, Storage, Functions, and Auth use the intended project.

### Acceptance Criteria
- Dev build uses dev Firebase config.
- Prod/release build uses prod Firebase config.
- No hardcoded `fiscore-dev` assumptions remain in production paths.
- App launches and signs in against the intended Firebase project.

## Issue 3: Complete Mobile Auth Readiness

### Goal
Make authentication production-ready for mobile before app review and payment testing.

### Scope
- Implement Apple Sign-In for iOS release readiness.
- Verify Google Sign-In on Android and iOS.
- Verify email link sign-in on mobile.
- Verify invited staff can accept invite from email link on mobile.
- Verify pre-site/new-owner setup and staff join-team routing.
- Ensure profile/preferences are available before and after site setup.

### Acceptance Criteria
- Apple Sign-In works on iOS.
- Google Sign-In works on Android and iOS.
- Email link sign-in opens the app/browser flow correctly.
- Invited staff can join a tenant from mobile.
- App review can sign in using documented test instructions.

## Issue 4: Prepare Store Listings, Policies, And Review Metadata

### Goal
Prepare the App Store and Play Store materials needed for internal testing and later app review.

### Scope
- Draft app name, subtitle/short description, full description, and keywords.
- Prepare Privacy Policy URL.
- Prepare Terms of Service URL.
- Prepare Support URL/contact email.
- Prepare Apple privacy questionnaire and Google data safety answers.
- Prepare screenshot plan for iPhone and Android.
- Prepare app review notes and demo/test account instructions.

### Acceptance Criteria
- App Store Connect app record can be created without missing metadata.
- Play Console app record can be created without missing metadata.
- Privacy/Terms/Support links exist or are tracked as blockers.
- Review instructions explain the restaurant/site workflow clearly.

## Issue 5: Create Android Internal Testing And iOS TestFlight Build Pipeline

### Goal
Get FiScore installable on real devices before adding payment complexity.

### Scope
- Configure Android release signing and build app bundle.
- Configure iOS signing/team and archive build.
- Upload Android build to internal testing.
- Upload iOS build to TestFlight.
- Verify app startup, sign-in, site setup, camera/photo upload, training media, and action inbox on physical devices where possible.

### Acceptance Criteria
- Android internal test build is installable.
- iOS TestFlight build is installable.
- Core mobile workflows work outside Chrome.
- Known device-specific issues are documented.

## Issue 6: Configure Apple/Google Subscription Products And RevenueCat

### Goal
Create the store and RevenueCat product foundation for V1 mobile subscriptions.

### Scope
- Create Apple subscription group and annual products.
- Create Google Play subscription products/base plans.
- Recommended V1 products:
  - `fiscore_pro_1_site_annual` = `$99/year`
  - `fiscore_pro_2_sites_annual` = `$178/year`
  - `fiscore_pro_3_sites_annual` = `$257/year`
  - `fiscore_pro_5_sites_annual` = `$415/year`
- Create RevenueCat project/apps and connect Apple/Google.
- Create entitlement, for example `fiscore_pro`.
- Create RevenueCat offering/packages.
- Decide trial length and configure introductory/trial behavior if using store-managed trial.

### Acceptance Criteria
- RevenueCat can see Apple and Google products.
- RevenueCat offering exposes the expected annual packages.
- Product IDs are documented and match app configuration.
- Sandbox/test purchases can be initiated in development.

## Issue 7: Implement Provider-Neutral Entitlement Sync

### Goal
Keep FiScore entitlement state in Firestore independent of Apple, Google, RevenueCat, or future Stripe.

### Scope
- Add/confirm tenant entitlement fields:
  - `subscriptionStatus`
  - `subscriptionPlan`
  - `trialStartedAt`
  - `trialEndsAt`
  - `entitlementProvider`
  - `entitlementSnapshot`
  - `entitlementOverride`
- Add RevenueCat webhook Cloud Function.
- Verify webhook secret.
- Resolve RevenueCat `app_user_id` to FiScore user and tenant.
- Update tenant entitlement snapshot.
- Write billing event history.
- Make webhook idempotent by provider event ID.

### Acceptance Criteria
- RevenueCat sandbox purchase updates tenant entitlement snapshot.
- Renewal/cancellation/expiration events update tenant state correctly.
- Billing events are written for audit/debugging.
- Firestore rules protect entitlement fields from client writes.

## Issue 8: Implement Paywall, Site Limits, And Admin Read-Only Billing Status

### Goal
Enforce V1 subscription behavior in the app while keeping admin billing read-only.

### Scope
- Add Billing screen under More for owner/admin.
- Show read-only subscription/entitlement status in admin web.
- Gate adding second site behind upgrade.
- Gate trial-expired tenants behind upgrade/owner action.
- Staff users see “ask owner/admin to upgrade,” not purchase controls.
- Owner/admin can open RevenueCat purchase flow.
- App refreshes entitlement after purchase.
- Support manual early adopter/promo entitlement override.

### Acceptance Criteria
- Tenant can use one site during trial.
- Paywall appears when trial expires.
- Paywall appears when adding a second site without sufficient site entitlement.
- Owner/admin can purchase/upgrade using RevenueCat.
- Staff cannot purchase but sees a clear message.
- Admin web shows subscription state read-only.
- Early adopter override can grant temporary access without store purchase.

