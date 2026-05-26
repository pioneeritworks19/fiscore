# Notification Flow

## Purpose

This document defines the notification model for FiScore version 1.

It focuses on operational notifications that help users take action without creating noise.

## Notification Principles

FiScore notifications should be:

- operational
- action-oriented
- low-noise
- role-aware
- linked to the correct site and record context

FiScore notifications should not behave like a social chat stream.

## Version 1 Notification Strategy

Version 1 should prioritize:

- in-app notifications
- mobile push notifications for important action items
- email only where it clearly fits, such as invitations and possibly future digest use cases

Recommended default:

- invites by email
- operational work notifications by in-app plus push

## Core Notification Channels

### 1. In-App Notifications

Use for:

- user work queue items
- reminders
- manager review requests
- status updates that should be visible without being disruptive

### 2. Push Notifications

Use for:

- assigned work
- due soon or overdue work
- review requests that need attention

Push should be selective in version 1.

### 3. Email

Use for:

- tenant invitations
- optional later digest summaries
- optional later administrative summaries

Version 1 should avoid heavy operational email noise.

## Notification Priority Model

Recommended priority levels:

- `high`
- `normal`
- `low`

Suggested interpretation:

- `high`
  requires prompt user attention
- `normal`
  useful action reminder
- `low`
  informational or secondary visibility

## Core Notification Events

Version 1 should support the following event categories.

### 1. Violation Assigned

### Trigger

- a violation is assigned to a user

### Recipients

- assigned user

### Recommended channels

- in-app
- push

### Priority

- high

### Deep link target

- violation detail screen

## 2. Violation Submitted For Review

### Trigger

- user submits a violation for review

### Recipients

- manager responsible for review

### Recommended channels

- in-app
- push

### Priority

- high

### Deep link target

- manager review view for that violation

## 3. Violation Sent Back

### Trigger

- manager rejects a response or requests more work

### Recipients

- assigned user
- recent contributor if needed by policy later

### Recommended channels

- in-app
- push

### Priority

- high

### Deep link target

- violation detail screen with response context

## 4. Training Assigned

### Trigger

- manager assigns training to a user

### Recipients

- assigned user

### Recommended channels

- in-app
- push

### Priority

- normal

### Deep link target

- assigned training detail screen

## 5. Training Due Soon

### Trigger

- training assignment is approaching due date

### Recipients

- assigned user

### Recommended channels

- in-app
- push when timing matters

### Priority

- normal

### Recommended timing

- one reminder on the due day or the day before, depending on final policy

## 6. Training Overdue

### Trigger

- training due date has passed and assignment is not completed

### Recipients

- assigned user
- optionally manager later if escalation is added

### Recommended channels

- in-app
- push

### Priority

- high

### Deep link target

- assigned training detail screen

## 7. Audit Due Soon

### Trigger

- scheduled audit due date is approaching

### Recipients

- assigned auditor or manager

### Recommended channels

- in-app
- push

### Priority

- normal

### Recommended timing

- one reminder before due time according to final schedule policy

## 8. Audit Overdue

### Trigger

- scheduled audit is overdue and not completed

### Recipients

- assigned auditor
- manager

### Recommended channels

- in-app
- push

### Priority

- high

### Deep link target

- scheduled audit or audit list screen for that site

## 9. Team Invitation

### Trigger

- admin or manager invites a user

### Recipients

- invited user

### Recommended channels

- email

### Priority

- high

### Deep link target

- invitation acceptance or sign-in flow

## Recommended Version 1 Non-Goals

Version 1 should avoid:

- push for every thread comment
- push for every minor status change
- social-style activity streams
- noisy batch spam
- complex preference management before the main workflow is proven

## Reminder Cadence Guidance

Version 1 reminder behavior should stay simple.

Recommended direction:

- notify at assignment time
- notify again when due soon if the item is still incomplete
- notify when overdue

Avoid aggressive repeated push loops in version 1.

## Notification Content Guidelines

Every notification should answer:

- what happened
- why it matters
- what the user should do next

Good examples:

- `Temperature Control violation needs your response`
- `Handwashing Basics training is due today`
- `2 audits are overdue at Downtown Site`
- `A violation is waiting for your review`

## Site Context Expectations

Notifications should preserve site context clearly.

Recommended visible context:

- site name
- issue type or work type
- due state when relevant

This matters because FiScore users may work across multiple sites.

## Notification Inbox Model

Version 1 should include an in-app notification inbox or activity view.

Recommended capabilities:

- unread versus read state
- open target record from notification
- show site context
- show timestamp
- group by actionable recency where useful

### Action Item Implementation Boundary

Operational inbox rows should be stored as action items at:

`tenants/{tenantId}/actionItems/{actionItemId}`

Business records remain authoritative. Action items are a read-optimized queue
for dashboards and inbox screens, with fields such as:

- `type`
- `status`
- `priority`
- `recipientUserId`
- `siteId`
- `targetType`
- `targetId`
- `title`
- `detail`
- `dueAt`
- `dueState`
- `readAt`
- `completedAt`

Action items should be created and completed by trusted callable Cloud
Functions at meaningful workflow transitions rather than by Firestore document
triggers:

- submitting a violation for review creates reviewer action items
- sending a violation back completes review items and creates staff follow-up
- closing a violation completes its open review action items
- assigning training creates an assignee action item
- completing or cancelling training completes its action item
- a scheduled function marks incomplete training action items overdue
- assigning a one-time internal check creates an assignee action item
- starting an unassigned internal check creates a quiet self-owned action item
  so the user can resume it from `My checks`
- starting, reassigning, completing, or cancelling that check updates its
  action item
- a scheduled function marks incomplete assigned-check action items overdue

Frequent collaborative operations such as draft editing, discussion notes, and
photo uploads remain direct app writes. Push delivery can later consume action
items without changing workflow ownership.

## Delivery and Deep Linking Recommendations

Notifications should deep link directly into the relevant workflow when possible.

Recommended targets:

- violation detail
- manager review view
- assigned training detail
- assigned check within the site audit workflow

Avoid landing users on overly broad home screens when a more direct target exists.

## Optional Future Enhancements

Later enhancements may include:

- digest summaries
- notification preferences by category
- escalation to manager for overdue staff training or assigned checks
- mention notifications in violation threads
- daily operational summaries by site

## Summary

FiScore notifications in version 1 should stay tightly focused on operational action: assigned violations, review requests, training assignments, due and overdue training, and due or overdue audits. The product should favor in-app plus selective push notifications, preserve site context, and avoid noisy chat-like behavior.
