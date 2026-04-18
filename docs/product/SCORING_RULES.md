# FiScore Scoring Rules

## Purpose

This document defines how FiScore should calculate audit scores and grades for checklist-based audits. The goal is to provide a scoring model that is flexible enough for different audit programs while remaining transparent, predictable, and traceable for restaurant teams and administrators.

FiScore should support checklist-specific scoring. Each audit checklist template may define its own sections, questions, response options, weights, grade thresholds, and critical-response rules. This allows different audit types to reflect different operational priorities and compliance standards.

## Core Principles

### 1. Checklist-Specific Scoring

Scoring is not global across the platform. Every audit checklist template can define its own scoring logic.

A checklist may vary by:

- section structure
- question set
- response types
- scoring weights
- point values
- grade thresholds
- critical question rules
- grade caps or overrides

### 2. Score and Grade Are Related but Distinct

FiScore should calculate:

- `Score`: a numeric percentage representing overall audit performance
- `Grade`: a text-based outcome representing the compliance or quality result

In many cases, grade will be derived from score thresholds. However, some responses may carry enough significance to reduce or cap the final grade even if the numeric score remains high.

### 3. Transparent Results

Users should be able to understand:

- how the score was calculated
- which questions affected the score
- which responses triggered violations
- whether any critical response changed the final grade

### 4. Historical Accuracy

Scoring logic should be versioned with the checklist template. If a checklist changes later, past audit results must still reflect the scoring configuration that was active when the audit was completed.

## Scoring Model Overview

Each completed audit should produce a result snapshot containing:

- checklist id
- checklist version
- scoring configuration version
- total earned points
- total possible points
- score percentage
- default grade from score thresholds
- final grade after rule adjustments
- any triggered critical rules
- explanation summary

## Scoring Building Blocks

### Checklist Template

Each audit checklist template should define:

- checklist name
- checklist version
- sections
- questions
- response options
- scoring configuration
- grade configuration
- critical-response rules

### Section

Sections organize the audit and may optionally contribute to scoring weights.

A section may define:

- display order
- section name
- optional section weight
- optional section scoring behavior

### Question

Each question may have its own scoring behavior.

Suggested question properties:

- question id
- section id
- prompt
- answer type
- required flag
- weight
- maximum points
- scoring method
- critical flag
- violation trigger rules
- follow-up question rules

### Response Option

Each response option may map to a score outcome.

Examples:

- `Compliant` = full points
- `Minor issue` = partial points
- `Non-compliant` = zero points
- `Critical failure` = zero points and grade cap
- `Not applicable` = excluded from score denominator

## Recommended Scoring Concepts

### 1. Earned Points vs Possible Points

The most flexible model is to calculate:

`Score % = (Earned Points / Possible Points) * 100`

This allows different questions to carry different weights and supports exclusion of non-applicable questions.

### 2. Weighted Questions

Some questions should matter more than others. For example:

- handwashing compliance may be higher weight
- labeling accuracy may be medium weight
- a low-risk housekeeping item may be lower weight

Each checklist should be able to assign point values or weights at the question level.

### 3. Non-Scored Questions

Some questions may exist for documentation only and should not affect score.

Examples:

- informational observations
- follow-up notes
- acknowledgment questions

### 4. Not Applicable Handling

If a response is marked `Not Applicable`, it should normally be removed from the possible-point denominator so the audit score remains fair.

## Grade Calculation

Each checklist should define its own grade scale and thresholds.

Example threshold model:

- `A`: 95 to 100
- `B`: 85 to 94.99
- `C`: 75 to 84.99
- `D`: 65 to 74.99
- `F`: below 65

FiScore should support configurable alternatives, such as:

- pass/fail
- green/yellow/red
- platinum/gold/silver/bronze

## Critical Response Rules

Some responses represent serious risk and should affect the grade beyond simple point loss.

Examples:

- food held at unsafe temperature
- pest evidence in prep area
- employee illness policy violation
- cross-contamination risk

These should be handled through explicit critical rules.

### Supported Critical Rule Types

Each checklist should be able to define rules such as:

- grade cap
- grade reduction
- automatic fail
- mandatory violation creation
- mandatory manager review

### Examples

Example 1:

- Score: `96%`
- Default grade from score: `A`
- One critical response triggered a maximum grade of `B`
- Final grade: `B`

Example 2:

- Score: `89%`
- Default grade from score: `B`
- Two serious responses trigger one-level downgrade
- Final grade: `C`

Example 3:

- Score: `91%`
- Default grade from score: `A`
- One automatic-fail response triggered
- Final grade: `F`

## Recommended Rule Hierarchy

