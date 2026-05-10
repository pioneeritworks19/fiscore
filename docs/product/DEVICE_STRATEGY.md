# Device Strategy

## Purpose

This document defines the recommended device strategy for FiScore version 1.

It clarifies which flows should be:

- mobile-first
- tablet-optimized
- browser-friendly
- browser-preferred

The goal is to avoid forcing every workflow into the same device pattern when the real usage context differs.

## Core Recommendation

FiScore should be:

- phone-first for field execution
- tablet-strong for audits and operational review
- browser-friendly for management and administration
- browser-preferred for authoring-heavy workflows

This supports the real-world split between:

- operational work done on site
- configuration and administrative work done at a desk

## Version 1 Position

Version 1 should not require full browser parity for every mobile workflow.

Instead:

- core execution workflows should be excellent on phone and tablet
- browser should support key management and review workflows
- authoring-heavy flows should lean toward browser usability even if they remain technically accessible elsewhere later

## Device Support Matrix

| Flow | Primary Device | Secondary Device | Reason | Recommended V1 Support |
|---|---|---|---|---|
| Sign in and onboarding | Phone | Browser | Simple guided setup, often first contact on mobile | Full mobile, light browser |
| Add first site | Phone | Browser | Can happen during onboarding, but also manageable on larger screens | Full mobile, browser-friendly |
| Add site after onboarding | Browser | Phone | Managers may add sites from office/admin context, but mobile should still support it | Full mobile, browser-friendly |
| Site portfolio landing page | Phone | Browser | Users need quick portfolio visibility everywhere | Full on both |
| Site switching | Phone | Browser | Lightweight context switch, frequent action | Full on both |
| View public inspections | Phone | Browser | Review may happen on site or at desk | Full on both |
| Upload onsite inspection report | Phone | Browser | Camera/scanner and quick upload are mobile-friendly | Mobile-first, browser-supported |
| Start audit | Phone | Tablet | Usually operational and on site | Full mobile/tablet |
| Perform audit | Tablet | Phone | Long checklists, evidence capture, and navigation benefit from tablet; phone still required | Full mobile/tablet, browser not required in v1 |
| Save/resume audit | Tablet | Phone | Audit continuity is a field workflow | Full mobile/tablet |
| Review and submit audit | Tablet | Phone | Summary review is clearer on tablet but still must work on phone | Full mobile/tablet |
| Lightweight audit summary | Tablet | Phone | Often shown on site immediately after completion | Full mobile/tablet |
| View final audit report | Browser | Tablet | Final reports are easier to review on larger screens | Browser-friendly, mobile readable |
| Create manual violation during audit | Phone | Tablet | Quick capture with photo evidence is a field workflow | Full mobile/tablet |
| Create manual violation against site | Phone | Browser | Quick operational capture on phone, but browser also useful | Full mobile, browser-friendly |
| Work a violation thread | Phone | Browser | Quick updates happen on phone; managers may review on desktop | Full on both |
| Edit structured violation response | Phone | Browser | Field updates on phone, richer review/edit on larger screens | Full mobile, browser-friendly |
| Manager review and close violation | Phone | Browser | Must be possible on mobile, but browser is comfortable for review | Full on both |
| Reopen violation | Phone | Browser | Short decision workflow | Full on both |
| View assigned training | Phone | Browser | Assignees need simple access anywhere | Full on both |
| Complete training | Phone | Tablet | Short content works well on phone; tablet is also good for supervisors or shared devices | Full mobile/tablet, browser optional |
| Assign training | Browser | Phone | Managers may do this from violation or audit review; browser gives better context, mobile still important | Full mobile, browser-friendly |
| Create tenant training | Browser | Tablet | Authoring benefits from more space and structured editing | Browser-preferred |
| Edit tenant training | Browser | Tablet | Editing topics and quick checks is more comfortable on larger screens | Browser-preferred |
| Configure quick checks | Browser | Tablet | Small authoring builder is easier on larger screens | Browser-preferred |
| Browse FiScore training library | Browser | Phone | Good on both; browser is better for review, phone for quick assignment context | Full on both |
| Team management and invites | Browser | Phone | Admin workflows often easier at desk, but mobile must still work | Browser-friendly, mobile-supported |
| Role and site assignment | Browser | Phone | More context and less error-prone on larger screens | Browser-preferred, mobile-supported |
| Checklist authoring | Browser | Tablet | Complex configuration, many sections/questions/rules | Browser-preferred |
| Checklist versioning and publish | Browser | Tablet | Administrative, high-precision workflow | Browser-preferred |
| Scoring rule configuration | Browser | Tablet | Better on larger screen due to complexity | Browser-preferred |
| Analytics and reporting | Browser | Phone | Managers often need wider comparative views | Browser-preferred, mobile summary supported |
| Notification inbox | Phone | Browser | Operational reminders should be easy everywhere | Full on both |

## Flow Grouping Recommendation

### Mobile-First Flows

These should be excellent on phone:

- audits
- violations
- training completion
- public inspection review
- notification handling

### Tablet-Important Flows

These should be especially strong on tablet:

- long audit execution
- section navigation
- audit summary review
- violation detail with thread plus response context
- training playback

### Browser-Friendly Flows

These should be comfortably usable on browser in version 1:

- site portfolio review
- inspections
- violations
- audit result review
- training assignment
- team management

### Browser-Preferred Flows

These should lean clearly toward browser:

- checklist authoring
- training authoring
- quick-check setup
- scoring configuration
- richer analytics
- broader administration

## Design Implications

### Phone

Phone design should optimize for:

- fast capture
- clear next actions
- minimal typing when possible
- evidence capture
- short review loops

### Tablet

Tablet design should optimize for:

- longer sessions
- dual-pane feeling where possible
- easier section and progress navigation
- richer review without feeling cramped

### Browser

Browser design should optimize for:

- content authoring
- comparisons
- administration
- multi-record review
- reporting

## Practical Product Rule

Use this rule when prioritizing implementation:

- execution workflows: mobile-first
- authoring workflows: browser-preferred
- review workflows: support both
- administration workflows: browser-friendly, with important mobile support where needed

## Summary

FiScore should not be treated as purely app-only or purely browser-first. The best version 1 strategy is a mobile-first operational product with strong tablet support, combined with a lightweight browser companion for management, review, and authoring-heavy workflows.
