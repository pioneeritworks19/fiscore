# FiScore Audit Checklist Design

## Purpose

This document defines the product design for FiScore's Audit Checklist module as a configurable inspection and audit execution engine.

It expands the higher-level feature description in `FEATURES.md` and gives a more detailed foundation for:

- checklist authoring
- checklist versioning
- question and response design
- conditional logic
- required follow-up behavior
- prior-response intelligence
- compliance traceability
- implementation planning

## Positioning

FiScore should treat Audit Checklist as more than a digital form.

It is a configurable audit and inspection engine that supports:

- reusable templates
- pre-built compliance content
- rich response types
- conditional logic
- required evidence and follow-up rules
- scoring and grading
- version-controlled audit history
- violation creation from findings

This is the right long-term product framing if FiScore is going to compete with audit and operations platforms rather than only basic inspection trackers.

## Design Principles

### 1. Template-Driven but Configurable

Users should be able to start from pre-built templates and also create custom checklist forms that fit their operation.

### 2. Compliance History Must Be Preserved

Historical audits must remain tied to the exact checklist version used at that time.

### 3. Stable Question Identity Matters

Question wording may evolve over time, but the product should support a stable logical question identity across versions when the business meaning is still the same.

### 4. Response Capture Should Be Rich but Practical

The checklist engine should support enough input types to handle real inspections without becoming unnecessarily complex in version 1.

### 5. Follow-Up Should Be Rule-Driven

Certain responses should be able to require evidence, comments, or follow-up violation creation automatically.

### 6. Prior Context Should Help, Not Hide

Showing prior answers and using smart pre-fill should reduce effort, but the current auditor must still confirm the present-state response.

## Template Model

### Supported Template Types

FiScore should support both:

- library templates owned by FiScore and made available across tenants
- custom checklists and forms created by tenant users

Examples of pre-built template categories:

- food safety
- cleaning and sanitation
- operational readiness
- regulatory compliance
- opening checklist
- closing checklist

### Template Metadata

Each checklist template should include:

- template name
- template code or short identifier if needed later
- description
- author or owner
- template source
- tags such as `FDA`, `Daily`, `Kitchen`, `Weekly`
- assigned restaurant or site scope
- status such as draft, active, archived
- current version number
- created at
- updated at

### Template Source Types

Suggested source values:

- `library_synced`
- `library_copied`
- `tenant_custom`

### Assigned Scope

Template ownership and availability should be understood separately.

Ownership:

- `library template`
  owned by FiScore and available across tenants
- `tenant template`
  owned by a tenant and available only inside that tenant

Availability:

- a tenant template may be available to all sites in that tenant
- a tenant template may be restricted to selected sites in that tenant
- a FiScore library template should not be directly assigned to sites globally at the source definition layer
- if site assignment is needed for a FiScore template, that assignment should happen in the tenant's adopted copy or tenant-side enablement record

### Library Adoption Model

When a tenant starts from FiScore library content, the product should support two explicit paths:

- `Synced from Library`
- `Created from Library`

`Synced from Library` means:

- the tenant checklist is tenant-owned
- it stays linked to a FiScore library template and source version
- future library versions may be surfaced as `Update available`
- the tenant chooses when to adopt the new version
- the tenant may later detach from the library link if it wants to diverge permanently

`Created from Library` means:

- the tenant checklist is tenant-owned
- it starts from a one-time copy of the library template
- no future library sync is expected

The product should avoid having tenant audits execute directly against live FiScore library template records.

Templates may therefore be assigned at:

- tenant-wide level
- site level
- operational area level later if needed

Version 1 can start with tenant-wide and site-level assignment.

## Versioning Model

### Why Versioning Is Required

Checklist version history is essential for compliance and analytics.

Without versioning, historical audits become unreliable because:

- question wording may change
- scoring may change
- required evidence rules may change
- critical-response logic may change

### Recommended Versioning Rules

- every published checklist should have a version number
- checklist content may be edited freely while the current version is still in `draft`
- once a checklist version is published, that version should become immutable for normal editing
- audits should snapshot the checklist version used at execution time
- older audit records should never be recalculated against a newer template version
- new edits to a published checklist should create a new version rather than silently modifying history
- when a new version is published, it should become the active published version for future audits
- new audits and new audit schedules should use the currently published version, not an unpublished draft version
- if a tenant checklist is synced from a library template, library version upgrades should create or activate a newer tenant version rather than mutating the version already used by historical audits

### Authoring and Publish Model

Recommended authoring flow:

1. create checklist in `draft`
2. edit sections, questions, scoring, and rules while in `draft`
3. publish the draft version
4. treat that version as locked for normal editing
5. when changes are needed later, create a new draft version from the published version
6. publish the new draft version when ready
7. use the newly published version for future audits

