# FiScore Product Status Snapshot - 2026-05-25

## Purpose

This document is a development checkpoint as of May 25, 2026. It records
what is working, the important product decisions made during implementation,
the explicit open work already captured in the repository, and the recommended
next sequence of work.

This is not a replacement for the canonical product requirements. Feature
scope and intended behavior remain defined in the product specifications,
including:

- [FEATURES.md](FEATURES.md)
- [WORKFLOWS.md](WORKFLOWS.md)
- [DATA_MODEL.md](DATA_MODEL.md)
- [AUDIT_EXECUTION_FLOW.md](AUDIT_EXECUTION_FLOW.md)
- [VIOLATION_EXECUTION_FLOW.md](VIOLATION_EXECUTION_FLOW.md)
- [TRAINING_EXECUTION_FLOW.md](TRAINING_EXECUTION_FLOW.md)
- [LIBRARY_CONTENT_SYNC_FLOW.md](LIBRARY_CONTENT_SYNC_FLOW.md)
- [TEAM_INVITE_FLOW.md](TEAM_INVITE_FLOW.md)
- [NOTIFICATION_FLOW.md](NOTIFICATION_FLOW.md)
- [BILLING_AND_SUBSCRIPTION_FLOW.md](BILLING_AND_SUBSCRIPTION_FLOW.md)

## Current Product Position

FiScore now has the essential closed-loop operating workflow:

```text
Site -> Public or Internal Finding -> Violation -> Resolution and Review
     -> Training Assignment -> Learning Completion
```

The product is no longer only an inspection viewer. The current application
can support a restaurant team in identifying a problem, documenting a fix,
reviewing the work, and assigning targeted coaching to reduce repeat issues.

## Implemented And Usable

### Tenant, Site, And Dashboard

- tenant/workspace creation and active site context
- restaurant linking to master data
- site dashboard focused on actionable operating work
- navigation into violations, audits, training, and team management

### Violations

- unified violations under tenant site records
- public inspection and internal audit violation sources
- status and severity presentation
- resolution response flow with supporting detail fields
- proof attachment upload, thumbnail display, image viewing, and deletion
- notes and collaboration on the violation
- submit-for-review, send-back, and close workflow

### Public Audits And Inspection History

- imported inspection list and inspection detail
- score, grade, findings, and related violation context
- navigation from an audit finding into the violation workflow
- tenant-side report attachment support where a usable report exists

### Internal Audits

- FiScore checklist library discovery and tenant adoption
- sample internal checklist templates
- section-by-section checklist execution
- observations and photo capture against responses
- review and submission flow
- creation of actionable violations from failed checks
- preservation of observed-during-check proof on generated violations

### Team Access

- tenant owner and admin team management
- invitations, acceptance, member status, and site access controls
- deactivation and re-invitation handling
- team activity history for access-management events

### Training

- FiScore training library discovery and tenant adoption
- manager assignment flow and team progress view
- cancellation of assignments
- staff learning flow with lesson topics and quick checks
- answer feedback and training completion summary
- training initiated from violation follow-up
- versioned training content with images and required video support

### Library Content Foundation

- central FiScore Library records for checklist and training content
- versioned FiScore-published content
- tenant-owned adoption of library items
- execution snapshots so historical audits and assignments remain tied to
  the exact content used
- centrally hosted training media referenced by tenant training snapshots

## Product Decisions Made

These decisions should guide future implementation unless the product strategy
changes deliberately.

### Mobile-First Use

FiScore should remain practical for restaurant staff with little or no
training. Primary actions must be obvious, short, and usable from a phone
during a shift.

### Violations Are The Actionable Unit

Whether an issue begins in a public inspection or an internal audit, resolution
work should use the same violation workflow. Audit screens provide context;
violations manage follow-up work.

### Resolution, Proof, And Notes Are Distinct

- `Resolution` captures what was fixed.
- `Attachments` or proof captures supporting evidence.
- `Notes` supports quick team collaboration without changing the formal fix.

### Library Content Is Adopted, Not Executed Live

Tenants should not execute mutable central library records directly. A tenant
adopts a checklist or training item, and individual audit sessions or training
assignments preserve snapshots of the selected version.

### FiScore-Published And Tenant-Created Content Differ

- FiScore Library should retain published central versions.
- A synced tenant copy may adopt the latest selected FiScore version for future
  execution.
- Tenant-created or customized content should eventually maintain its own
  tenant-owned draft and version lifecycle.

### Media Storage Must Remain Controlled

Violation proof is tenant-owned. FiScore training media is centrally owned and
referenced by tenant content rather than duplicated into each tenant. Image
compression, short video constraints, thumbnails, and storage rules remain
important cost controls.

### Imported Public Reports Are Secondary For Now

Many public inspection sources expose incomplete HTML artifacts rather than
clean customer-facing PDFs. Public report handling should not distract from
the core remediation workflow until FiScore can provide a consistently useful
viewable artifact.

## Explicitly Captured TODO Items

### Internal Audit Report

Generate a tenant-owned final audit report after an internal check is
submitted. It should include answers, observations, evidence, created
violations, and eventually review or closure history.

Reference: [AUDIT_EXECUTION_FLOW.md](AUDIT_EXECUTION_FLOW.md)

### Checklist Library Growth

- tenant-created company checklists and checklist editing
- categories, filters, recently used checks, and suggested checks
- update, detach, and version management for tenant administrators
- site-level checklist availability where needed

