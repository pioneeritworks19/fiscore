# FiScore Sword Solutions Ingestion Plan

## Purpose

This document defines the first concrete ingestion plan for FiScore using the Sword Solutions inspections platform as the initial operational source.

The goal of this plan is twofold:

- execute the first real ingestion pipeline for nearby Michigan counties
- establish the architectural and operational foundation for managing many pipelines over time

This source is a strong practical starting point because:

- it is restaurant-relevant
- it includes counties near the target user base
- it supports real-world local testing inside FiScore
- it provides one shared platform with multiple county sources

## Scope

The initial scope is:

- platform: `Sword Solutions`
- sources: each Michigan county available on the Sword Solutions inspections site
- ingestion target: restaurant-relevant inspection data
- output target: master data platform plus tenant-facing projections for linked restaurants

## Counties in Scope

Based on the current Sword Solutions inspection site, the counties currently visible include:

- MI - Allegan
- MI - Grand Traverse
- MI - Livingston
- MI - Marquette
- MI - Muskegon
- MI - Oakland County
- MI - Washtenaw
- MI - Wayne

These should be modeled as separate sources under one shared platform.

## Platform and Source Model

### Platform

- `platform = Sword Solutions`

### Sources

Each county should be treated as its own source record for operations visibility.

Examples:

- `sword_mi_allegan`
- `sword_mi_grand_traverse`
- `sword_mi_livingston`
- `sword_mi_marquette`
- `sword_mi_muskegon`
- `sword_mi_oakland`
- `sword_mi_washtenaw`
- `sword_mi_wayne`

### Why Separate County Sources

- county-level reruns are easier
- county-level failures are easier to isolate
- county-specific freshness is easier to monitor
- operational dashboards become more useful
- future county-specific parsing differences can be handled cleanly

## Ingestion Goals

For the first rollout, FiScore should ingest:

- relevant restaurant header fields
- relevant inspection header fields
- relevant violation fields

The goal is not to ingest every possible field on day one. The goal is to ingest the fields needed to support:

- master restaurant creation and matching
- inspection history display
- violation creation and tenant workflows

## Data to Ingest

## 1. Restaurant Header Data

Recommended fields:

- county
- license number
- restaurant name
- address
- city
- state
- zip code if available
- source restaurant key if one exists

## 2. Inspection Header Data

Recommended fields:

- inspection date
- inspection type if available
- inspection status if available
- score if available
- grade if available
- result summary if available

## 3. Violation Data

Recommended fields:

- violation category or type if available
- violation code or clause if available
- violation text
- correction or compliance notes if present
- compliance timeline if present

## Ingestion Strategy

## Historical Backfill

The first rollout should perform:

- full historical backfill first

There should be no artificial limit for the first execution.

### Why

- FiScore needs full inspection history for linked restaurants
- historical depth improves product value from the beginning
- it reduces the need for an immediate second ingestion phase

### Backfill Mode

The Sword pipeline should treat the initial historical load as an explicit run mode:

- `backfill`

Backfill mode should:

- run county by county
- use the broadest safe source scope available
- avoid date restriction unless Sword requires batching to retrieve older records
- establish the baseline set of restaurants, inspections, findings, and source versions for later comparison

## Ongoing Refresh

After the initial backfill, the ongoing cadence should be:

- weekly refresh per county
- plus manual refresh when needed

### Incremental Mode

The routine weekly refresh should run as an explicit:

- `incremental`

mode.

For Sword, incremental mode should use the source date filters to reduce fetch scope, but should not rely on the date filter as the source of truth for change detection.

Recommended weekly incremental query window:

- rolling overlapping lookback of `45 days`

Why:

- catches newly posted recent inspections
- reduces the amount of source content that must be re-read on each weekly run
- provides protection against delayed source publication and small scheduler gaps

Within that window, FiScore should still detect change by comparing parsed records against stored records using:

- source inspection keys
- source finding keys
- normalized comparison hashes
- source version history

