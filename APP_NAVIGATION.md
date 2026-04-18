# FiScore App Navigation

## Purpose

This document defines the recommended navigation structure for the FiScore tenant-facing application.

The goal is to create a navigation model that is:

- mobile-first
- easy to understand for restaurant operators
- optimized for the most common daily tasks
- aligned with the one-restaurant-at-a-time product model
- flexible enough to support role-based access

This document covers:

- top-level information architecture
- mobile navigation recommendations
- web navigation recommendations
- screen hierarchy
- role-based visibility
- core user journeys

## Navigation Design Principles

### 1. One Restaurant at a Time

FiScore should always make the current restaurant context obvious. Users work inside one restaurant at a time and switch explicitly when needed.

This should not prevent the product from offering a tenant-level overview of all accessible restaurants. Users often need a portfolio snapshot before drilling into one location.

### 2. Daily Work First

The most frequent actions in the app are likely to be:

- reviewing active violations
- conducting audits
- checking recent inspections
- switching restaurant context

Navigation should prioritize those workflows over less frequent administrative areas.

### 3. Compliance Work Should Feel Structured

Public inspections, internal audits, and violations are closely related, but users think about them differently in daily work.

Because of that:

- public inspections should be visible as a reference/history area
- audits should be a task-oriented workflow area
- violations should be a top-level action area

### 4. Role Complexity Should Not Overcomplicate Navigation

Different roles should see different destinations where appropriate, but the overall app structure should stay consistent.

### 5. Mobile First, Web Adapted

The information architecture should stay consistent across platforms, while the web app can use a wider layout such as a sidebar.

### 6. Design for Expansion

FiScore should be designed as a restaurant operations platform, not only a food-safety tool. The navigation model should leave room for future modules such as:

- asset tracking
- complaint tracking
- additional operations or compliance modules

The initial navigation should therefore separate restaurant context from module context so the app can grow cleanly over time.

## Recommended Top-Level Sections

For version 1, the recommended top-level sections are:

- `Restaurants`
- `Dashboard`
- `Violations`
- `Audits`
- `Inspections`
- `More`

This keeps the most active daily workflows close at hand without overcrowding the primary navigation.

## Recommended Mobile Navigation

### Primary Pattern

Use a bottom tab navigation with five destinations:

1. `Restaurants`
2. `Dashboard`
3. `Violations`
4. `Audits`
5. `More`

### Why This Pattern

- bottom tabs are familiar for mobile users
- the most important daily destinations stay one tap away
- restaurant operations users benefit from simple, consistent navigation
- the `More` tab gives room for less-frequent destinations without making the main tab bar too busy

### Where Inspections Goes on Mobile

On mobile, `Inspections` should live under the restaurant dashboard and within `More`, rather than as a permanent bottom tab.

Reason:

- users need a restaurant portfolio view at the top level
- violations and audits are more action-oriented daily destinations
- inspections remain important, but they are more reference-oriented than violations in day-to-day use

## Recommended Web Navigation

### Primary Pattern

Use a left sidebar with the same information architecture:

- Restaurants
- Dashboard
- Violations
- Audits
- Inspections
- Assets
- Complaints
- Analytics
- Team
- Settings

### Why This Pattern

- the web app can support broader navigation density
- sidebar navigation works better for table-heavy and management-heavy screens
- the same conceptual structure can remain consistent with the mobile app

## Restaurant Context and Switching

### Recommendation

Restaurant switching should live in the top app header as a persistent restaurant context control once a user is inside a restaurant-specific module or screen.

### Recommended Pattern

- current restaurant name shown in the top header
- tapping it opens a restaurant switcher
- users only see restaurants they are allowed to access
- tenant owner and admin can see all restaurants in the tenant

### Why

- restaurant context is central to almost every workflow
- placing the switcher in the header keeps it visible without taking up a bottom-tab slot
- users should always know which restaurant they are currently operating in

### Restaurant Overview vs Restaurant Context

FiScore should support both:

- a tenant-level restaurant overview screen that shows all accessible restaurants with summary data
- a single active restaurant context for detailed work

This gives users a portfolio snapshot without losing the one-restaurant-at-a-time operating model.

## Recommended Default Landing Screen

### Recommendation

After login, the default landing experience should be:

- `Restaurants` overview if the user has access to multiple restaurants
- `Dashboard` for the last active restaurant if that is the preferred resume path later
- onboarding or add-restaurant flow if the tenant has no restaurants yet