Important behavior:

- a published checklist version should remain historically stable
- a new version should not overwrite the old version's audit history
- the product should always make it clear which version is currently published and active for future audit creation

### Cross-Version Question Linkage

FiScore should support cross-version linkage within an audit type based on a stable question identifier.

Recommended model:

- `questionId` is the stable logical identifier across versions when the question is still the same business question
- each published version also has a version-specific record snapshot
- if a question changes so much that it is no longer meaningfully the same, create a new stable `questionId`

This is important for:

- showing previous responses at the question level
- trend reporting over time
- smart pre-fill
- mapping scoring history across versions

## Checklist Structure

The engine should support:

- checklist templates
- sections
- questions
- response options
- rule definitions

Each checklist may define:

- its own sections
- its own questions
- its own answer types
- its own scoring rules
- its own critical-response rules
- its own follow-up requirements
- whether a full section may be marked not applicable

This allows FiScore to support different audit programs without forcing one structure on all customers.

## Section-Level Not Applicable

Some audit programs need the ability to mark an entire section as not applicable.

Recommended behavior:

- section-level N/A should be configurable per checklist section
- the auditor may mark the full section as not applicable only when the checklist allows it
- when a section is marked not applicable, unanswered questions in that section should not block completion
- section-level N/A should be visible in progress and summary views
- section-level N/A should be excluded from scoring denominator when the checklist scoring rules exclude not-applicable content

Best-practice expectations:

- section-level N/A should require explicit confirmation
- optional note may be captured when policy requires explanation
- the audit summary should clearly distinguish completed sections from not-applicable sections

## Question Types

## Basic Answer Types

Recommended version 1 support:

- yes/no
- pass/fail
- multiple choice
- dropdown
- short text
- long text
- number input

### Design Note

`yes/no` and `pass/fail` may be stored similarly at the technical layer, but they should remain separate semantic answer types in the product model because reporting language and auditor intent differ.

## Advanced Input Types

Recommended support as the module matures:

- slider or range input
- date picker
- time picker
- date-time picker
- signature capture
- barcode scan
- QR scan
- GPS or location capture

### Version 1 Recommendation

For version 1, prioritize:

- date or time input where clearly needed
- signature capture if sign-off is part of compliance workflow
- barcode or QR scan only if a concrete restaurant use case is identified
- GPS capture as configurable, not mandatory

## Measurement Fields

The checklist engine should support numeric measurement capture with operational validation.

Capabilities include:

- numeric value entry
- unit selection or unit definition
- min threshold
- max threshold
- target range
- pass/fail evaluation based on threshold rules

Examples:

- cold holding temperature in `degF`
- sanitizer concentration
- line check count

Best-practice expectations:

- units should be stored structurally, not only inside free text
- threshold failures should be available for reporting and trigger logic

## Question Configuration

Each question should be able to define:

- prompt
- help text
- answer type
- whether required
- whether scored
- whether critical
- display order
- allowed response options
- default notes or predefined notes
- evidence permissions
- validation rules
- conditional logic rules
- follow-up trigger rules

Each section should also be able to define:

- whether section-level N/A is allowed
- whether a note is required when the section is marked N/A

## Conditional Logic

FiScore should support conditional question behavior so audits stay relevant and efficient.

### Examples

- if `Fail`, show follow-up questions
- if temperature is above threshold, require comment
- if location type is `Kitchen`, show kitchen-only section

### Supported Behaviors

- show question when prior answer matches rule
- hide question when prior answer does not match rule
- require question when condition is met
- branch to a follow-up sequence

### Design Recommendation

Condition evaluation should be deterministic and versioned with the checklist.

That prevents historical audits from changing behavior later when rules evolve.

## Required Follow-Up Rules

Certain responses should be able to force follow-up violations.

Recommended rule-driven requirements:

- require photo upload
- require comment
- require violation creation
- suggest training
- flag repeat issue
- require manager review later if configured

Examples:

- if refrigeration temperature exceeds threshold, require photo plus comment
- if handwashing station fails, require comment and create a violation on submission
- if the same failure has repeated at the site, surface a repeat-issue alert and recommend training
- if compliance sign-off section is completed, require signature

### Important Design Principle

These should be configured as response rules, not manually enforced every time by memory or training.

## Evidence and Compliance Inputs

The checklist engine should support evidence capture at question level.

Supported evidence types:

- image
- short video
- document
- signature
- scanned code result
- location capture metadata

Best-practice expectations:

- evidence requirements should be configurable per question or rule
- evidence should be linked to the exact response event
- media should remain lightweight enough for mobile and low-connectivity use

## Smart Pre-Fill and Prior Response Visibility

