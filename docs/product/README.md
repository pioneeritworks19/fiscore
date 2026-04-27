# FiScore

FiScore is a food safety and restaurant inspection management platform designed for restaurant owners, managers, and staff. It helps teams review local health department inspection reports, run internal audits, track violations, and take corrective action before future inspections.

The primary experience is a mobile app for iOS and Android, supported by a lighter companion web app. FiScore is built with Flutter and Firebase.

## How To Use This Folder

This folder mixes product overview material and deeper product design references.

For most work:

1. read [FEATURES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\FEATURES.md) for scope and behavior
2. read [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md) for user flow
3. read [USER_ROLES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\USER_ROLES.md) for permissions
4. then use the specialized docs only if your task needs them

## Product Source Of Truth

Within the product folder, these docs should be treated as primary:

- feature scope:
  [FEATURES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\FEATURES.md)
- user workflows:
  [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- roles and permissions:
  [USER_ROLES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\USER_ROLES.md)
- business entities:
  [DATA_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\DATA_MODEL.md)
- sync rules:
  [SYNC_STRATEGY.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\SYNC_STRATEGY.md)
- scoring and grading:
  [SCORING_RULES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\SCORING_RULES.md)

Specialized reference doc:

- audit checklist engine:
  [AUDIT_CHECKLIST_DESIGN.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_CHECKLIST_DESIGN.md)

## Problem Statement

Restaurants often struggle to keep inspection results, internal audits, follow-up actions, and team accountability organized in one place. FiScore helps restaurants improve food safety practices, reduce repeat violations, and stay better prepared for health department inspections.

## Target Users

- Restaurant owners
- Restaurant managers
- Restaurant staff members

## Platform

- iOS app
- Android app
- Lightweight web app

## Tech Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting or related Firebase services for web deployment

## Core Features

### Tenant and Restaurant Setup

- User registration and onboarding
- Tenant-style setup for organizations with multiple restaurant locations
- Find and add restaurants
- Switch between restaurants

### Inspection and Audit Workflows

- View health department inspection reports
- View, track, and close violations from health department inspections
- Plan and conduct internal inspections and audits
- Use prebuilt inspection and audit checklists
- View, track, and close violations from internal inspections and audits

### Analytics and Team Management

- Analytics for health department inspections
- Analytics for internal audits
- Admin tools for inviting team members

## Product Design References

The core product design documents in this folder include:

- [FEATURES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\FEATURES.md)
- [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- [USER_ROLES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\USER_ROLES.md)
- [DATA_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\DATA_MODEL.md)
- [SCORING_RULES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\SCORING_RULES.md)
- [SYNC_STRATEGY.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\SYNC_STRATEGY.md)
- [AUDIT_CHECKLIST_DESIGN.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_CHECKLIST_DESIGN.md)

## Offline-First Requirement

FiScore must work reliably in low-connectivity and no-connectivity environments. Restaurant teams should be able to continue using the app during active shifts, in storage areas, or in buildings with poor signal without losing confidence in the system.

Key expectations:

- Users can view relevant restaurant data while offline
- Users can conduct audits and inspections while offline
- Users can create, update, and close violations while offline
- The app should automatically sync data when connectivity returns
- The user experience should make it clear when data is saved locally, waiting to sync, synced successfully, or needs attention

## Synchronization Principles

Synchronization must be designed carefully so users do not feel that data has disappeared, failed to save, or been overwritten unexpectedly.

Important sync principles:

- Use an offline-first approach where changes are stored locally before syncing to the cloud
- Queue writes locally and retry them automatically when the device reconnects
- Show sync status clearly for important records and actions
- Preserve user trust by avoiding silent overwrites whenever possible
- Track update timestamps, device context, and user identity for important changes
- Design conflict handling rules for concurrent edits across devices and team members

## Suggested Sync Strategy

The implementation should favor a predictable and user-trust-focused sync model:

- Save user actions locally first so the app feels immediate and dependable
- Sync in the background whenever connectivity is available
- Mark records with statuses such as `draft`, `pending sync`, `synced`, or `sync issue`
- Use server timestamps and revision metadata to detect conflicting edits
- Prefer field-level merges where safe, especially for additive data like notes, photos, and checklist progress
- For high-risk conflicts, surface a review flow instead of silently replacing one user's work
- Keep an audit trail for key actions such as creating, updating, closing, and reopening violations

## User Experience Requirements for Sync

To reduce anxiety and improve confidence, the app should communicate sync behavior clearly:

- Show whether the device is offline or online
- Confirm that actions were saved locally even when offline
- Indicate when background sync is in progress
- Show when sync has completed successfully
- Warn users when the same record was changed elsewhere and needs review
- Avoid implying that cloud sync happened instantly if the action is only stored locally

## Authentication

FiScore supports authentication with:

- Google Sign-In
- Sign in with Apple

## Database

- Cloud Firestore

## Deployment Targets

- Apple App Store
- Google Play Store
- Firebase

## Version 1 Scope

Version 1 focuses on helping restaurant teams centralize inspection visibility, manage violations, complete internal audits, and collaborate across locations and team members.

## Future Enhancements

Potential future additions may include:

- Notifications and reminders for unresolved violations
- Role-based permissions for owners, managers, and staff
- Trend analysis across locations
- Photo evidence uploads for violations and corrective actions
- Downloadable compliance reports
- Advanced conflict resolution workflows for multi-user editing

## Project Goals

- Improve restaurant food safety readiness
- Reduce repeated violations
- Make audit workflows easier for teams to complete consistently
- Help restaurants prepare for future health department inspections

## Development Notes

This README is an initial product and project overview. As the app architecture becomes more defined, this document can be expanded with:

- Local setup instructions
- Folder structure
- Firebase configuration steps
- Build and release workflows
- Testing guidance
