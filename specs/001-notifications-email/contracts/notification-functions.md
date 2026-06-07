# Contracts: Notification and Email Functions

These contracts describe business boundaries for implementation. Exact callable names can be adjusted during implementation if the behavior remains equivalent.

## Shared Backend Notification API

### `recordNotificationDecision(input)`

Internal helper used by callable and scheduled functions.

Input:

- `eventType`
- `category`
- `tenantId`
- `siteId`
- `targetType`
- `targetId`
- `targetPath`
- `recipientUserId`
- `recipientEmail`
- `recipientRoleSnapshot`
- `tenantNameSnapshot`
- `channel`
- `dedupeKey`
- `templateId`
- `templateData`
- `locale`
- `reason`

Behavior:

- validates required event/channel/recipient fields
- checks dedupe/suppression rules
- resolves/falls back locale when caller does not provide one
- writes a notification event
- returns `{eventId, status, suppressed}`

Errors:

- `invalid-argument` for missing event or recipient context
- `permission-denied` if caller workflow did not validate tenant context
- `internal` only for unexpected persistence failures

## `sendEmailForNotification(eventRef)`

Internal helper called after a notification decision is recorded.

Behavior:

- loads template
- renders localized subject/body from safe variables
- calls provider adapter
- records delivery attempt
- updates notification event status

Errors:

- provider failures are recorded as failed delivery attempts
- caller receives failure only when the surrounding business action must fail

## `receiveResendWebhook`

HTTP function in `apps/fiscore_app/functions/notifications.js`.

Behavior:

- accepts Resend/Svix signed webhook POST requests
- verifies `svix-id`, `svix-timestamp`, and `svix-signature` using the
  `RESEND_WEBHOOK_SECRET` Firebase secret
- records a top-level provider webhook event by `svix-id` for idempotency
- maps Resend email events into `providerDeliveryStatus`
- updates the matching notification event and delivery attempt by Resend
  provider message id
- preserves FiScore notification `status` as the business send state while
  storing provider mailbox status separately

Errors:

- `401` for missing or invalid webhook signature
- `405` for unsupported methods
- unmatched Resend message ids are recorded as webhook events with no matching
  notification instead of failing the webhook

## Existing Callable Integration Points

### `sendPasswordlessSignInLink`

Callable in `apps/fiscore_app/functions/auth.js`.

Notification behavior:

- generates the Firebase Auth email sign-in link on the backend
- records/sends `passwordless_sign_in_link` through the notification adapter
- uses Resend when `FISCORE_EMAIL_PROVIDER=resend`
- tenant-scopes the notification when the email matches a pending invite or
  active member, otherwise writes a global pre-tenant notification event
- does not dedupe repeated requests so users can request a fresh sign-in link

### `createTenantAndOwner`

Existing callable in `apps/fiscore_app/functions/tenants.js`.

Notification behavior:

- after tenant/member/user creation succeeds, record/send `workspace_created`
- recipient is the creator/tenant owner
- email identifies FiScore as sender, includes workspace name, next step to add/link restaurant, app link, website/help link, and admin console mention when available

### `createTenantInvite`

Existing callable in `apps/fiscore_app/functions/team.js`.

Notification behavior:

- after invite creation succeeds, record/send `team_invite_created`
- recipient is invited email
- email identifies FiScore as sender, includes workspace name, role/site context, and sign-in/join CTA

### `resendTenantInvite`

Existing callable in `apps/fiscore_app/functions/team.js`.

Notification behavior:

- validate invite remains pending
- record/send `team_invite_resent`
- preserve original invite state; do not create duplicate invite

### `deactivateTenantMember`

Existing callable in `apps/fiscore_app/functions/team.js`.

Notification behavior:

- V1 may record an access-change notification decision
- direct email is optional unless product copy makes it required
- operational action notifications must stop for inactive member

## Scheduled Lifecycle Integration Points

### `sendNoWorkspaceSetupReminders`

Scheduled function candidate.

Behavior:

- find users who signed in or registered but have no active tenant after the configured waiting period
- re-check condition at delivery time
- send at most one reminder per dedupe window
- record skipped/suppressed decisions

### `sendNoSiteSetupReminders`

Scheduled function candidate.

Behavior:

- find active tenants with `activeSiteCount == 0` after the configured waiting period
- send to tenant owner/admin recipients
- re-check site count at delivery time
- suppress once first site exists

## Non-Email Operational Events

The following remain action-item-first in V1:

- violation assigned
- violation submitted for review
- violation sent back
- training assigned
- training overdue
- audit/check assigned
- audit/check overdue

Future push can consume the same event/action data.

## Template Rendering Requirements

V1 email templates are code-owned inside the notification module.

- render subject, text body, and HTML body from the same safe template data
- support English and Spanish FiScore-controlled copy
- choose locale from recipient preference, then future tenant default, then English fallback
- preserve tenant names, site names, user names, comments, and authored content exactly as entered
- include FiScore product identity and tenant/workspace context when available
- do not require tenant-managed logos, colors, sender domains, or custom branding in V1
