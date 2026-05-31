# Feature Specification: Notifications and Email Strategy

**Feature Branch**: `001-notifications-email`

**Created**: 2026-05-31

**Status**: Draft

**Input**: User description: "Create a clear notification strategy and technology strategy for how FiScore sends emails, including first sign-on, registration, tenant workspace creation, sign-in links, team invites, resend invites, deactivation, and other important events."

## Clarifications

### Session 2026-05-31

- Q: Should all notifications be emails? -> A: No; account access, onboarding, and future billing use email, while operational work uses action items first and push later.
- Q: Should incomplete first-time workspace setup be included? -> A: Yes; use sparse onboarding lifecycle nudges that do not create operational action items.

## Affected Areas

- FiScore App: notification surfaces, action inbox entry points, user preferences, and email-link sign-in states.
- Firebase Cloud Functions: trusted notification decisions, role-aware recipient selection, action item lifecycle, and future delivery orchestration.
- Firestore rules/schema/indexes: notification/action item records, delivery logs, preference records, and scalable query shapes.
- FiScore Admin Console: read-only delivery/status visibility and later support workflows; not the primary V1 sender.
- FiScore Ingestion: not affected in V1, except future operational alerts if ingestion health becomes tenant-visible.
- Firebase Storage/rules: not affected in V1.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Invite and access emails get users into the right workspace (Priority: P1)

Tenant owners and admins can invite teammates, resend invites, and update or deactivate access with confidence that the recipient receives the right account-access email and lands in the correct FiScore workspace.

**Why this priority**: FiScore is self-service for small restaurants. If staff cannot join easily, the rest of the operational workflow does not matter.

**Independent Test**: Invite a new staff user, resend the invite, accept it with email-link or Google sign-in, and verify the user lands in the invited tenant/site context without duplicate active memberships.

**Acceptance Scenarios**:

1. **Given** an owner or admin invites a staff user, **When** the invite is created, **Then** the invited email receives a clear FiScore invitation with workspace name, inviter context when available, and a direct call to join.
2. **Given** an invite is pending, **When** the inviter resends it, **Then** the recipient receives a new invite email without creating duplicate active invites or confusing the invite state.
3. **Given** a user has been deactivated, **When** the user tries to access the tenant, **Then** FiScore clearly explains that access is inactive and does not send noisy operational work notifications for that tenant.

---

### User Story 2 - First-time owner understands their new workspace (Priority: P1)

A new tenant owner who signs in for the first time and creates a FiScore workspace receives a clear confirmation and orientation message that explains where daily app work happens and where admin or website resources can be found.

**Why this priority**: First-time setup is the first trust moment for a self-service SaaS product. The owner should not wonder whether the workspace was created, where to add sites, or where admin console access belongs.

**Independent Test**: Create a new tenant workspace from a fresh owner account and verify the owner receives a workspace-created confirmation that names the workspace, points back to the FiScore app, and references the FiScore website/admin console only as helpful next destinations.

**Acceptance Scenarios**:

1. **Given** a new owner creates a workspace, **When** workspace creation succeeds, **Then** the owner receives a confirmation with workspace name, next step to add or link a restaurant, and a clear sign-in path back to FiScore.
2. **Given** a workspace is created, **When** the confirmation is sent, **Then** the message can mention the FiScore website for product/help resources and the FiScore admin console for owner/admin management without requiring staff to use those surfaces.
3. **Given** workspace creation fails or is retried, **When** the owner tries again, **Then** FiScore must not send duplicate successful workspace-created emails for the same workspace.

---

### User Story 3 - Operational notifications point users to important work without noise (Priority: P1)

Staff, auditors, managers, admins, and tenant owners receive in-app action items and selective emails or future push notifications only for work that needs action.

**Why this priority**: FiScore already uses action items for scalable daily work. Notifications should amplify that model, not become a chat stream.

**Independent Test**: Assign a violation, submit a fix for review, send it back, assign training, complete training, assign a check, and cancel a check. Verify only actionable notification records remain open and low-value events do not create emails.

**Acceptance Scenarios**:

1. **Given** a violation is submitted for review, **When** the transition succeeds, **Then** the responsible reviewers see an actionable review item and only the selected notification channels for that event are queued.
2. **Given** a manager sends a violation back, **When** the transition succeeds, **Then** the assignee receives a follow-up action with the reason and deep link to the violation.
3. **Given** a note, photo, draft save, or minor status refresh occurs, **When** the event completes, **Then** FiScore does not send an email by default.

---

### User Story 4 - Incomplete onboarding gets a gentle nudge (Priority: P2)

New owners who start setup but do not finish the first usable FiScore workspace receive sparse lifecycle reminders that help them continue without creating a noisy notification stream.

