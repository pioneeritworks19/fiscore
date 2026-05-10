# Content Management Model

## Purpose

This document defines how FiScore content should be owned, authored, versioned, published, and distributed.

It covers:

- audit checklist content
- training content
- FiScore-owned library content
- tenant-owned content
- preferred management channel for each content type

The goal is to keep content governance clear as FiScore grows.

## Why This Matters

FiScore now has configurable content that can exist at two levels:

- FiScore library level
- tenant level

Without a clear content-management model, later decisions become inconsistent, such as:

- who is allowed to edit master content
- whether tenant users can modify FiScore-provided content directly
- where versioning and publishing should happen
- whether content should be authored in the mobile app or browser

## Core Recommendation

FiScore should separate:

- `library content`
  content owned and managed by FiScore
- `tenant content`
  content owned and managed by an individual tenant

For both audit checklist templates and training content, the recommended default is:

- execution happens primarily on phone or tablet
- authoring and governance happen primarily on web

## Content Types Covered

This model applies to:

- library audit checklist templates
- tenant audit checklist templates
- library training content
- tenant training content

## Content Ownership Model

## 1. FiScore Library Content

FiScore library content is reusable content created and maintained by FiScore for use across tenants.

Examples:

- food safety master audit templates
- sanitation checklists
- common micro-learning modules
- standard food safety training courses

### Characteristics

- owned by FiScore
- managed by FiScore internal product or content team
- reusable across tenants
- versioned and published through internal governance
- not directly editable by tenant users
- available to tenants through explicit adoption patterns rather than direct editing

## 2. Tenant Content

Tenant content is customer-specific content created within one tenant.

Examples:

- tenant-specific opening checklist
- local SOP training
- region-specific manager walkthrough
- custom retraining content

### Characteristics

- owned by the tenant
- visible only inside that tenant
- managed by permitted tenant users
- may be versioned and published according to tenant rules

## Content Categories

## Audit Checklist Content

Includes:

- sections
- questions
- trigger logic
- scoring rules
- grading rules
- site assignment

Audit checklists are high-governance content because they directly affect audit execution, scoring, and historical compliance records.

## Training Content

Includes:

- training title and description
- topics or content blocks
- quick checks
- risk area tags
- status and assignment availability

Training content is also version-sensitive, but in version 1 it can use lighter governance than audit checklists.

## Preferred Management Channel

## FiScore Internal Team

The FiScore internal team should manage library content primarily through a web-based internal admin experience.

This is the recommended channel for:

- creating library audit checklists
- editing library checklist versions
- publishing library checklist versions
- creating library training content
- editing training versions
- publishing training updates
- tagging and categorizing reusable content

### Why web is preferred

These are authoring and governance workflows that benefit from:

- larger screen space
- side-by-side comparison
- easier editing of long structured content
- safer publishing and version review

## Tenant Users

Tenant users should execute content primarily on phone or tablet, but should manage authoring-heavy tenant content primarily through browser.

### Mobile or tablet should be primary for:

- performing audits
- completing training
- reviewing violations
- responding to findings

### Browser should be preferred for:

- tenant checklist authoring
- training creation and editing
- quick-check setup
- scoring and rule setup
- larger administrative content workflows

## Internal Versus Tenant Web

FiScore should conceptually distinguish between:

### 1. Internal FiScore Content/Admin Web

Used by FiScore company staff to manage:

- library templates
- library training
- versioning and publishing
- future content governance

### 2. Tenant Companion Web

Used by customer tenant users for:

- management
- review
- tenant content authoring
- reporting

These may share technology, but they should not be treated as the same permission space or workflow model.

## Authoring and Publish Rules

## Audit Checklists

Recommended rules:

- checklist content is editable while in `draft`
- once published, that version is locked for normal editing
- changes to a published checklist create a new draft version
- when that draft is published, it becomes the active published version for future audits
- historical audits remain tied to the version they used

This applies to both:

- FiScore library audit templates
- tenant-owned audit templates

## Training Content

Recommended rules:

