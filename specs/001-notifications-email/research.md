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