To keep grading predictable, FiScore should apply rules in a clear order:

1. Calculate earned points and possible points
2. Calculate raw score percentage
3. Determine default grade from score thresholds
4. Evaluate critical-response rules
5. Apply grade caps, reductions, or fail rules
6. Produce final score explanation and final grade

This order helps users understand why the final grade may differ from the score-based grade.

## Question-Level Scoring Approaches

FiScore should support different scoring methods by question.

### Full / Partial / Zero Scoring

Good for yes-no or pass-fail style compliance questions.

Example:

- `Pass` = 10 points
- `Needs Improvement` = 5 points
- `Fail` = 0 points

### Range-Based Scoring

Good for numeric or rating questions.

Example:

- 1 to 5 rating converted to point percentages

### Multi-Select Scoring

Good for observations with multiple selected conditions.

Example:

- each negative selection subtracts points
- certain combinations trigger a critical rule

### Rule-Based Scoring

Good for complex logic.

Example:

- answer pattern across multiple questions affects score or grade

## Section-Level Scoring

FiScore may support either of these models depending on checklist needs:

- `Question-weighted model`: all question points roll directly into the final score
- `Section-weighted model`: each section produces its own score, and sections contribute to the final score based on configured weights

The question-weighted model is simpler and should likely be the default for version 1. Section weighting can be added where audit programs need it.

## Violation Integration

Scoring and violation creation are related but should remain distinct.

Important principles:

- A failed response may reduce score without creating a violation
- A response may create a violation even if its direct point impact is limited
- A critical violation may lower or cap grade independently of score
- Manual violations may be added even when no scoring rule is triggered

This separation helps FiScore support real operational judgment rather than forcing all findings into a purely numeric system.

## Result Snapshot Requirements

When an audit is completed, FiScore should save a snapshot of the calculated result.

Suggested result fields:

- audit id
- checklist id
- checklist version
- scoring config version
- total earned points
- total possible points
- score percentage
- default grade
- final grade
- triggered critical rules
- list of score-impacting responses
- list of grade-impacting responses
- calculation timestamp

This result snapshot is important for historical reporting and defensibility.

## User Experience Requirements

Users should not see scoring as a black box.

The UI should make these things visible:

- current or final score percentage
- current or final grade
- why points were lost
- which questions were critical
- whether a grade was lowered because of a serious response

Helpful UX patterns:

- score summary card
- grade explanation panel
- audit completion summary
- badge or warning for critical findings
- drill-down into section and question score details

## Versioning Rules

Checklist scoring logic should be versioned whenever any of the following change:

- section structure
- question wording that affects scoring
- response options
- point values
- question weights
- grade thresholds
- critical rules
- grade cap or downgrade logic

Past completed audits must continue to reference the scoring version used at the time of completion.

## Recommended Version 1 Scope

For version 1, FiScore should support:

- checklist-level scoring configuration
- question-level points or weights
- percentage score calculation
- configurable grade thresholds
- critical-question flags
- grade caps or grade downgrades based on critical responses
- not-applicable exclusion from scoring
- auto-created violations based on responses
- saved scoring result snapshots

Version 1 does not need to support every advanced model immediately. It is better to build a scoring system that is understandable and reliable before adding highly complex rules.

## Example Checklist Configuration

Illustrative example:

- Checklist: `Daily Food Safety Audit`
- Grade Scale:
- `A`: 95 to 100
- `B`: 85 to 94.99
- `C`: 75 to 84.99
- `D`: 65 to 74.99
- `F`: below 65

Questions:

- `Cold holding temperature within range?`
  - Pass = 15 points
  - Fail = 0 points
  - Critical rule: if failed, final grade cannot exceed `B`

- `Handwashing station stocked and accessible?`
  - Pass = 10 points
  - Partial = 5 points
  - Fail = 0 points

- `Food labels complete and current?`
  - Pass = 5 points
  - Fail = 0 points

- `Observed pest activity?`
  - No = 10 points
  - Yes = 0 points
  - Critical rule: if yes, automatic manager review and final grade cannot exceed `C`

## Open Design Decisions

These questions should be finalized before implementation:

- Will weights be stored as point values, percentages, or both?
- Will section weighting be supported in version 1 or later?
- Can multiple critical rules stack, and how should precedence work?
- Can a checklist define both grade caps and grade reductions at the same time?
- Should in-progress audits show a live score before completion?
- How should partially completed audits handle temporary score previews?

## Summary

FiScore should support a checklist-specific scoring model in which every audit template can define its own structure, weights, thresholds, and critical-response rules. The final system should be transparent to users, flexible for different audit programs, and strict enough to reflect serious food safety risks even when the raw score appears strong.

