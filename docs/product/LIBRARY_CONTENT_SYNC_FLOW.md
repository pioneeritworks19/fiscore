# FiScore Library Content Sync Flow

## Purpose

This document defines how FiScore Library checklist and training content should be adopted, updated, detached, and preserved in tenant workflows.

It applies to:

- audit checklist templates
- training content

The goal is to make library content operationally useful without letting library updates silently rewrite tenant history.

## Core Model

Tenants should never execute audits or training assignments directly against mutable FiScore Library records.

Instead, tenants should always work with **tenant-owned records** that may originate from the library in one of two ways:

- `Synced from Library`
- `Created from Library`

## Terminology

### FiScore Library

Central content authored and published by FiScore for reuse across tenants.

Examples:

- monthly food safety walkthrough
- handwashing refresher
- holding temperature basics

### Tenant Copy

A tenant-owned checklist or training record derived from a library item.

This is the actual record used in tenant scheduling, audits, assignments, and reporting.

### Synced from Library

A tenant-owned copy that remains linked to the source library item and may later adopt newer library versions.

### Created from Library

A tenant-owned copy that starts from a library item once and then becomes fully detached from future library updates.

### Detach from Library

An action that converts a previously synced tenant-owned record into a fully tenant-managed record with no future library update linkage.

## Why This Model

This model balances:

- centralized authoring
- tenant control
- historical integrity
- safer operational upgrades

Without this separation:

- library edits could silently change tenant audits or training
- completed audits could become historically ambiguous
- assigned training could shift underneath users after assignment

## Supported Creation Paths

## 1. Synced from Library

### Goal

Let tenants benefit from centrally maintained content while keeping adoption explicit and history stable.

### What gets created

When a tenant chooses `Synced from Library`:

- create a tenant-owned checklist or training record
- copy the current published library version into the tenant record
- store linkage metadata:
  - `libraryTemplateId` or `libraryTrainingId`
  - `libraryVersion`
  - `syncMode = synced_from_library`
  - `syncStatus = up_to_date`
  - `lastSyncedAt`

### Expected behavior

- the tenant may use the tenant record immediately
- future library versions do not auto-overwrite the tenant copy
- instead the tenant sees `Update available`
- the tenant explicitly decides whether to adopt the update

## 2. Created from Library

### Goal

Give tenants a fast starting point with no future sync expectations.

### What gets created

When a tenant chooses `Created from Library`:

- create a tenant-owned checklist or training record
- copy the current library version into the tenant record
- optionally preserve provenance metadata such as `libraryTemplateId` or `libraryTrainingId`
- store:
  - `syncMode = created_from_library`
  - `syncStatus = detached` or `never_synced`

### Expected behavior

- the tenant fully owns the copy
- no update prompts are required
- future library versions do not affect the tenant record

## Update Detection Model

For synced items only:

1. FiScore publishes a newer library version
2. the platform compares the tenant's adopted `libraryVersion` to the newest published library version
3. if newer library content exists:
   - set `updateAvailable = true`
   - set `syncStatus = update_available`
4. show that state in the tenant UI

The product should not silently apply the update.

## Checklist Update Adoption Flow

### Goal

Allow a tenant to move to newer checklist content safely without rewriting historical audits.

### Steps

1. tenant opens a synced checklist
2. FiScore shows `Update available`
3. tenant reviews:
   - current tenant version
   - newest library version
   - summary of meaningful changes if available
4. tenant chooses one of:
   - `Apply Update`
   - `Detach from Library`
   - `Keep Current Version`

### Apply Update behavior

When `Apply Update` is selected:

- create or activate a newer **tenant checklist version**
- keep the same tenant template identity where appropriate
- update:
  - `libraryVersion`
  - `lastSyncedAt`
  - `updateAvailable = false`
  - `syncStatus = up_to_date`

### Historical safety rule

Existing audits and schedules must remain tied to the version they were already using.

This means:

- completed audits remain unchanged
- in-progress audits remain on their original tenant checklist version
- future audits and future schedules use the newer tenant version

## Training Update Adoption Flow

### Goal

Allow a tenant to adopt newer training content without changing existing assignments mid-stream.

### Steps

1. tenant opens a synced training item
2. FiScore shows `Update available`
3. tenant reviews the update
4. tenant chooses one of:
   - `Apply Update`
   - `Detach from Library`
   - `Keep Current Version`

### Apply Update behavior

When `Apply Update` is selected:

