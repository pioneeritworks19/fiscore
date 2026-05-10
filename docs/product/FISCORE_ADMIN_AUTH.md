# FiScore Admin App Authentication

## Purpose

This document defines the recommended authentication and authorization model for the FiScore Admin App.

The goal is to keep the Admin App:

- internal-only
- restricted to Pioneer IT Works employees
- aligned with the existing internal access model used for the Ops Console
- simple to operate and offboard over time

## Recommendation Summary

The recommended model for the FiScore Admin App is:

1. Google Sign-In only
2. access controlled primarily by Google Group membership
3. optional `@pioneeritworks.com` domain check as a defense-in-depth guardrail
4. Firebase custom claims used for Admin App roles and downstream authorization

This is the best fit for FiScore because it gives the team:

- consistent internal access control across internal apps
- centralized offboarding
- minimal custom credential management
- clear role enforcement inside Firebase-oriented product systems

## Why Group Membership Should Be the Primary Gate

Group membership is stronger than domain-only restriction.

### Domain-only check

Domain-only access means:

- any user with a `@pioneeritworks.com` identity could potentially sign in

That may be broader than intended.

### Group-based check

Group-based access means:

- only explicitly approved internal users can sign in to the Admin App

That is better for:

- least-privilege access
- cleaner onboarding and offboarding
- internal governance
- separation between general employees and FiScore internal admins

## Recommended Access Model

### Sign-In Provider

The FiScore Admin App should use:

- Google Sign-In only

Version 1 should not enable public providers such as:

- email/password
- Apple
- anonymous auth
- phone auth

The Admin App is an internal product, so a single enterprise-style sign-in path is preferable.

### Primary Eligibility Rule

A user should be allowed into the Admin App only if they are a member of an approved Google Group.

Recommended starting group:

- `fiscore-admins@pioneeritworks.com`

Possible future groups:

- `fiscore-content-admins@pioneeritworks.com`
- `fiscore-support-admins@pioneeritworks.com`
- `fiscore-product-admins@pioneeritworks.com`

Version 1 can begin with a single group and expand later if needed.

### Secondary Guardrail

The system may also verify that the user email ends with:

- `@pioneeritworks.com`

This should be treated as a secondary guardrail rather than the primary control.

Why keep it:

- it is cheap to validate
- it protects against accidental policy drift
- it makes the intended trust boundary explicit

Why it should not be the main gate:

- group membership is the stronger and more precise access control

## Alignment with Ops Console

The Admin App should use the same internal identity pattern as the Ops Console wherever practical.

That means:

- internal Google identity
- approved internal group membership
- internal-only access posture

The reason to align them is simple:

- one internal access model
- easier offboarding
- lower operator confusion
- fewer special cases to maintain

The apps remain separate product surfaces, but their internal identity approach should stay consistent.

## Authentication Flow

Recommended flow:

1. user opens the FiScore Admin App
2. user signs in with Google
3. backend or privileged admin auth logic verifies:
   - email is verified
   - user belongs to an approved Google Group
   - optionally email domain is `@pioneeritworks.com`
4. system issues or refreshes Firebase custom claims
5. app grants access only if required claims are present

If any check fails, access should be denied and the user should see an internal-access-only message.

## Authorization Model

Authentication proves identity.

Authorization should be handled through Firebase custom claims and product-side role checks.

Recommended claims:

- `internal_admin: true`
- `admin_app_access: true`
- `admin_role: content_admin | product_admin | support_admin | super_admin`

These claims should be used to secure:

- Admin App screen access
- Firestore access rules for admin-only records
- callable functions or admin endpoints
- publish/version actions
- tenant support actions

## Recommended Role Model

### content_admin

Can:

- create and edit library drafts
- preview content
- publish checklist and training versions

### support_admin

Can:

- inspect tenant-linked library content state
- view update availability
- help diagnose tenant content sync questions

### product_admin

Can:

- do everything `content_admin` can do
- manage broader product configuration
- manage internal content governance settings

### super_admin

Can:

- perform all Admin App actions
- manage internal role assignment tooling if implemented

## Recommended Technical Pattern

### Firebase Authentication

Use Firebase Authentication as the login/session mechanism for the Admin App because it aligns well with:

- Flutter web or internal web delivery
- Google Sign-In
- Firestore and Firebase-backed product data

### Group Membership Verification

The app should not trust client-side email checks alone.

Group membership validation should happen through privileged backend logic, for example:

- admin backend endpoint
- Cloud Function using Google Admin SDK or equivalent enterprise identity integration
- existing internal auth middleware if the Ops Console already has a reusable pattern

The key principle is:

- group membership must be verified server-side or through trusted admin logic

### Custom Claims Issuance

Once eligibility is verified, the system should set or refresh Firebase custom claims for the user.

Those claims should be treated as the runtime authorization source inside the Admin App.

This allows the app and Firestore rules to enforce access consistently without needing to query Google Group membership on every screen render.

## Firestore Authorization Expectations

If the Admin App reads or writes admin-only Firestore collections, Firestore rules should rely on claims rather than UI hiding alone.

Recommended pattern:

- allow access only when `internal_admin == true`
- restrict more sensitive writes further by `admin_role`

UI gating is helpful for experience, but server-side and Firestore-side checks must be the real enforcement.

## User Experience Recommendations

### Allowed user

If the user is approved:

- sign in should feel normal and low-friction
- the Admin App should load immediately after claim validation

### Disallowed user

If the user is not approved:

- show a clear internal-only message
- do not leak app details
- explain that access is restricted to approved FiScore internal administrators

Example:

- `This application is restricted to approved FiScore internal administrators.`

## Operational Recommendations

### Group administration

Use the Google Group as the main operational control point for:

- adding admins
- removing admins
- emergency access removal

This is easier than hardcoding user lists into the app.

### Offboarding

Offboarding should primarily mean:

- remove user from approved group
- optionally revoke or refresh claims if immediate lockout is needed

### Auditability

Sensitive Admin App actions should still be logged separately from auth itself, especially:

- library publish actions
- tenant support mutations
- role-sensitive configuration changes

## Version 1 Recommendation

Version 1 should use this exact rule set:

1. Google Sign-In only
2. require membership in `fiscore-admins@pioneeritworks.com`
3. optionally require `@pioneeritworks.com` domain as a guardrail
4. issue Firebase custom claims for Admin App access and role
5. enforce role checks in app, Firestore rules, and privileged backend actions

This is a strong, simple, and maintainable version 1 model.

## What Not to Do

Avoid:

- relying only on UI hiding for admin access
- relying only on client-side email domain checks
- using email/password for this internal app
- treating domain membership alone as the full authorization rule
- maintaining a manual hardcoded user allowlist when a managed internal group can do the job better

## Final Recommendation

The FiScore Admin App should use the same internal identity model as the Ops Console:

- Google identity
- internal group-based access
- role-based authorization

The main gate should be Google Group membership.

The domain check should be optional defense-in-depth, not the primary control.