**Why this priority**: FiScore creates value only after a workspace has at least one restaurant. A small nudge can recover abandoned setup, but it should not distract active restaurant staff.

**Independent Test**: Simulate a first-time user who signs in without creating a workspace and another owner who creates a workspace without adding a site. Verify each receives only the intended setup reminder after the configured waiting period.

**Acceptance Scenarios**:

1. **Given** a first-time user signs in but does not create a workspace, **When** the setup reminder window is reached, **Then** FiScore sends one clear reminder to create a workspace.
2. **Given** an owner creates a workspace but does not add or link any restaurant, **When** the site setup reminder window is reached, **Then** FiScore sends a reminder with one primary call to add the first restaurant.
3. **Given** the user creates a workspace or adds a site before the reminder window, **When** the reminder job evaluates the user, **Then** no stale setup reminder is sent.

---

### User Story 5 - Users and support can understand notification status (Priority: P2)

Admins and support users can understand whether important notifications were sent, skipped, failed, or suppressed by dedupe rules without reading raw function logs.

**Why this priority**: Email delivery issues are common in self-service products. A lightweight audit trail reduces support guesswork.

**Independent Test**: Trigger each V1 notification category and verify a delivery/status record exists with recipient, reason, target, channel, status, and timestamp.

**Acceptance Scenarios**:

1. **Given** an invite email is sent, **When** an admin views invite history later, **Then** FiScore can show that the invite was created and the latest delivery attempt status is known.
2. **Given** notification delivery fails, **When** the status is inspected, **Then** the failure can be distinguished from an event intentionally skipped because it was not email-worthy.

---

### User Story 6 - Notification preferences stay simple but extensible (Priority: P3)

Users can rely on sensible defaults now, while FiScore keeps a clean path for future user preferences by category and channel.

**Why this priority**: Preferences are useful, but premature complexity would distract from the core operational workflows.

**Independent Test**: Verify V1 defaults are documented, role-aware, and do not require users to configure anything before receiving essential access and action notifications.

**Acceptance Scenarios**:

1. **Given** a new user joins FiScore, **When** they have no notification preference record, **Then** FiScore uses safe defaults for access and operational action notifications.
2. **Given** future preferences are added, **When** a user changes a category, **Then** required access/security emails remain unaffected.

### Edge Cases

- A recipient has more than one pending invite with the same email.
- A recipient is inactive in the tenant but receives a new invite for reactivation.
- A recipient loses site access before a scheduled notification is delivered.
- A manager or reviewer role changes after an action item is created.
- An event is retried and must not create duplicate emails or duplicate open action items.
- An email delivery provider accepts the message but the user reports not receiving it.
- A tenant has multiple sites and the notification target must make the site context unambiguous.
- A user signs in with Google even though the invite was sent to the same email through email-link flow.
- A first-time user signs in, abandons setup, then later joins by invitation instead of creating a workspace.
- A workspace owner manually adds a restaurant shortly before a scheduled reminder evaluates the workspace.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST define notification categories for account access, tenant/team administration, operational action items, billing/entitlements, and future system health.
- **FR-002**: System MUST send or queue account-access emails for team invitation, invite resend, passwordless sign-in link, workspace creation confirmation, and important access changes.
- **FR-002A**: Workspace creation confirmation MUST orient the first tenant owner to the FiScore app for daily work, the FiScore website for product/help resources, and the FiScore admin console for owner/admin management when available.
- **FR-002B**: System MUST support sparse onboarding lifecycle reminders for users who sign in but do not create a workspace and owners who create a workspace but do not add or link a restaurant.
- **FR-002C**: FiScore-controlled emails MUST identify FiScore as the product sender and include tenant/workspace context when available using "FiScore on behalf of {tenantName}" style wording; V1 MUST NOT require tenant-managed logos, colors, sender domains, or custom branding.
- **FR-002D**: FiScore-controlled email copy MUST support localization using recipient language preference when known, a future tenant default when available, and English fallback; tenant names, user names, site names, comments, and other user-entered values MUST remain as entered.
- **FR-003**: System MUST avoid email by default for low-value collaboration events such as note creation, draft save, photo upload, routine list refresh, and ordinary read activity.
- **FR-004**: System MUST keep action items as the primary in-app needs-action model for violations, assigned checks, assigned training, review requests, sent-back fixes, due work, and overdue work.
- **FR-005**: System MUST define notification recipients from tenant role, site access, assignment, and workflow ownership rules.
- **FR-006**: System MUST preserve site and tenant context in every actionable notification.
- **FR-007**: System MUST deep link notifications to the most specific useful target when the app supports that target.
- **FR-008**: System MUST record notification decisions with recipient, event type, target, channel, status, dedupe key, timestamps, and enough context for support review.
- **FR-009**: System MUST dedupe or suppress repeated notifications for the same recipient/event/target within a defined business window.
- **FR-010**: System MUST distinguish sent, failed, skipped, suppressed, and pending delivery states.
- **FR-011**: System MUST enforce role and site access before creating or delivering tenant operational notifications.
- **FR-012**: System MUST support resend invite without creating duplicate active memberships or duplicate unresolved invitation states.
- **FR-013**: System MUST stop operational notifications to deactivated users for the affected tenant.
- **FR-014**: System MUST allow future push notifications to consume the same notification/action model without changing the business event definitions.
- **FR-015**: System MUST allow future billing emails and entitlement notices without mixing billing state into operational action item logic.
- **FR-016**: System MUST keep user-entered content and authored training/checklist content in its original language unless a separate translation feature is explicitly specified.