### Reconciliation Mode

Sword should also support a periodic wider refresh mode:

- `reconciliation`

Recommended cadence:

- monthly per county

Recommended reconciliation query window:

- rolling lookback of `180 days`

Why:

- catches late postings and corrected inspections outside the normal weekly incremental window
- validates that the narrower incremental process is not missing meaningful source changes
- reduces the need for frequent full-county re-reads once the source is operating normally

### Run Mode Summary

Recommended Sword run modes:

- `backfill` = full historical baseline load
- `incremental` = weekly `45-day` overlapping refresh
- `reconciliation` = monthly `180-day` lookback refresh

## Identity and Matching Rules

## Source-Specific Strongest Identifier

For the Sword Solutions source, the strongest source-specific identifier should be:

- `county + license_number`

This should be treated as the strongest source establishment identity when a license number exists.

## Canonical Identity Model

FiScore should still use:

- `masterRestaurantId` as the FiScore-owned canonical identity
- `locationFingerprint` as the primary canonical match anchor when broader cross-source matching is needed
- `county + license_number` as the strongest Sword source identifier

## Identity Rules

### Same County + Same License + Changed Name

Treat as:

- same establishment

Reason:

- the source identifier is stronger than the display name
- name changes should not create duplicate establishments

### Same Address + Different License Number

Treat as:

- new establishment

Reason:

- a changed license number may represent a true establishment change
- the address alone is not enough to force a merge

### Same Address + Different License + Similar Name

Treat as:

- separate records initially
- candidate for review if broader match logic later suggests continuity

Reason:

- this is a classic ownership-transfer or permit-turnover scenario
- do not merge aggressively in version 1

## Storage Requirements

The first pipeline should store all three layers:

- raw HTML responses
- parsed result snapshots
- normalized records

## 1. Raw HTML

Store:

- search result pages
- detail pages
- any additional inspection or violation pages used for parsing

Why:

- reprocessing
- debugging
- parser regression review
- defensible source traceability

## 2. Parsed Result Snapshots

Store:

- extracted restaurant payloads
- extracted inspection payloads
- extracted violation payloads
- parser warnings and parser version

Why:

- faster review of parser behavior
- easier troubleshooting without reparsing raw HTML every time

## 3. Normalized Records

Store normalized data in the master data platform using the structures already defined in:

- `MASTER_DATA_SCHEMA.md`

## Change Detection Requirements

The first pipeline must detect and store:

- new inspections
- updated inspection summaries
- changed violations
- removed historical records

This should be done with:

- source version tracking
- change classification
- current record markers

For Sword specifically, date filters should only narrow the fetch scope.

The decision about whether something is new, changed, or removed should still come from FiScore comparison logic rather than from the date filter alone.

## Versioning Rules

### New Inspection

Create:

- new canonical inspection record
- new source version record

### Updated Inspection Summary

Create:

- updated source version
- updated current canonical representation

### Changed Violation

Create:

- updated source version
- updated current finding representation

### Removed Historical Record

Record:

- removal event in source history
- do not silently delete traceability from the master data platform

## Tenant Publishing Rules

The first pipeline should publish into tenant-facing data right away.

### Publishing Rule

Only linked restaurants should be projected into the tenant application.

### Tenant Update Behavior

When Sword inspection data changes later:

- tenant projections should update automatically
- source version history should be preserved
- material changes should be flagged for review

### Material Change Examples

- score change
- inspection result status change
- violation added
- violation removed
- meaningful violation text change

## Operational Foundation Requirements

The first version must also lay the foundation for operating many pipelines.

From day one, FiScore should support:

- source run history
- county-level run history
- error logs
- alerting on failed runs
- manual retry controls
- stale data monitoring

## Required Operational Features

## 1. Source Run History

Track for every county source:

- start time
- end time
- status
- record counts
- parser version
- error summary

## 2. County-Level Run History

