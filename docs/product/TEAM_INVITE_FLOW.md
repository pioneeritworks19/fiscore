# FiScore Team Invite Flow

## Purpose

This document defines the ongoing team invitation and membership lifecycle for FiScore version 1.

Unlike tenant onboarding, this is not a one-time setup flow. It is an ongoing operational workflow used when:

- new staff join
- managers add auditors
- team members change sites
- staff leave and need to be deactivated

This document should be read alongside:

- [USER_ROLES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\USER_ROLES.md)
- [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- [ONBOARDING_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\ONBOARDING_FLOW.md)

## Version 1 Principles

### 1. Team Invitation Is Ongoing

Inviting users should be treated as a normal operational workflow that can happen at any time after onboarding.

### 2. Email Is The Primary Invite Identifier

For version 1, FiScore should use email as the primary invitation and membership identifier.

Phone number may still exist in the user profile, but it should not be the primary invitation key in version 1.

Recommended version 1 position:

- invite by email
- phone number optional on profile
- phone may be used later for contact or reminders

### 3. Role Is Tenant-Wide, Site Access Can Be Narrower

In version 1:

- the user's role is assigned at tenant level
- site access may be restricted separately
- role does not vary by site within the same tenant

### 4. Invitation Should Be Lightweight

The inviter should only need to provide:

- email
- role
- site access

The invited user can complete or confirm their profile later.

### 5. Deactivation Should Preserve History

When a user leaves:

- access should be removed
- historical audits, responses, thread comments, and violation activity should remain preserved

## Who Can Invite

Version 1 allowed inviters:

- `admin`
- `manager`

## Where It Lives In The App

Recommended location:

- `More -> Team`

Recommended Team area sections:

- `Active`
- `Invited`
- `Inactive`

## Invitation Flow

```text
Open Team
-> Tap Invite User
-> Enter email
-> Choose role
-> Choose site access
-> Send invite
-> Invitation record created
-> User receives invitation
-> User signs in
-> User accepts invitation
-> Tenant membership becomes active
-> Site access becomes active
```

## Detailed Flow

## 1. Open Team Management

### Goal

Allow the inviter to manage users inside the tenant.

### Recommended visible data

- user name
- email
- role
- status
- assigned sites count or summary

### Recommended sections

- active members
- invited members
- inactive members

## 2. Start Invite

### Goal

Create a new pending invitation for a user.

### User inputs

- email address
- tenant role
- site access assignment

### Recommended version 1 role choices

- `admin`
- `manager`
- `auditor`
- `staff`

## 3. Site Access Assignment

### Goal

Define which sites the invited user can access.

### Recommended options

- one site
- multiple sites
- all sites where the inviter's permissions allow that pattern

### Important product rule

Site access should be assignment-based.

Even if role is tenant-wide, not every user must see every site.

## 4. Invitation Record Creation

### System actions

FiScore should create:

- tenant membership in invited or pending state
- site access assignment in pending or invited state if modeled separately
- invitation metadata including inviter and timestamps

### Recommended invitation status values

- `invited`
- `active`
- `inactive`
- `suspended`

## 5. Invitation Delivery

### Version 1 recommendation

FiScore should primarily support email-based invitation delivery.

The invitation should:

- identify the tenant
- identify the inviter if appropriate
- direct the user to sign in

Phone-based invite delivery can be considered later, but should not be the primary version 1 invite method.

## 6. User Accepts Invitation

### Goal

Convert an invited user into an active tenant member.

### User actions

1. user signs in with Google or Apple
2. FiScore detects pending invite for the email
3. user accepts the invitation

### System actions

FiScore should:

1. activate the tenant membership
2. activate site access assignments
3. route the user to the correct first landing experience

## 7. First Landing After Accept

Use the normal site-entry rules:

- if the user has access to exactly one site, open that site directly
- if the user has access to multiple sites, open the `Sites` summary list

## 8. Deactivation Flow

### Goal

Remove access for a user who leaves or should no longer operate in the tenant.

### Allowed actors

- admin
- manager

### System behavior

Deactivation should:

- remove current access
- preserve historical activity
- retain attribution on audits, thread entries, responses, and review history

### Important product rule

FiScore should not delete historical work just because a user is no longer active.

## 9. Recommended Team UI States

### Active

Users who currently have tenant access.

### Invited

Users who were invited but have not yet completed acceptance.

### Inactive

Users who previously had access but are now deactivated.

## 10. Recommended Data Model Direction

At minimum, the invitation flow should work with:

- `users/{userId}`
- `tenants/{tenantId}`
- `tenants/{tenantId}/members/{userId}`
- optional site-level membership records if site access is modeled separately

Suggested tenant membership invite-related fields:

- `emailSnapshot`
- `role`
- `status`
- `invitedBy`
- `invitedAt`
- `joinedAt`

## Future Enhancements

Potential later improvements:

- phone-based invitation
- resend invite
- invite expiration rules
- invitation reminder notifications
- role-change approval guardrails
- bulk import or bulk invite

## Summary

FiScore version 1 should treat team invitation as an ongoing tenant-management workflow. Invitations should be email-first, lightweight, and role-aware, with separate site access assignment where needed. Deactivation should remove access without removing historical accountability.
