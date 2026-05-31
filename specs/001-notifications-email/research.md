# Research: Notifications and Email Strategy

## Decision: Keep operational notifications as action items first

**Rationale**: FiScore already has tenant-scoped action items for assigned fixes, review queues, training, and checks. Emailing every operational event would create noise for restaurant staff and duplicate dashboard behavior.

**Alternatives considered**:

- Email every assignment/status change: rejected because it creates noise and weakens the app's daily-work model.
- Push-first implementation: deferred until mobile release plumbing is ready.

## Decision: Use transactional email only for access and onboarding in the first slice

**Rationale**: Sign-in links, team invites, workspace-created orientation, and stalled onboarding nudges are account/lifecycle events where email is expected. These messages help people get into FiScore or finish setup.

**Alternatives considered**:

- Full lifecycle marketing system: rejected for V1 because it adds campaign complexity before pilot.
- No onboarding reminders: rejected because self-service owners can abandon setup before first value.

## Decision: Introduce a notification module and provider adapter in Cloud Functions

**Rationale**: The app must not send email directly. A backend module can validate tenant/site/role context, apply dedupe, record delivery status, and swap email providers later without rewriting team/tenant workflows.

**Alternatives considered**:

- Embed provider calls inside `team.js` and `tenants.js`: rejected because delivery logic would fragment quickly.
- Firestore triggers for email: rejected because FiScore's constitution favors explicit business functions over trigger side effects for important state transitions.

## Decision: Record notification decisions even when delivery is skipped

**Rationale**: Support needs to distinguish sent, failed, skipped, and suppressed. This also proves that low-noise rules are working and prevents guessing from raw function logs.

**Alternatives considered**:

- Only log provider errors: rejected because skipped/suppressed decisions are product behavior and need visibility.
- Store logs only in Cloud Logging: rejected because app/admin support views need queryable tenant context.

## Decision: Setup nudges are lifecycle reminders, not operational action items

**Rationale**: "No workspace" and "workspace has no site" are onboarding states, not daily restaurant work. They should not appear in My checks, My fixes, or manager queues.

**Alternatives considered**:

- Create action items for setup reminders: rejected because users without a site/workspace may not have meaningful action inbox context yet.
- Repeat daily setup reminders: rejected for V1 to avoid spam.

## Decision: Use code-owned localized templates for V1 emails

**Rationale**: FiScore is still converging on its self-service onboarding and access flows. Code-owned templates keep subject/body copy, variables, localization, and provider behavior version-controlled and testable with the Cloud Functions changes. This also avoids making the first email provider the source of truth for product copy.

**Alternatives considered**:

- Provider-managed templates: deferred because it couples product copy to a provider console and makes code review harder.
- Firestore-managed tenant-editable templates: rejected for V1 because customer-editable email copy adds moderation, preview, permissions, and support complexity before pilot.

## Decision: Use tenant context, not tenant branding, in V1

**Rationale**: Users should know why they received the message and which workspace it belongs to, but V1 does not need customer logos, colors, sender domains, or branding controls. Copy such as "FiScore on behalf of Kannappan Hospitality" gives enough context while preserving product trust and implementation simplicity.

**Alternatives considered**:

- Full tenant branding: deferred until FiScore has a clear paid plan need and support process for branded email assets.
- FiScore-only emails with no tenant context: rejected because invited staff may not recognize why they are receiving an invite or setup message.

## Decision: Localize FiScore-controlled copy, not customer-entered values

**Rationale**: The app already has English/Spanish localization direction. Emails should use the same recipient-language-first behavior for system copy, while tenant names, user names, comments, site names, and authored content remain exactly as entered.

**Alternatives considered**:

- English-only emails: acceptable for a prototype but not aligned with mobile-first staff usage.
- Live translation of tenant/user-entered content: rejected because it is not a V1 business need and can distort compliance-relevant wording.