Because each county is modeled as a separate source, each county should have:

- its own run history
- its own freshness status
- its own alerting and rerun controls

## 3. Error Logs

Capture:

- fetch failures
- parse failures
- unexpected page structures
- missing identifiers
- normalization failures

## 4. Failed Run Alerting

Alert when:

- a county run fails
- extraction counts drop unexpectedly
- no records are returned where records were previously expected
- parser errors spike

## 5. Manual Retry Controls

The first operational version should support:

- manual rerun by county
- manual rerun by restaurant or license
- full source rerun

These can be phased in operationally, but they are all required capabilities in the model.

## 6. Stale Data Monitoring

Each county source should track:

- last successful run
- target freshness window
- staleness state

## Manual QA Workflow

The first pipeline should include a manual QA step before considering each county fully trusted.

### QA Process

For each county:

1. run initial backfill
2. sample 20 restaurants
3. compare parsed records against the live Sword site
4. verify restaurant header fields
5. verify inspection header fields
6. verify violation extraction quality
7. approve county rollout or log parser issues for correction

### Why

- catches county-specific quirks early
- builds trust in the first production pipeline
- reduces silent data quality drift

## First Pipeline Architecture

The first Sword pipeline should follow these stages:

1. source discovery by county
2. fetch search and detail HTML
3. store raw HTML
4. parse restaurant, inspection, and violation data
5. store parsed payload snapshots
6. normalize into master restaurant, inspection, and finding records
7. run source identity and canonical match logic
8. detect changes against previously known records
9. publish linked restaurant projections into the tenant app
10. record operational results and alerts

## Recommended Execution Order

Although the source set includes all counties on the site, implementation should still proceed in a controlled order.

### Phase 1: Foundation

- register platform and county sources
- define fetch and parse structure
- define raw/parsed/normalized persistence
- implement county-level run tracking

### Phase 2: Full Historical Backfill

- execute county-by-county full historical ingestion
- populate master restaurant, inspection, and finding records
- apply change/version structures

### Phase 3: QA and Validation

- sample 20 restaurants per county
- validate extraction quality
- approve or fix county parsers

### Phase 4: Tenant Publishing

- publish linked restaurant projections
- validate local restaurant testing inside the app

### Phase 5: Ongoing Operations

- move to weekly refresh cadence
- run monthly reconciliation passes
- enable manual reruns and monitoring

## Recommended Field Importance Priority

To keep implementation focused, FiScore should prioritize field reliability in this order:

### Highest Priority

- county
- license number
- restaurant name
- address
- inspection date
- inspection score or grade if available
- violation text

### Medium Priority

- inspection type
- clause/code
- result summary
- correction notes

### Lower Priority

- optional display-only fields that do not materially improve matching, history, or workflow

## Relationship to Existing Documents

This plan should be implemented consistently with:

- `MASTER_DATA_ARCHITECTURE.md`
- `MASTER_DATA_SCHEMA.md`
- `MASTER_LIST_STRATEGY.md`
- `RESTAURANT_MATCHING.md`
- `INGESTION_WORKFLOWS.md`
- `INTERNAL_OPS_CONSOLE.md`
- `FIRESTORE_SCHEMA.md`

## Recommended Next Deliverables

After this plan, the next most useful implementation docs would be:

- `SWORD_SOLUTIONS_FIELD_MAPPING.md`
- `SWORD_SOLUTIONS_PARSER_RULES.md`
- `TENANT_PROJECTION_RULES.md`
- `MONTH_1_PLAN.md`

## Summary

FiScore should use Sword Solutions as the first practical ingestion platform, modeled as one platform with separate county sources. The first rollout should ingest relevant restaurant, inspection, and violation data for all Sword-listed Michigan counties through a full historical backfill, store raw and parsed artifacts alongside normalized records, detect source changes with version tracking, publish only linked restaurant data into tenants, and include the operational tooling needed to monitor and rerun county pipelines over time.
