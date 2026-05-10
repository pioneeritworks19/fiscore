# FiScore Training Module

## Purpose

This document defines the Training module for FiScore as an operational behavior and remediation capability rather than a generic learning management system.

The module exists to help restaurants improve behavior after audits, violations, and operational issues.

## Positioning

FiScore training should be:

- operational
- short
- relevant to real issues
- linked to site performance

FiScore training should not become a traditional LMS with broad academic course management as the primary focus.

## Product Loop

The Training module participates in the core FiScore loop:

`Audit -> Violation -> Discussion -> Structured Response -> Training -> Improved Behavior -> Better Audit`

This loop should remain visible in product design, workflows, and reporting.

## Training Types

FiScore should support two main training types.

FiScore should also support two training content sources:

- `library training`
  FiScore-provided training available across tenants through the FiScore Library
- `tenant training`
  tenant-created training available only within that tenant

When a tenant starts from FiScore Library content, version 1 should support two tenant-facing modes:

- `Synced from Library`
- `Created from Library`

`Synced from Library` means the tenant has a tenant-owned training record linked to the source library item and can later adopt newer library versions.

`Created from Library` means the tenant receives a one-time tenant-owned copy with no future sync behavior.

## Training Versioning

Training should support version stability, but with lighter governance than audit checklists.

### Why it matters

If training content changes after users have already been assigned or have started it, FiScore should avoid silently changing what those users are expected to complete.

### Recommended version 1 rules

- training should include a `version` field
- draft or not-yet-assigned training may be edited more freely
- once training is active and has assignments, meaningful content changes should create a new version for future assignments
- existing assignments should remain tied to the version they were assigned
- in-progress users should finish the version they started
- completed history should remain tied to the version that was completed
- library-linked upgrades should create or activate a newer tenant version for future assignments rather than silently modifying in-progress or completed assignments

### Version 1 positioning

This is lighter than checklist versioning:

- no need for heavy compliance-grade version control at first
- but assignment-to-version stability should still be preserved

### 1. Full Courses

Used for:

- onboarding
- certification preparation
- annual compliance refreshers
- broader operational education

Typical characteristics:

- multiple topics
- longer total duration
- optional assessment or knowledge check
- completion tracked at assignment level

### 2. Micro-Learning Topics

Used for:

- violation remediation
- targeted coaching
- just-in-time learning
- focused retraining after audit findings

Typical characteristics:

- one focused topic
- short duration
- operationally specific
- optional quick check

## Core Requirements

The Training module should support:

- manager-assigned training
- training linked to violations
- training linked to audits when relevant
- training categorized by risk area
- assignment due dates
- overdue assignment states
- completion tracking
- optional quick knowledge checks
- training progress tracking by user
- training progress tracking by site

## Assignment Model

Version 1 should assume that managers are the primary human assigners of training.

The system may recommend training based on audit findings, violations, and repeat issues, but hard automatic assignment should wait unless explicitly approved later.

### Assignment Sources

Training may be assigned from:

- a manager manually choosing training for a user
- a violation thread recommending a training topic
- an audit finding recommending a training topic
- a repeat issue or risk pattern surfacing suggested training

## Training Linkage

Training should be linkable to:

- violation id
- audit id
- checklist question or risk area when appropriate
- site id
- assigned user id

This linkage is important so FiScore can connect training activity back to compliance outcomes.

Version 1 recommendation:

- `violationId` should be the main issue-level training link
- `auditId` should be kept when the assignment comes from audit context
- `riskArea` should primarily come from training metadata or be system-derived from the source context
- users should not normally be asked to type a risk area during assignment

## Assignment States

Recommended assignment states:

- `assigned`
- `in_progress`
- `completed`
- `overdue`
- `cancelled`

## Completion Model

The system should support simple, operational completion tracking.

Completion may include:

- started at
- completed at
- completion status
- optional quick check result
- manager-visible completion history

Version 1 should keep completion simple and avoid complex certification engines unless required later.

## Knowledge Checks

FiScore may support lightweight knowledge checks.

Recommended version 1 position:

- optional
- short
- operationally relevant
- tied to the training topic rather than formal exam infrastructure
- simple to configure

Examples:

- one or two confirmation questions
- quick procedural verification
- acknowledgment that the user reviewed the content

Recommended setup model:

- toggle quick check on or off
- allow 1 to 3 simple questions
- support `true_false` or `single_choice`
- allow one correct answer per question
- allow optional explanation text

## Reporting Expectations

Training reporting should support:

- assigned versus completed training
- overdue training by site
- overdue training by user
- training linked to violations
- training linked to repeat findings
- review of whether later audits improved after training

## Scope Guardrails

FiScore training should avoid turning into:

- badge systems
- leaderboards
- playful reward loops
- academic course management
- noisy social-learning experiences

The module should stay close to operational accountability and measurable improvement.

## Future Enhancements

Potential later additions:

- richer quizzes
- multilingual content
- acknowledgments and signatures
- certification-style workflows
- annual retraining cycles

## Summary

FiScore's Training module should be an operational remediation capability that helps sites improve behavior after audits and violations. It should support full courses and micro-learning, keep assignments manager-driven in version 1, link training directly to real operational issues, and measure whether training contributes to better future audit outcomes.
