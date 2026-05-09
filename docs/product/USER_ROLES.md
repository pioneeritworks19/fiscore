# FiScore User Roles

## Purpose

This document defines the customer-side user roles for FiScore and the responsibilities and permissions associated with each role.

The goal is to create a role model that is:

- simple enough for version 1
- clear for product and engineering decisions
- aligned with restaurant operations
- compatible with Firestore authorization and app workflows

This document focuses on tenant-side product roles used by restaurant organizations inside FiScore.

## Identity And Invitation Direction

For version 1:

- email should be the primary invitation identifier
- phone number may be stored on the user profile
- phone should be treated as contact information rather than the primary invite key

## Version 1 Roles

For version 1, FiScore should support these main tenant roles:

- `tenant_owner`
- `admin`
- `manager`
- `auditor`
- `staff`

## Role Summary

### 1. Tenant Owner

The tenant owner is the person who started the tenant registration and is the highest authority within that tenant.

This role is intended to represent the primary customer account owner.

### 2. Admin

The admin role supports day-to-day administrative control of the tenant, sites, team members, and configuration.

Admins help manage the tenant without necessarily being the original tenant owner.

### 3. Manager

Managers are responsible for site operations, team oversight, responses to findings and violations, and final closure of violations.

### 4. Auditor

Auditors are responsible for conducting internal audits and working with checklist-driven inspection workflows.

They may also help manage checklist templates and scoring configuration.

### 5. Staff

Staff members participate in operational follow-up, including responding to violations and supporting remediation work.

They are not final approvers for closure-sensitive workflows.

## Core Role Principles

### 1. Tenant Owner Is Unique in Authority

The tenant owner has the highest tenant-level authority and should be able to manage tenant-level settings and control restaurant access at the broadest level.

### 2. Role Scope Is Tenant-Wide in Version 1

A user may belong to multiple sites within the same tenant, but their role remains the same across those sites.

This means:

- one user can access multiple sites
- users switch one restaurant at a time in the app
- role differences by restaurant are not part of version 1

### 3. Restaurant Context Is Still Important

Although the role is tenant-wide, the app experience is site-specific. Users work in one site context at a time and switch sites when needed.

### 4. Sensitive Actions Need Stronger Roles

Sensitive operations such as closing violations, managing tenant settings, or adding sites should be restricted to higher-trust roles.

## Capability Matrix

The table below summarizes the intended version 1 permissions.

| Capability | Tenant Owner | Admin | Manager | Auditor | Staff |
|---|---|---|---|---|---|
| View tenant | Yes | Yes | Yes | Yes | Yes |
| View assigned sites | Yes | Yes | Yes | Yes | Yes |
| View all sites in tenant | Yes | Yes | No | No | No |
| Add site to tenant | Yes | Yes | No | No | No |
| Manually add site to tenant | Yes | Yes | No | No | No |
| Link manual site to master restaurant | Yes | Yes | No | No | No |
| Remove site from tenant | Yes | Yes | No | No | No |
| Invite team members | No | Yes | Yes | No | No |
| Change user roles | No | Yes | Yes | No | No |
| Deactivate users | No | Yes | Yes | No | No |
| Edit tenant settings | Yes | Yes | No | No | No |
| View analytics and reports | Yes | Yes | Yes | Yes | No |
| Upload onsite health inspection report | Yes | Yes | Yes | Yes | No |
| Schedule one-time audits | No | No | Yes | Yes | No |
| Create recurring audit schedules | No | No | Yes | Yes | No |
| Create internal audits | No | No | Yes | Yes | No |
| Complete internal audits | No | No | Yes | Yes | No |
| Create or edit checklist templates | No | Yes | Yes | Yes | No |
| Create or edit scoring rules | No | Yes | Yes | Yes | No |
| Assign training | No | No | Yes | No | No |
| Complete assigned training | No | No | Yes | Yes | Yes |
| Respond to violations | No | No | Yes | Yes | Yes |
| Submit violation response for review | No | No | Yes | Yes | Yes |
| Approve violation response | No | No | Yes | No | No |
| Close violation | No | No | Yes | No | No |
| Reopen violation | No | No | Yes | No | No |

## Detailed Role Definitions

## Tenant Owner

### Description

The tenant owner is the original account owner for the tenant and has the highest authority over tenant-wide configuration and restaurant portfolio management.

### Key Permissions

- view all sites within the tenant
- add sites to the tenant
- manually add sites to the tenant
- link manual sites to master restaurant records
- remove sites from the tenant
- edit tenant-level settings
- view analytics and reports
- upload onsite health inspection reports

### Notes

- the tenant owner is not necessarily involved in day-to-day operational workflows
- the tenant owner may delegate much of the ongoing administration to admin users
- version 1 does not require the tenant owner to handle routine user invites or role changes unless you decide to add that later

## Admin

### Description

The admin role is the main tenant administration role for managing sites, team membership, and configuration.

### Key Permissions

- view all sites within the tenant
- add and remove sites
- manually add sites
- link manual sites to master restaurant records
- invite team members
- change roles
- deactivate users
- edit tenant settings
- view analytics and reports
- upload onsite health inspection reports
- create or edit checklist templates and scoring rules

### Notes

- admins are the main operational administrators for tenant setup and maintenance
- this role is broader than manager and should be treated as a high-trust role

## Manager

### Description

Managers are operational leaders who oversee audit completion, remediation work, and final violation closure.

### Key Permissions

- create and complete internal audits
- assign training
- invite team members
- change roles
- deactivate users
- create or edit checklist templates and scoring rules
- respond to violations
- approve violation responses
- close violations
- reopen violations
- view analytics and reports
- upload onsite health inspection reports

