# FiScore Onboarding Flow

## Purpose

This document defines the recommended first-run and onboarding experience for FiScore version 1.

The onboarding flow is critical because it establishes:

- tenant creation
- initial user role assignment
- first site setup
- public inspection import for linked sites
- the user's first landing experience inside the app

This document should be read alongside:

- [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- [USER_ROLES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\USER_ROLES.md)
- [APP_NAVIGATION.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\APP_NAVIGATION.md)

## Version 1 Onboarding Principles

### 1. Onboarding Should Feel Guided

Users should not be dropped into an empty app without direction.

The onboarding should clearly guide them through:

- sign in
- create tenant
- add first site
- land in the right first screen

### 2. Linked Site Is Preferred, Manual Site Is Fully Supported

FiScore should encourage users to search and link a site from master restaurant data first.

However:

- manual site creation must remain a first-class supported path
- it should not feel like an error recovery path
- it should not block the tenant from starting to use the app

### 3. First Value Should Arrive Quickly

Users should feel progress early.

The onboarding should help them get to one of these outcomes quickly:

- view public inspection history for a linked site
- review active imported violations from the latest inspection
- start an internal audit for a newly created site

### 4. Tenant Switching Is Not A Version 1 Onboarding Concern

For version 1, the app should behave as one active tenant.

The onboarding should assume:

- the user is entering one tenant context
- there is no tenant switcher yet

### 5. Site Count Should Affect Landing, Not Permissions

If the user has:

- one accessible site, the app may open that site directly
- more than one accessible site, the app should start at the site summary list

However:

- users with permission to add sites should still see `Add Site`
- site-management entry points should remain visible based on role, not current site count

## High-Level Onboarding Flow

```text
Open App
-> Welcome
-> Sign in with Google or Apple
-> Create Tenant
-> User becomes tenant_owner
-> Add First Site
   -> Search and link from master restaurant data
      -> Import public inspection history
      -> Create latest public-inspection violations
   OR
   -> Add Site Manually
-> Onboarding complete
-> First landing
   -> one site: Site Dashboard
   -> multiple sites: Sites Summary List
```

## Detailed Flow

## 1. App Open and Welcome

### Goal

Introduce FiScore clearly and move the user quickly into authentication.

### Recommended screen content

- FiScore name and positioning
- short value summary
- `Continue with Google`
- `Continue with Apple`

### Suggested product message direction

FiScore helps restaurant teams:

- review public inspection history
- run internal audits
- track violations
- document remediation
- improve future inspection outcomes

## 2. Authentication

### Goal

Authenticate the user with the supported providers.

### Supported providers

- Google Sign-In
- Sign in with Apple

### Result

- Firebase Authentication user exists
- FiScore can now determine whether this is a first-run tenant owner flow or an existing-user flow

## 3. Tenant Creation

### When this step appears

Show this step when the authenticated user does not yet belong to a tenant in version 1.

### Goal

Create the tenant and establish the first tenant owner.

### User inputs

Recommended version 1 inputs:

- tenant or business name
- optional default timezone if needed

### System actions

FiScore should:

1. create the tenant record
2. create the tenant membership for the current user
3. assign role `tenant_owner`

### Result

- `tenant` exists
- `tenant_owner` exists
- the app transitions directly into first-site setup

## 4. First Site Setup

### Goal

Help the user add their first operating site into the tenant.

### Recommended step framing

The user should be shown a clear choice sequence:

1. search for site in FiScore master restaurant data
2. if not found, add the site manually

This should be presented as one guided flow with two supported paths.

## 4A. Linked Site Path

### Goal

Create the first site by linking it to a master restaurant record.

### User steps

1. user enters zip code
2. FiScore searches master restaurant data
3. user filters or searches by restaurant name
4. FiScore shows candidate matches
5. user selects the correct site

### System actions

FiScore should:

1. create the tenant site record
2. link the tenant site to the master restaurant record
3. import all historical public inspections for that site
4. copy public findings into the site inspection history
5. automatically create tenant violations only for findings from the most recent public inspection

### Result

- first site exists
- public inspection history is visible
- latest public inspection issues are actionable as tenant violations

### Important product rule

Only the latest public inspection findings should auto-create tenant violations during onboarding.

Older findings should remain visible historically without becoming active by default.

### Security Hardening TODO

Before production launch, the master restaurant search endpoint used by onboarding must be hardened against enumeration and scraping:

- require Firebase Auth and active tenant membership
- require Firebase App Check from supported app clients
- log every search with user ID, tenant ID, search text, result count, and timestamp
- rate-limit by user, tenant, and request origin
- require meaningful search text and avoid broad unbounded searches
- cap result count and do not expose pagination for onboarding search
- return only tenant-safe fields needed for matching
- monitor repeated searches that look like master-data enumeration
- keep raw master data access server-side only

## 4B. Manual Site Path

### Goal

Create the first site without a master restaurant link.

### When this path appears

Show this path when:

- search produced no reliable result
- the user cannot find the correct site
- the user chooses manual entry

### User inputs

Recommended version 1 inputs:

- site name
- address line 1
- city
- state
- zip code
- timezone

### System actions

FiScore should:

1. create the tenant site record
2. mark it as manual and unlinked
3. make audits, violations, and later team workflows available immediately

### Result

- first site exists
- tenant can start using FiScore right away
- public inspection history remains unavailable until the site is linked later

### Important product rule

Manual site creation must be treated as a valid operating path, not as a failed onboarding path.

## 5. Onboarding Completion

### Goal

Confirm that the tenant is ready to begin daily work.

### Recommended completion summary

The completion state should make it clear:

- tenant was created
- first site was added
- public history was imported if linked
- the user can now enter the app

### Suggested completion messaging direction

Examples:

- `Your FiScore workspace is ready.`
- `Your first site has been added.`
- `Inspection history is available for review.` when linked
- `You can start your first internal audit now.` when manual or no public data is available

## 6. First Landing Behavior

### Version 1 recommendation

After onboarding:

- if the user has access to exactly one site, open that site directly
- if the user has access to more than one site, open the `Sites` summary list

### Important role-based behavior

Even if the user currently has only one site:

- users with permission to add sites should still see `Add Site`
- site-management entry points should remain visible

This is important because a tenant owner or admin may start with one site and expand later.

## 7. First-Run Entry Points After Onboarding

Once the user is inside the app, the likely next destinations are:

- review latest public inspection
- review imported violations from the latest inspection
- start internal audit
- add another site if permitted

These entry points should be visible from:

- site dashboard
- site summary list
- header or `More` navigation for site management

## Recommended Screen Sequence

Recommended version 1 first-run sequence:

1. Splash
2. Welcome
3. Sign in
4. Create Tenant
5. Add First Site
6. Linked or Manual Site Confirmation
7. First App Landing

## Onboarding Branching Summary

### New Tenant Owner

```text
Welcome
-> Sign in
-> Create Tenant
-> Add First Site
-> Finish
-> Site Dashboard or Sites List
```

### Linked Site Branch

```text
Add First Site
-> Search by zip
-> Search by name
-> Select master match
-> Create site
-> Import inspections
-> Create latest violations
-> Finish
```

### Manual Site Branch

```text
Add First Site
-> Search fails or user chooses manual
-> Enter site details
-> Create manual site
-> Finish
```

## Recommended Empty-State Behavior

If the user somehow completes authentication and tenant creation but does not complete site setup:

- FiScore should not drop them into the full app experience
- FiScore should return them to `Add First Site`
- the UI should make it clear that site setup is required before normal workflows begin

## Future Enhancements

Potential later onboarding improvements:

- invite teammates during onboarding
- select and enable FiScore system checklist templates during onboarding
- choose whether to import inspection history immediately or in background
- link a manual site later as a guided follow-up
- future tenant switcher for users who belong to multiple tenants

## Summary

FiScore version 1 onboarding should move the user through a clear and practical first-run sequence:

- authenticate
- create tenant
- add first site
- import public inspection history if linked
- land in the correct site-aware home experience

The onboarding should prefer linked sites when possible, fully support manual sites when needed, and preserve a strong path to first value without making the user feel blocked by missing master data.
