# FiScore Audit UX Guidelines

## Purpose

This document defines the intended user experience behavior for live audit execution in FiScore.

It exists to keep the audit experience guided, fast, and operational rather than feeling like a large static form.

## UX Principles

The audit experience should feel:

- guided
- efficient
- low-friction
- mobile-first
- operational

The audit experience should not feel:

- form-heavy
- deeply nested
- confusing when triggers fire
- disruptive during response entry

## Main Audit Flow

Recommended flow:

`Select Audit -> Checklist -> Trigger Questions -> Violations or Actions -> Review -> Submit`

## Trigger Behavior

Trigger behavior should expand inline.

The user should not be navigated away from the current audit context just because a trigger rule fired.

Recommended behavior:

- show trigger result inline
- preserve surrounding section and question context
- keep the reason for the trigger visible
- allow the user to complete required follow-up in place

## Required UX Rules

### 1. Explain Why Triggered

When a trigger fires, the UI should show why it happened.

Examples:

- failed answer
- threshold exceeded
- prior answer combination matched a rule

### 2. Keep Hierarchy Visible

The user should continue to understand:

- which section they are in
- which question triggered the behavior
- which follow-up items belong to that question

### 3. Progressive Disclosure

The audit should reveal complexity only when needed.

Examples:

- follow-up questions appear only when relevant
- evidence requirements appear when triggered
- suggested actions or training appear only when relevant

### 4. Collapse Support

Triggered blocks should support collapse state after the user has understood or completed them.

This helps reduce visual overload during long audits.

### 5. Inline Required Inputs

When a trigger requires:

- comment
- photo
- severity confirmation
- suggested remediation review

those inputs should be completed inline within the audit flow whenever practical.

## Suggested Inline Intelligence

The audit experience may surface contextual assistance such as:

- suggested fixes
- risk explanation
- repeat issue alert
- recommended training
- suggested action-plan direction

Version 1 should keep this useful and concise rather than noisy.

## Visual Behavior Expectations

Recommended interface patterns:

- inline expansion
- progressive disclosure
- grouped follow-up blocks
- bottom sheets for supporting detail when needed
- lightweight modals for narrow decisions

Avoid:

- deep nested navigation
- surprise screen transitions
- overloaded full-screen forms
- hidden trigger behavior

## Offline UX Expectations

The live audit experience should still communicate clearly when offline.

The user should be able to tell:

- that responses are saved locally
- whether evidence is pending upload
- whether the audit is still in progress locally

## Summary

FiScore audit UX should behave like a guided operational workflow. Triggered logic should expand inline, remain explainable, preserve context, and use progressive disclosure so auditors can move quickly without feeling lost inside a generic form experience.