FiScore should support prior-response intelligence at the question level.

### Smart Pre-Fill

The system may suggest or pre-fill a value from the previous audit for the same site when appropriate.

Recommended behavior:

- pre-fill should be assistive, not silent automation
- the current auditor should still actively confirm or change the response
- pre-filled answers should be clearly indicated in the UI

### Show Previous Response

While answering a question, the auditor should be able to see the previous audit response for the same site and same stable `questionId` where available.

Suggested prior-response display:

- previous answer value
- previous note
- previous response date
- previous auditor

### Benefits

- reduces repetitive entry
- improves consistency
- helps auditors understand whether an issue is recurring
- supports faster audits without hiding accountability

## Scoring and Grading Integration

Scoring and grading should remain checklist-specific.

Each checklist may define:

- question weights
- section weights
- passing logic
- critical-response logic
- grade thresholds
- grade caps or overrides

This document should work together with `SCORING_RULES.md`, not replace it.

## Audit Execution Expectations

When used in a live audit, the checklist engine should support:

- loading the assigned checklist version
- showing conditional follow-up questions
- saving answers locally during execution
- attaching evidence during the audit
- showing previous responses where configured
- showing section progress clearly
- showing overall audit progress clearly
- surfacing unanswered and incomplete items clearly
- allowing navigation back to incomplete sections and questions
- allowing question flagging or review marking when supported by the checklist UX
- keeping triggered follow-up inline rather than navigating away
- explaining why triggers fired
- preserving section and question hierarchy during triggered expansion
- supporting collapse state for triggered blocks
- allowing section-level not applicable when configured by the checklist
- deferring auto-created violation generation until audit submission

## Audit Summary And Reporting Expectations

At the end of the audit, the auditor should be able to review a clean and lightweight summary before leaving the site.

Recommended summary content:

- site name
- checklist name and version
- audit date and auditor
- section completion summary
- overall score
- final grade
- critical findings summary
- created violations summary
- not-applicable sections summary

Recommended report behavior:

- the device should be able to generate or share a lightweight on-site summary view or lightweight PDF
- this lightweight summary is intended for immediate operational review or on-site sharing
- the final official audit report should be generated server-side after submission
- the server-generated final report should become the canonical audit report attached to the audit record

Important product distinction:

- lightweight local summary is immediate and operational
- server-generated final report is the durable final audit artifact

## Severity-Driven Response Behavior

Severity should be a stronger first-class signal in the checklist engine.

Recommended severity levels:

- critical
- high
- medium
- low

Severity may influence:

- required evidence
- required comment
- violation creation
- manager review expectations
- training recommendation
- risk display in the audit UI

## Suggested Intelligence

When supported by rules or historical context, the audit experience may surface:

- repeat violation alerts
- suggested fixes
- risk explanations
- recommended training

This should stay concise and operational rather than becoming noisy.

## Audit UX Reference

See [AUDIT_UX_GUIDELINES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\AUDIT_UX_GUIDELINES.md) for the intended interaction behavior of live audits, including inline trigger expansion, progressive disclosure, and context-preserving follow-up UX.

## Data Model Implications

The product design above has important implementation implications.

The data model should support:

- stable checklist template id plus version
- stable section and question identifiers
- section-level not-applicable configuration
- question-level response snapshots
- structured answer storage by type
- rule definitions for conditional logic and required violation behavior
- template metadata including tags and owner
- assignment of templates to sites
- prior-response lookup by restaurant or site plus stable question id
- lightweight audit-summary generation inputs
- final server-generated audit-report attachment metadata

## Recommended Phasing

### Version 1 Core

- custom templates
- pre-built templates
- sections and questions
- checklist versioning
- basic answer types
- conditional follow-up logic
- evidence requirements for photo or comment
- audit schedule support
- stable question ids across versions
- show previous response at question level
- score and grade integration

### Version 1.5 or Version 2

- signature capture
- advanced measurement workflows with richer thresholds
- barcode and QR scanning
- GPS capture
- smarter pre-fill policies
- broader template sharing and cloning workflows

## Recommended Product Language

When describing this capability externally or internally, FiScore should use wording closer to:

"Audit Checklist is a configurable inspection engine for restaurant operations and food safety. It supports reusable templates, version-controlled compliance forms, rich response types, conditional logic, prior-response visibility, evidence capture, scoring, and automatic violation creation."

That positioning better reflects the true scope of the feature.

## Summary

FiScore's Audit Checklist module should be designed as a configurable, versioned inspection engine rather than only a form builder. It should support custom and pre-built templates, rich question types, conditional logic, evidence and follow-up rules, prior-response intelligence, and stable cross-version question identity so the product can deliver credible compliance history and scalable audit operations.
