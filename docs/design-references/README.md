# FiScore Design References

## Purpose

This folder stores visual reference material used to guide FiScore app design and UX implementation.

These assets are helpful during development, but they are not the source of truth for product behavior, permissions, data modeling, or workflow rules.

## How To Use These References

Use these mockups and visual artifacts for:

- screen layout direction
- information hierarchy
- interaction patterns
- visual tone
- component grouping
- flow continuity across screens

Do not use these references alone to decide:

- business rules
- data model structure
- permission rules
- trigger behavior
- offline and sync behavior
- final navigation architecture

Those decisions should still come from the canonical product and app docs.

## Source Of Truth Reminder

When design references and written specs differ, follow the written specs unless the product team intentionally updates them.

Main canonical docs:

- [Product Features](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\FEATURES.md)
- [Operational Workflows](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- [User Roles](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\USER_ROLES.md)
- [Audit Checklist Design](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_CHECKLIST_DESIGN.md)
- [Training Module](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\TRAINING_MODULE.md)
- [App Navigation](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\APP_NAVIGATION.md)
- [Firestore Schema](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\FIRESTORE_SCHEMA.md)

## Recommended Folder Structure

Store future visual references under subfolders like:

- `audits/`
- `training/`
- `violations/`
- `site-management/`
- `navigation/`

If a reference spans several modules, place it in the most relevant folder and mention the cross-module use in a short note.

## Recommended Naming Convention

Use descriptive filenames that explain both the module and the flow.

Recommended pattern:

`<module>-<flow>-<screen-or-step>-v<version>.<ext>`

Examples:

- `training-assignment-manager-flow-v1.png`
- `audit-trigger-question-inline-followup-v1.png`
- `violation-thread-action-plan-v1.png`
- `audit-submit-review-score-v1.png`

## Recommended Per-Image Note

When possible, keep a short note next to a visual reference describing:

- what the screen is trying to communicate
- whether it is mobile-first, tablet, or mixed
- which parts are aspirational versus expected in version 1
- which product docs are most relevant

This can be a small markdown file in the same subfolder if needed.

## Current Reference Themes

The current FiScore mockups are especially useful for these areas:

- guided audit flow
- inline trigger behavior
- thread-based violation handling
- structured action-plan presentation
- training assignment and completion loop
- performance impact and improvement framing

## Implementation Guidance

During app development, these references should be treated as:

- UX intent
- layout inspiration
- styling direction

They should not be treated as:

- pixel-perfect requirements
- locked navigation contracts
- final feature commitments for advanced future behavior not yet in scope

## Summary

This folder helps FiScore preserve design intent while keeping product requirements in the canonical docs. Use the references to shape the experience, but use the written specs to define what the app must actually do.