### Why

- a restaurant overview gives users a cross-location snapshot
- it supports quick drill-down into one restaurant
- it creates a more scalable pattern as the tenant grows to multiple restaurants

## Recommended Entry Model

### 1. Restaurants Overview

This is the tenant-level landing area for selecting and scanning restaurants.

### 2. Restaurant Dashboard

This is the active-location operational home once a restaurant is selected.

This distinction is important because:

- overview is cross-restaurant
- dashboard is restaurant-specific

## 1. Restaurants

### Purpose

The Restaurants section is the portfolio-level landing experience. It shows all restaurants the user can access and provides a quick summary of health/compliance status.

### Recommended content

- restaurant cards or rows
- restaurant name and location
- latest inspection date
- latest inspection score or grade when available
- open violation count
- pending review count
- draft or recent audit indicator
- quick visual status cues

### Recommended actions

- open restaurant dashboard
- switch active restaurant
- add restaurant if permitted

### Why

- users need a portfolio snapshot before drilling into one restaurant
- this works especially well for owners, admins, and managers overseeing multiple sites
- it creates a strong foundation for future multi-module restaurant operations management

## Recommended Section Roles

## 2. Dashboard

### Purpose

The dashboard is the operational home screen for the currently selected restaurant.

### Recommended content

- restaurant summary
- latest public inspection summary
- active violation counts
- pending review count
- upcoming or recent audits
- quick actions

### Recommended quick actions

- start audit
- view open violations
- review latest inspection
- switch restaurant

## 2. Violations
## 3. Violations

### Purpose

Violations should be a top-level destination because they are one of the most actionable and time-sensitive parts of the product.

### Recommended screens

- violation list
- violation detail
- response editor
- attachments
- status history
- review actions for managers

### Why Top-Level

- violations are a daily action queue
- they combine public and internal findings into one operational workflow
- users should not need to drill through inspections or audits just to work on them

## 3. Audits
## 4. Audits

### Purpose

Audits should be a top-level destination because they represent a major active workflow, especially for auditors and managers.

### Recommended screens

- audit list
- start audit
- in-progress audit
- audit detail
- completed audit summary

### Audit Flow Layout Recommendation

Use a hybrid section-based audit experience:

- one section per screen or step
- grouped questions within the section
- clear next/previous progression
- persistent progress indicator

### Why

- better than one question per screen for medium and long checklists
- easier to manage than one giant scroll form
- works well offline
- helps users keep context while moving through an audit

## 5. Inspections

### Purpose

This section should provide access to public health department inspection history and findings for the current restaurant.

### Recommended screens

- public inspection list
- public inspection detail
- finding list within inspection
- report/PDF access where available

### Why Separate from Audits

- public inspections are external reference history
- audits are internal operational workflows
- users think about them differently, even though they are related

## 6. More

### Purpose

This area should contain lower-frequency destinations and role-based management areas.

### Recommended mobile items under `More`

- Analytics
- Inspections
- Assets later
- Complaints later
- Team
- Settings
- Profile
- Help or Support later if needed

### Why

- these are important but not primary daily-task destinations for most users
- grouping them here keeps the main mobile navigation focused

## Recommended Screen Hierarchy

## Authentication and Onboarding

- Login
- Tenant registration
- Restaurant setup prompt
- Add restaurant from master list

## Main App

- Restaurants overview
- Dashboard
- Violations
- Audits
- Inspections
- More

## Restaurants Branch

- Restaurants overview
- Restaurant detail entry point
- Add restaurant
- Restaurant switcher

## Dashboard Branch

- Dashboard
- Quick link to latest inspection detail
- Quick link to open violations
- Quick link to start audit

## Violations Branch

- Violation list
- Violation detail
- Edit response
- Attach evidence
- Submit for review
- Manager review actions

## Audits Branch

- Audit list
- Start audit
- In-progress audit
- Resume draft audit
- Submit audit
- Audit completion summary

## Inspections Branch

- Public inspection list
- Public inspection detail
- Inspection findings
- Linked tenant violation where applicable

## More Branch

- Analytics
- Assets
- Complaints
- Team management
- Settings
- Profile

## Recommended Role-Based Visibility

Navigation should be role-aware, but avoid making the app feel radically different per role.

### Dashboard

- visible to all tenant users with restaurant access

### Restaurants

- visible to all tenant users with restaurant access

### Violations

- visible to all tenant users with restaurant access

### Audits