### Notes

- manager is the only role allowed to close violations in version 1
- manager is also the key review role for violation responses submitted by staff or auditors
- this role should be able to guide daily restaurant compliance activity

## Auditor

### Description

Auditors are focused on internal inspections, checklist execution, and audit program quality.

### Key Permissions

- create and complete internal audits
- create or edit checklist templates
- create or edit scoring rules
- complete assigned training
- respond to violations
- submit violation responses for review
- view analytics and reports
- upload onsite health inspection reports

### Notes

- auditors can create findings through audit workflows
- auditors cannot close violations in version 1
- auditors can participate deeply in compliance operations without having final managerial approval authority

## Staff

### Description

Staff members support corrective action work and day-to-day operational follow-up.

### Key Permissions

- view their accessible restaurant context
- complete assigned training
- respond to violations
- submit responses for review

### Notes

- staff cannot close violations
- staff do not manage tenant settings, sites, or user administration
- staff should remain focused on execution rather than approval

## Restaurant Access Model

### Version 1 Rules

- a tenant may contain multiple sites
- the app shows one site at a time
- users can switch sites they have access to
- a user may belong to multiple sites
- a user's role remains the same across sites in the same tenant

### Visibility Rules

- tenant owner and admin can view all sites in the tenant
- other roles should only see sites they are assigned or allowed to access

## User Management Rules

### Invite and Role Management

For version 1:

- admin can invite users
- manager can invite users
- admin can change roles
- manager can change roles
- admin can deactivate users
- manager can deactivate users

### Important Product Question for Later

Because managers can change roles in version 1, the team should later define guardrails such as:

- whether a manager can promote another user to admin
- whether a manager can deactivate another manager
- whether a manager can change the role of the tenant owner

Recommended version 1 product guardrails:

- no one can change the tenant owner role through normal UI
- managers should not be able to modify tenant owner access
- role escalation to admin may require admin confirmation if needed later

## Restaurant Portfolio Management

### Add and Remove Restaurants

Only these roles can add or remove sites from a tenant:

- tenant owner
- admin

This is important because adding a restaurant creates a connection between the tenant and the master public data platform.

### Manual Site Creation and Later Linking

Only these roles can manually create tenant sites or later link a manual site to a master restaurant:

- tenant owner
- admin

This keeps portfolio integrity and master-data linkage under higher-trust roles.

## Audit Permissions

### Roles Allowed to Create and Complete Internal Audits

- manager
- auditor

### Roles Allowed to Schedule Audits

- manager
- auditor

### Roles Allowed to Create Recurring Audit Schedules

- manager
- auditor

### Roles Allowed to Manage Checklist Templates and Scoring

- admin
- manager
- auditor

### Notes

- this allows operational and compliance-focused users to own the audit program
- staff do not control audit design in version 1

## Violation Permissions

Violations may come from:

- public inspection data
- internal audits
- audit-triggered findings
- manual site-level identification

### Roles Allowed to Assign Training

- manager

### Roles Allowed to Complete Assigned Training

- manager
- auditor
- staff

### Roles Allowed to Respond to Violations

- manager
- auditor
- staff

### Roles Allowed to Submit for Review

- manager
- auditor
- staff

### Roles Allowed to Approve, Close, or Reopen Violations

- manager

### Important Rule

Violation closure should always be controlled by a manager in version 1.

This matches your intended product direction:

- staff and other users can do the work
- managers provide the final operational sign-off

## Analytics and Reporting Access

These roles can view analytics and reports:

- tenant owner
- admin
- manager
- auditor

Staff do not have analytics/report access in version 1 unless this is expanded later.

## Public Inspection Report Upload Access

These roles can upload onsite copies of health department inspection reports when the public source does not provide the official report:

- tenant owner
- admin
- manager
- auditor

Staff should not upload onsite health inspection reports in version 1 unless the operating model changes later.

## Tenant Settings Access

Only these roles can edit tenant-level settings such as:

- company profile
- subscription settings
- integrations
- defaults

Allowed roles:

- tenant owner
- admin

## Recommended Firestore Authorization Implications

This role model should inform Firestore security rules and backend checks.

Recommended enforcement areas:

- tenant membership validation for all tenant reads
- role-based write checks for restaurant add/remove
- role-based write checks for manual site creation and later master linking
- role-based checks for user invites, deactivation, and role changes
- role-based checks for site add/remove and violation workflows
- manager-only checks for violation closure
- read-only access to public inspection projections
- admin/manager/auditor checks for checklist editing
- tenant-owner/admin/manager/auditor checks for onsite public inspection report uploads

## Recommended Role Values

Suggested canonical values for implementation:

- `tenant_owner`
- `admin`
- `manager`
- `auditor`
- `staff`

Using explicit role values like `tenant_owner` is better than using only `owner`, because it avoids confusion with restaurant ownership in the real world.

## Open Questions for Later Versions

These questions do not need to block version 1, but should be revisited later:

- should tenant owner also inherit all admin and manager powers explicitly in UI and backend rules
- should manager role changes be limited to lower-privilege roles only
- should auditor be allowed to assign violations
- should admins eventually be allowed to assign training directly
- should staff be limited to only their own assigned violations
- should there be a future `regional_manager` role
- should FiScore internal platform roles be documented separately from tenant roles

## Summary

FiScore version 1 should use a tenant-wide role model with five main roles: `tenant_owner`, `admin`, `manager`, `auditor`, and `staff`. Tenant owner and admin handle tenant-wide setup and site portfolio control. Managers oversee operational compliance, including final violation closure. Auditors manage audit execution and checklist logic while also participating in violation workflows. Staff support remediation work without final approval authority.
