# Quickstart: Notification and Email Implementation Validation

## Preconditions

- Firebase dev project is available.
- Firebase Auth email-link sign-in is enabled.
- At least one tenant owner/admin test user exists.
- Transactional email provider is configured in sandbox/test mode, or the provider adapter is set to `noop` with delivery attempts recorded.

## Validation Scenarios

### 1. Team invite email

1. Sign in as tenant owner/admin.
2. Invite a new staff email.
3. Verify invite document remains pending.
4. Verify notification event exists with:
   - `eventType = team_invite_created`
   - `channel = email`
   - `status = sent` or provider sandbox status
   - tenant/workspace context
5. Verify a delivery attempt exists.
6. Verify invited user can sign in and accept invite.

### 2. Resend invite

1. Resend the pending invite.
2. Verify no duplicate active invite is created.
3. Verify a resend notification event or delivery attempt is recorded.
4. Verify dedupe rules suppress accidental rapid repeats if configured.

### 3. Workspace-created orientation

1. Sign in with a fresh owner account.
2. Create a new workspace.
3. Verify `workspace_created` notification event is recorded.
4. Verify copy includes:
   - workspace name
   - add/link restaurant next step
   - FiScore app return path
   - website/help mention
   - admin console mention when available

### 4. Signed in but no workspace

1. Create/sign in a user with no workspace.
2. Simulate reminder eligibility.
3. Run scheduled reminder function or helper.
4. Verify one setup reminder is recorded/sent.
5. Create workspace and rerun.
6. Verify stale reminder is skipped/suppressed.

### 5. Workspace created but no site

1. Create workspace with zero sites.
2. Simulate reminder eligibility.
3. Run scheduled reminder function or helper.
4. Verify one add-first-restaurant reminder is recorded/sent.
5. Add a site and rerun.
6. Verify reminder is skipped/suppressed.

### 6. Operational action items stay in app

1. Assign training, assign check, submit violation for review, and send violation back.
2. Verify existing action items are created or updated.
3. Verify no email delivery attempts are created for low-value operational events unless explicitly enabled later.

## Suggested Local Checks

From `apps/fiscore_app/functions`:

```powershell
node --check index.js
node --check notifications.js
```

From `apps/fiscore_app` only when app UI files are touched:

```powershell
flutter analyze
```