### Key Entities *(include if feature involves data)*

- **Notification Event**: A business event that may create an in-app action item, email delivery, push delivery, or an intentional skip record.
- **Action Item**: A read-optimized operational work item assigned to a user or role for dashboard and inbox use.
- **Delivery Attempt**: A record of one channel attempt for a notification event, including status, provider response summary, and timestamps.
- **Notification Template**: A product-managed message definition for a category, locale, channel, and event type; V1 templates are code-owned and localized for FiScore-controlled copy.
- **Recipient**: A user, invited email, role group, or site-scoped actor selected by business rules.
- **Notification Preference**: A future user-level or tenant-level setting that can adjust optional categories while preserving required account/security messages.

## Notification Event Matrix

| Event | Default Channel | Recipient | V1 Priority | Notes |
| --- | --- | --- | --- | --- |
| Passwordless sign-in link | Email | requesting email | High | Authentication email, not optional. |
| Team invite created | Email | invited email | High | Include workspace and role/site context. |
| Team invite resent | Email | invited email | High | Dedupe invite state; send fresh link. |
| Invite accepted | In-app/admin activity | inviter/admin later | Low | Email not required in V1. |
| Member deactivated | In-app/admin activity, optional email later | affected member/admin | Normal | V1 can focus on access state. |
| Workspace created | Email and in-app confirmation | creator/tenant owner | High | First-owner orientation; include app, website, and admin console context. |
| Signed in, no workspace | Email lifecycle nudge | signed-in user | Normal | Send once after the configured waiting period if no workspace exists. |
| Workspace has no site | Email lifecycle nudge and in-app setup card | tenant owner/admin | Normal | Send sparse reminders until first site exists, then suppress. |
| Violation assigned | Action item, future push | assignee | High | Email optional later if assignment is missed. |
| Violation submitted for review | Action item, future push | reviewer roles | High | Backend transition owns creation. |
| Violation sent back | Action item, future push | assignee/recent submitter | High | Include reason. |
| Violation closed | In-app/activity | assignee/reviewer later | Low | Email not required in V1. |
| Training assigned | Action item, future push | assignee | Normal | Email optional later. |
| Training overdue | Action item, future push/email digest later | assignee, manager escalation later | High | Avoid repeated spam. |
| Check assigned | Action item, future push | assignee | Normal | Include due date if present. |
| Check overdue | Action item, future push/email digest later | assignee, manager escalation later | High | Future digest candidate. |
| Billing trial ending | Email later | tenant owner/admin | High | RevenueCat/billing spec will refine. |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of account-access emails in test scenarios include tenant/workspace context, a clear call to action, and no ambiguous destination.
- **SC-001A**: 90% of first-time owner test recipients can identify the next setup step and where admin management belongs after reading the workspace-created message.
- **SC-001B**: Incomplete onboarding reminders are sent only to users/workspaces that still match the incomplete setup condition at delivery time.
- **SC-002**: A complete V1 workflow test matrix produces zero duplicate open action items for the same recipient/event/target.
- **SC-003**: Low-value events in the test matrix create no outbound email attempts by default.
- **SC-004**: Every V1 notification decision can be inspected as sent, failed, skipped, suppressed, or pending without reading raw application logs.
- **SC-005**: Staff and managers can open an actionable notification target from the app dashboard or inbox without first navigating broad lists.
- **SC-006**: Deactivated users receive no new operational notifications for the tenant after deactivation.

## Assumptions

- Existing action items remain the primary operational inbox model.
- Existing callable-owned workflow transitions remain the source of important action item changes.
- The email provider decision is separate from this product specification; the product contract should work with Firebase Auth emails, a transactional email provider, or later provider changes.
- Push notifications are not required for this first email strategy spec, but the model must not block future push.
- Billing emails will be refined in the RevenueCat/billing feature spec.
- Existing development test data can be cleaned up or reseeded if needed before pilot; production migration requirements must be explicit in future implementation plans.
