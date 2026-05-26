# FiScore Documentation

This folder contains the project documentation for FiScore.

The goal of this documentation set is to help both humans and coding agents move quickly without guessing.

## How To Use This Folder

Read broad documents first, then move into focused reference docs only when the task needs them.

Recommended pattern:

1. start with the product and app overview docs
2. use schema and workflow docs for implementation decisions
3. use deep-dive docs only for complex areas such as ingestion or audit checklist behavior

## Source Of Truth

To keep the documentation usable as the project grows, each major topic should have a primary source of truth.

Use these documents as canonical unless a later doc explicitly replaces them:

- Product scope and feature intent:
  [product/FEATURES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\FEATURES.md)
- Day-to-day user behavior:
  [product/WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- Roles and permissions:
  [product/USER_ROLES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\USER_ROLES.md)
- Tenant app navigation:
  [app/APP_NAVIGATION.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\APP_NAVIGATION.md)
- Tenant app data model in Firestore:
  [app/FIRESTORE_SCHEMA.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\FIRESTORE_SCHEMA.md)
- Product-level business entities:
  [product/DATA_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\DATA_MODEL.md)
- Sync behavior:
  [product/SYNC_STRATEGY.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\SYNC_STRATEGY.md)
- Audit scoring and grading:
  [product/SCORING_RULES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\SCORING_RULES.md)
- Audit checklist engine design:
  [product/AUDIT_CHECKLIST_DESIGN.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_CHECKLIST_DESIGN.md)
- Audit execution user flow:
  [product/AUDIT_EXECUTION_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_EXECUTION_FLOW.md)
- Violation execution user flow:
  [product/VIOLATION_EXECUTION_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\VIOLATION_EXECUTION_FLOW.md)
- Onboarding experience:
  [product/ONBOARDING_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\ONBOARDING_FLOW.md)
- Team invitation and membership flow:
  [product/TEAM_INVITE_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\TEAM_INVITE_FLOW.md)
- Training setup and execution flow:
  [product/TRAINING_EXECUTION_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\TRAINING_EXECUTION_FLOW.md)
- Pricing and subscription model:
  [product/PRICING_AND_SUBSCRIPTION_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\PRICING_AND_SUBSCRIPTION_MODEL.md)
- Billing and subscription flow:
  [product/BILLING_AND_SUBSCRIPTION_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\BILLING_AND_SUBSCRIPTION_FLOW.md)
- Notification triggers and behavior:
  [product/NOTIFICATION_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\NOTIFICATION_FLOW.md)
- Testing and release quality strategy:
  [product/TEST_AND_RELEASE_QUALITY_STRATEGY.md](C:\Users\mkann\Documents\kannappan\fiscore\docs\product\TEST_AND_RELEASE_QUALITY_STRATEGY.md)
- Device and platform support strategy:
  [product/DEVICE_STRATEGY.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\DEVICE_STRATEGY.md)
- Content ownership and management model:
  [product/CONTENT_MANAGEMENT_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\CONTENT_MANAGEMENT_MODEL.md)
- Master-data platform architecture:
  [backend/MASTER_DATA_ARCHITECTURE.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\backend\MASTER_DATA_ARCHITECTURE.md)
- Master-data relational schema:
  [backend/MASTER_DATA_SCHEMA.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\backend\MASTER_DATA_SCHEMA.md)
- Ingestion operating model:
  [ingestion/INGESTION_WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\ingestion\INGESTION_WORKFLOWS.md)
- Ingestion run-mode contract:
  [ingestion/RUN_MODE_BEHAVIOR.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\ingestion\RUN_MODE_BEHAVIOR.md)
- Source-specific Sword integration:
  [source-integrations/sword/SWORD_SOLUTIONS_INGESTION_PLAN.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\source-integrations\sword\SWORD_SOLUTIONS_INGESTION_PLAN.md)

## Doc Types

The files in this repository generally fall into these buckets:

- overview docs
  Entry points and orientation
- canonical design docs
  The main source of truth for a topic
- reference docs
  Detailed supporting material used when implementing or reviewing a specific area
- source-specific docs
  Ingestion documentation tied to one external source

When adding future markdown files, prefer extending an existing canonical doc unless the topic is complex enough to justify a dedicated reference doc.

## Structure

- `product/`
  Product requirements, workflows, roles, scoring, and feature definitions
- `app/`
  Tenant app navigation and Firestore-facing application design
- `backend/`
  Platform architecture, backend setup, schemas, storage, and technology choices
- `ingestion/`
  Ingestion workflows, operations, matching, and master-list strategy
- `source-integrations/`
  Source-specific ingestion planning and parser documentation
- `design-references/`
  Mockups and UI reference material used to guide implementation

## Recommended Docs By Task

If you are coding in a specific area, start here:

- Building tenant app screens:
  `product/FEATURES.md`, `product/WORKFLOWS.md`, `app/APP_NAVIGATION.md`
- Designing tenant data or Firestore rules:
  `product/DATA_MODEL.md`, `app/FIRESTORE_SCHEMA.md`, `product/USER_ROLES.md`
- Working on offline behavior:
  `product/SYNC_STRATEGY.md`, `app/FIRESTORE_SCHEMA.md`
- Building audit functionality:
  `product/AUDIT_CHECKLIST_DESIGN.md`, `product/SCORING_RULES.md`, `product/WORKFLOWS.md`
- Building backend and ingestion services:
  `backend/MASTER_DATA_ARCHITECTURE.md`, `backend/MASTER_DATA_SCHEMA.md`, `ingestion/INGESTION_WORKFLOWS.md`
- Building Sword integration:
  `source-integrations/sword/`
- Using visual mockups during app implementation:
  `design-references/`

## Documentation Hygiene Rules

To keep this set useful for development:

- avoid repeating the same rule in many files
- update the canonical doc first when a decision changes
- use focused reference docs for complex subsystems
- prefer linking to related docs instead of copying large sections
- retire or rewrite docs that become contradictory

If two docs disagree, prefer the canonical doc listed in the Source Of Truth section until the conflict is cleaned up.

## Recommended Reading Order

If you are new to the project, a good order is:

1. `product/README.md`
2. `app/APP_NAVIGATION.md`
3. `backend/MASTER_DATA_ARCHITECTURE.md`
4. `backend/ARCHITECTURE_DIAGRAM.md`
5. `ingestion/INGESTION_WORKFLOWS.md`
6. `source-integrations/sword/`