- visible to manager and auditor
- optionally visible read-only to other roles if you later want audit history access

### Inspections

- visible to all tenant users with restaurant access

### Analytics

- visible to tenant owner, admin, manager, and auditor
- hidden from staff in version 1

### Team

- visible to admin and manager

### Settings

- visible to tenant owner and admin

## Recommended Visibility Behavior

For version 1, hidden role-restricted destinations should generally not appear in navigation rather than appearing as locked items.

### Why

- cleaner user experience
- less confusion for operational users
- easier mobile navigation

Locked-state screens can be added later if product strategy shifts toward feature discovery.

## Recommended Violation Review Pattern

### Recommendation

Use both:

- review actions inside the violation detail screen
- and a filtered review queue in the violation list

### Why

- managers need a fast way to see what requires review
- they also need full context in the detail view before closing, rejecting, or requesting more work

### Recommended implementation

- default list filters such as `Open`, `Pending Review`, `Closed`
- managers can jump into `Pending Review`
- final review decisions happen inside the violation detail screen

## Notifications and Inbox Recommendation

### Version 1 Recommendation

Do not make a separate notifications or inbox screen a core navigation destination in version 1.

Instead:

- use badges and counts on Dashboard and Violations
- use pending review summaries
- surface important items in dashboard cards

### Why

- keeps navigation simpler
- avoids creating a thin or underused inbox experience too early
- most needed alerts can be represented through existing workflow destinations

An inbox can be added later once notification volume and workflow complexity justify it.

## Team, Profile, and Settings Grouping

### Recommendation

On mobile:

- place Team, Settings, and Profile inside `More`

On web:

- Team and Settings can appear directly in the sidebar for eligible roles
- Profile can remain in the account menu or header menu

## Recommended Dashboard Card Model

The dashboard should likely include:

- `Current Restaurant`
- `Latest Inspection`
- `Open Violations`
- `Pending Review`
- `Recent or Draft Audits`
- `Quick Actions`

This makes the dashboard a true control center rather than just a generic summary page.

## Recommended Restaurants Overview Card Model

Each restaurant summary card or row should likely include:

- restaurant name
- city or short address
- latest inspection score or grade
- latest inspection date
- open violations count
- pending review count
- draft audit indicator
- status cue for attention needed

This lets users quickly scan the portfolio and choose where to drill in.

## Core User Journeys

## Journey 1: Tenant Owner Sets Up Restaurant

1. user logs in
2. user creates tenant
3. user adds restaurant from master list
4. app imports public inspections and latest active findings
5. user lands on Restaurants overview
6. user opens the selected restaurant dashboard

## Journey 2: Auditor Runs an Audit

1. auditor opens Audits
2. auditor starts an audit
3. auditor completes sections offline if needed
4. auditor submits the audit
5. app creates triggered violations
6. auditor sees audit completion summary

## Journey 3: Staff Responds to a Violation

1. staff opens Violations
2. staff selects an open violation
3. staff updates the active response
4. staff submits the violation for review
5. violation moves to pending review

## Journey 4: Manager Reviews and Closes

1. manager opens Violations
2. manager filters to pending review
3. manager opens a violation detail screen
4. manager edits response if needed
5. manager closes the violation or sends it back

## Journey 5: User Switches Restaurant

1. user taps the restaurant header control
2. user selects another allowed restaurant
3. app updates context
4. dashboard and lists refresh to the new restaurant

## Journey 6: Manager Reviews the Restaurant Portfolio

1. manager opens Restaurants
2. manager scans summary cards across locations
3. manager sees which locations have open violations, pending review, or poor recent inspections
4. manager drills into the restaurant that needs attention

## Recommended Version 1 Screen List

The version 1 app should likely include these screens:

- Login
- Tenant registration
- Restaurants overview
- Add restaurant
- Restaurant switcher
- Dashboard
- Violation list
- Violation detail
- Violation response edit
- Audit list
- Start audit
- In-progress audit
- Audit summary
- Public inspection list
- Public inspection detail
- Team management
- Analytics
- Settings
- Profile

## Summary

FiScore version 1 should use a mobile-first navigation model built around bottom tabs for `Restaurants`, `Dashboard`, `Violations`, `Audits`, and `More`, with the current restaurant shown in a persistent header switcher whenever the user is inside restaurant-specific work. This creates a better balance between portfolio visibility and one-restaurant-at-a-time execution, while also leaving room for future modules like assets and complaints as FiScore evolves into a broader restaurant operations platform.