- training content should have a version
- draft or not-yet-assigned training may be edited more freely
- once training is assigned, meaningful content changes should create a new version for future assignments
- users already assigned or in progress remain tied to the version they were assigned
- completed history remains tied to the completed version
- new assignments use the newer active version

This applies to both:

- FiScore library training
- tenant-owned training

## Distribution Model

## Library Content Distribution

FiScore library content should become available to tenants in one of these ways:

- synced tenant template derived from the library item
- one-time tenant copy created from the library item
- future tenant enablement record if needed for simpler adoption tracking

The right pattern may vary by content type.

### Recommended behavior

- FiScore library content should not be edited directly by tenant users
- tenants should always work against tenant-owned records, not live library records
- the product should support two explicit creation paths:
  - `Synced from Library`
  - `Created from Library`
- `Synced from Library` means:
  - the tenant record stays linked to the source library item
  - the tenant can be notified when a newer library version exists
  - the tenant chooses when to adopt the newer version
  - the tenant may detach later if it wants to diverge permanently
- `Created from Library` means:
  - the tenant gets a one-time copy
  - no future sync or update prompt is expected
  - the tenant fully owns the copied content from that point forward
- library updates should behave like version upgrades, not silent live mirroring
- active or historical audits and training assignments must remain tied to the exact tenant version used at the time

### Recommended synced behavior

For synced tenant content:

- store a link back to the source library item
- store the source library version last adopted
- track whether a newer library version is available
- allow the tenant to preview and apply the update
- allow the tenant to detach from future library updates
- do not silently overwrite tenant content in place
- if the tenant has local edits, require an explicit review flow before applying a newer library version

## Tenant Content Distribution

Tenant content should be available only within that tenant and optionally scoped further:

- tenant-wide
- selected sites
- selected operating use cases later if needed

## Permissions Model

## FiScore Internal Roles

Separate internal roles should eventually govern library content.

Examples may include:

- content admin
- product admin
- training content editor
- checklist content editor

This should be documented separately from tenant roles if internal tooling grows.

## Tenant Roles

Tenant content creation and editing should be controlled by tenant-side permissions.

Recommended likely roles:

- `tenant_owner`
- `admin`
- `manager`

Audit execution, violation response, and training completion remain broader operational workflows and do not imply content-authoring access.

## Governance Rules

Recommended guardrails:

- library content should not be edited from tenant context
- tenant edits should never change FiScore library content
- published checklist versions should preserve history
- assigned training versions should preserve assignment stability
- synced tenant content should upgrade only through an explicit tenant action
- active or completed operational records should never be rebound to a newer library version automatically
- browser should be the preferred governance channel for content-heavy workflows

## Example Operating Model

### FiScore Internal Team

1. creates a master handwashing audit checklist in internal web admin
2. publishes version 1
3. tenants can adopt it as `Synced from Library` or `Created from Library`
4. later FiScore publishes version 2
5. synced tenants see `Update available`
6. future tenant usage can adopt version 2 without rewriting historical audits

### Tenant Team

1. manager creates a tenant checklist from the library
2. if the manager selects `Created from Library`, the checklist is detached immediately
3. if the manager selects `Synced from Library`, the tenant checklist keeps a link to the source library version
4. tenant edits and publishes its own tenant version
5. future audits use that tenant-published version
6. later library updates may be reviewed and adopted only if the tenant chose the synced mode

### Training Example

1. FiScore publishes `Holding Temperature Basics v1`
2. tenant assigns it to staff
3. FiScore later improves the content and publishes `v2`
4. synced tenant training shows `Update available`
5. existing assignments remain on `v1`
6. future assignments use `v2` only after the tenant adopts or upgrades to the newer tenant version

## Summary

FiScore should use a clear content-management model in which FiScore-owned library checklist and training content are governed primarily through a web-based internal admin experience, while tenant-owned content is governed within the tenant context, also preferably through browser for authoring-heavy workflows. Mobile and tablet remain the primary execution surfaces, while content ownership, versioning, publishing, and distribution are managed through structured web-based governance. Tenants should work with tenant-owned copies, either as synced library-derived records or detached copies created from the library, so historical audits and training assignments remain stable while newer library versions can still be adopted deliberately.
