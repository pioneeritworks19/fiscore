# Data Model: Notifications and Email Strategy

## Notification Event

Represents one product decision that may result in email delivery, future push delivery, an action item, or an intentional skip.

Suggested path:

- Tenant-scoped: `tenants/{tenantId}/notificationEvents/{eventId}`
- Pre-tenant lifecycle: `users/{userId}/notificationEvents/{eventId}` when no tenant exists yet

Fields:

- `eventType`: string, canonical event name such as `team_invite_created`, `workspace_created`, `signed_in_no_workspace`
- `category`: `account_access`, `onboarding`, `operational`, `billing`, `system`
- `tenantId`: string or null for pre-tenant lifecycle
- `siteId`: string or null
- `targetType`: string such as `invite`, `tenant`, `site`, `violation`, `training_assignment`, `audit_assignment`
- `targetId`: string or null
- `targetPath`: string or null
- `recipientUserId`: string or null
- `recipientEmail`: string or null
- `recipientRoleSnapshot`: string or null
- `channel`: `email`, `in_app`, `push`, `skip`
- `status`: `pending`, `sent`, `failed`, `skipped`, `suppressed`
- `dedupeKey`: string
- `reason`: short system-readable reason for sent/skipped/suppressed
- `templateId`: string or null
- `locale`: string, default `en`
- `createdAt`: timestamp
- `updatedAt`: timestamp
- `sentAt`: timestamp or null
- `failedAt`: timestamp or null
- `suppressedAt`: timestamp or null

Validation:

- `dedupeKey` must be deterministic for event/target/recipient/channel.
- `tenantId` is required for tenant operational events.
- `recipientEmail` is required for email events unless `recipientUserId` can be resolved before delivery.
- `status` transitions are append/update only; records should not be deleted during normal operation.

## Delivery Attempt

Represents a concrete channel attempt for a notification event.

Suggested path:

- `tenants/{tenantId}/notificationEvents/{eventId}/deliveryAttempts/{attemptId}`
- `users/{userId}/notificationEvents/{eventId}/deliveryAttempts/{attemptId}` for pre-tenant lifecycle

Fields:

- `channel`: `email` or future `push`
- `provider`: string such as `firebase_auth`, `resend`, `sendgrid`, or `noop`
- `providerMessageId`: string or null
- `status`: `pending`, `accepted`, `failed`, `suppressed`
- `recipientEmail`: string or null
- `attemptedAt`: timestamp
- `completedAt`: timestamp or null
- `errorCode`: string or null
- `errorMessage`: short string or null

Validation:

- Do not store secrets or full provider payloads.
- Provider failure text should be short and support-safe.

## Notification Template

Represents a product-owned message template by event/channel/locale.

Suggested path:

- `notificationTemplates/{templateId}` or config-managed code/constants for V1

Fields:

- `templateId`
- `eventType`
- `channel`
- `locale`
- `subject`
- `bodyText`
- `bodyHtml`
- `requiredVariables`
- `status`: `draft`, `active`, `retired`
- `version`

V1 recommendation:

- Keep templates in code/config first for version control.
- Move to Firestore only when non-developer template management is needed.

## Notification Preference

Represents future user-level channel/category preferences.

Suggested path:

- `users/{userId}/notificationPreferences/{preferenceId}` or compact map on `users/{userId}`

Fields:

- `category`
- `emailEnabled`
- `pushEnabled`
- `updatedAt`

V1 recommendation:

- Implement safe defaults.
- Do not block required authentication, account access, or security emails.

## Action Item

Existing read model at `tenants/{tenantId}/actionItems/{actionItemId}`.

This feature does not replace action items. It may add notification-event links later:

- `notificationEventIds`: optional array or map
- `lastNotifiedAt`: optional timestamp

## Query and Index Expectations

Expected Firestore query shapes:

- tenant notification events by `status`, ordered by `createdAt`
- tenant notification events by `eventType`, ordered by `createdAt`
- tenant notification events by `recipientUserId`, ordered by `createdAt`
- tenant notification events by `targetType` and `targetId`
- user pre-tenant notification events by `status`, ordered by `createdAt`

Indexes should be added when implementation introduces these queries.