- create or activate a newer tenant training version
- update:
  - `libraryVersion`
  - `lastSyncedAt`
  - `updateAvailable = false`
  - `syncStatus = up_to_date`

### Historical safety rule

Existing assignments must remain tied to the assigned version.

This means:

- assigned users stay on the version they were assigned
- in-progress users finish the version they started
- completed records remain tied to the completed version
- only future assignments use the newer tenant version

## Detach Flow

### Goal

Allow a synced tenant item to become fully tenant-managed.

### Behavior

When a tenant chooses `Detach from Library`:

- preserve the current tenant content exactly as-is
- clear future upgrade expectations
- update:
  - `syncStatus = detached`
  - `detachedFromLibraryAt`
- preserve provenance metadata if useful for history

After detaching:

- no future update prompts are required
- tenant users may edit more freely according to normal versioning rules

## Local Edits and Upgrade Safety

Synced items may eventually receive tenant-local edits.

Version 1 recommendation:

- allow tenant-local edits on synced content
- but if those edits materially diverge from the current library-based version, require an explicit review before applying a future library update

If conflict handling becomes too complex for version 1, a simpler acceptable rule is:

- allow update only when there are no meaningful tenant-local edits beyond allowed metadata changes
- otherwise require:
  - `Detach from Library`
  - or a future merge workflow

## UI Recommendations

## Checklist Library UI

For each library-derived checklist, show:

- source label:
  - `FiScore Library`
  - `Tenant Library`
- mode:
  - `Synced from Library`
  - `Created from Library`
  - `Tenant Custom`
- current tenant version
- update badge:
  - `Update available`

Primary actions:

- `Apply Update`
- `Detach from Library`
- `Create from Library`
- `Schedule Audit`

## Training Library UI

For each library-derived training item, show:

- source label
- mode
- current tenant version
- update badge

Primary actions:

- `Apply Update`
- `Detach from Library`
- `Create from Library`
- `Assign`

## Data Expectations

Checklist and training records should support fields such as:

- `libraryTemplateId` / `libraryTrainingId`
- `libraryVersion`
- `syncMode`
- `syncStatus`
- `lastSyncedAt`
- `updateAvailable`
- `detachedFromLibraryAt`

Suggested `syncMode` values:

- `synced_from_library`
- `created_from_library`
- `tenant_custom`

Suggested `syncStatus` values:

- `up_to_date`
- `update_available`
- `detached`
- `never_synced`

## Versioning Rules Summary

### Checklist

- current or historical audits must stay tied to the exact tenant version used
- applying a library update affects future audits only

### Training

- current or historical assignments must stay tied to the exact tenant version used
- applying a library update affects future assignments only

## Recommended Version 1 Rule Set

For version 1, FiScore should:

- support `Synced from Library`
- support `Created from Library`
- show `Update available`
- require explicit adoption of updates
- support `Detach from Library`
- freeze historical audits and assignments to their exact tenant version

Version 1 does **not** need:

- automatic live mirroring
- deep three-way merge tooling
- complex field-level sync conflict resolution for content authoring

## Current Product Slice

The first implemented library experience should use the same pattern for
checklists and training:

- `My Library` is the operational collection owned by the tenant
- `Explore FiScore Library` exposes FiScore-published starter content
- a manager adds one published item at a time into `My Library`
- checklists can be started only after they are in `My Library`
- training can be assigned only after it is in `My Library`
- selecting `Update` adopts the latest FiScore version for future audits or
  future assignments only

The initial FiScore published catalog is bootstrapped from server-side curated
definitions while the content set is small, then served through central
published Firestore records. It should later be managed through a governed
publishing workflow without changing the tenant-owned adoption model.

### TODO: Tenant-Created Content

- add `Create checklist` and `Create training` actions within `My Library`
- support draft, preview, publish, archive, and new-version workflows
- show tenant-authored content as `Created by your team`
- support `Customize for my team` by making an independent tenant-owned copy
  of FiScore content

### TODO: Library Administration And Discovery

- add a FiScore publishing console and published-version records
- add preview/detail screens before adopting content
- add categories, filters, recently used items, and suggested content
- add update summaries, detach controls, and site availability controls

## Summary

FiScore Library content should behave like a governed template source, not like live mutable shared records inside tenant operations. Tenants should always work against tenant-owned checklist and training records. Some tenant records may remain synced to the library and adopt updates deliberately; others may be one-time copies. In all cases, completed audits, in-progress audits, assigned training, and completed training history must remain tied to the exact tenant version originally used.