Reference: [AUDIT_EXECUTION_FLOW.md](AUDIT_EXECUTION_FLOW.md)

### Tenant-Created Library Content

- create checklist and create training actions in `My Library`
- draft, preview, publish, archive, and new-version workflows
- `Created by your team` labeling
- `Customize for my team` flow for independent tenant-owned copies

Reference: [LIBRARY_CONTENT_SYNC_FLOW.md](LIBRARY_CONTENT_SYNC_FLOW.md)

### FiScore Library Administration And Discovery

- publishing console or governed publishing workflow
- content detail and preview before adoption
- categories, filters, suggested items, and recently used items
- update summaries, detach controls, and site availability controls

Reference: [LIBRARY_CONTENT_SYNC_FLOW.md](LIBRARY_CONTENT_SYNC_FLOW.md)

### Team Invitations And Authentication Branding

- send branded invitation emails through a verified FiScore domain
- generate passwordless sign-in links from trusted backend code
- validate delivery to common mailbox providers
- configure branded auth/action-link domains
- configure Android App Links and Apple Universal Links for mobile invitation
  acceptance
- configure Google sign-in branding so users see FiScore rather than a Firebase
  development hostname
- enable Apple sign-in after platform/provider setup

References:

- [TEAM_INVITE_FLOW.md](TEAM_INVITE_FLOW.md)
- `apps/fiscore_app/lib/services/auth_service.dart`
- `apps/fiscore_app/lib/features/auth/welcome_screen.dart`

### Multiple Workspace Membership

If users need to belong to more than one tenant, add an explicit workspace
switcher instead of relying on the current single-active-tenant path.

Reference: `apps/fiscore_app/lib/features/home/signed_in_home_screen.dart`

### Public Report Experience

De-emphasize imported source reports until ingestion can produce reliable
customer-facing report artifacts, preferably PDFs or generated mobile-friendly
snapshots stored for the tenant.

Reference: `apps/fiscore_app/functions/sites.js`

### Onboarding Search Security

Before production rollout, harden master restaurant search with authentication,
active membership checks, App Check, logging, rate limiting, constrained
queries, and monitoring against master-data enumeration.

Reference: [ONBOARDING_FLOW.md](ONBOARDING_FLOW.md)

## Major Specified Features Still Ahead

### Notifications And Action Inbox

The product specification calls for operational notifications covering:

- violation assignment and review
- violation sent back for additional work
- training assignment, due soon, and overdue
- audit due soon and overdue once scheduling exists
- direct navigation into the relevant work item

Reference: [NOTIFICATION_FLOW.md](NOTIFICATION_FLOW.md)

### Audit Scheduling And Recurrence

Internal audits should eventually support scheduled and recurring work,
assignees, due and overdue states, and manager visibility.

### Billing And Tenant Entitlements

The intended version 1 billing strategy is annual-first and tenant based, with:

- self-serve mobile purchase support
- tenant-level entitlements
- included site counts and added-site upgrades
- owner/admin billing control
- enterprise-managed tenant handling

Reference: [BILLING_AND_SUBSCRIPTION_FLOW.md](BILLING_AND_SUBSCRIPTION_FLOW.md)

### Offline Reliability

FiScore is intended to work during restaurant operations where connectivity may
be unreliable. Remaining work includes durable offline execution queues,
background media sync behavior, visible sync status, and conflict handling.

### Production Observability And Hardening

Before a serious pilot or launch, add runtime monitoring and operational safety,
including error reporting, security hardening, authentication polish, and
storage/API abuse protection.

## Recommended Next Item

### Build Notifications And Action Inbox Next

The app now creates meaningful work for multiple roles:

- staff resolve violations
- managers review submitted fixes
- staff complete assigned training
- managers watch for overdue learning
- scheduled audits will later create additional due work

Without an action inbox, users must manually visit each feature area to discover
what requires attention. That is manageable during development, but it is not
natural for restaurant teams using the app during an active shift.

The next implementation should therefore be a low-noise operational action
surface rather than a new standalone module.

### Recommended Version 1 Slice

Implement an in-app action inbox or activity view, reachable from the dashboard
or a suitable secondary navigation location, with:

- unread/read state
- site context
- relative time
- clear action wording
- deep linking directly to the required screen

Start with these events:

| Event | Recipient | Destination |
| --- | --- | --- |
| Violation submitted for review | Owner/admin/appropriate manager | Review violation |
| Violation sent back | Responsible staff member | Violation resolution |
| Training assigned | Assigned staff member | Training assignment |
| Training overdue | Assigned staff member, visible to manager | Training assignment |

Once the in-app event model is stable, add selective push delivery for urgent
items. Email should remain primarily for team invitations rather than everyday
operational noise.

## Recommended Work Sequence

1. Notifications and action inbox
2. Audit scheduling and recurring internal checks
3. Invitation email delivery, branded authentication, and Apple sign-in
4. Tenant-created checklist and training content
5. Billing and entitlement enforcement
6. Internal audit final report generation
7. Offline hardening and production observability

## Why Not Billing First

Billing is important and the entitlement model is already documented. However,
the most important near-term product question is whether restaurant teams can
reliably discover and complete the work FiScore creates for them.

Notifications and direct task navigation strengthen daily product use across
violations, reviews, training, and later scheduled audits. Billing can then be
introduced around a workflow that users already find operationally valuable.

