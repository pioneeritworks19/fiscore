# FiScore Internal Operations Console

## Purpose

This document defines the purpose, scope, and functional requirements for the FiScore Internal Operations Console.

The Internal Operations Console is an internal-only tool used to manage the master public inspection data platform. It is not part of the tenant-facing app. Its purpose is to help the FiScore team monitor scraper health, investigate parser failures, review ambiguous restaurant matches, inspect raw source artifacts, and maintain data quality across a growing number of jurisdictions and data sources.

Without this internal console, a scraper fleet that grows into tens or hundreds of sources will quickly become difficult to maintain, debug, and scale.

## Goals

- monitor the health of all government source pipelines
- identify stale, failing, or degraded sources quickly
- inspect individual scrape runs and parser results
- review and resolve restaurant matching ambiguity
- inspect raw source artifacts such as HTML and PDFs
- reprocess records when parser or normalization logic improves
- review changed source reports before or after publication where needed
- support operational quality and trust in the master dataset

## Non-Goals

- tenant-facing audit, violation, or CAPA workflows
- end-user restaurant management
- exposing raw source operations to restaurant customers

## Product Role

The Internal Operations Console should be treated as a core operational product for FiScore, not just an engineering convenience.

It supports:

- master data quality
- ingestion reliability
- source freshness
- troubleshooting and recovery
- operational scalability

This is especially important because the backend depends on external government websites that will change over time.

## User Types

The console should support at least these internal roles:

### 1. Operations Analyst

Focus areas:

- source monitoring
- reviewing failed or degraded runs
- checking stale data
- reviewing ambiguous restaurant matches

### 2. Data Quality Analyst

Focus areas:

- validating parsed outputs
- reviewing duplicate records
- checking changed inspection records
- confirming publication readiness in edge cases

### 3. Admin or Engineering Operator

Focus areas:

- source configuration
- parser version management
- reruns and reprocessing
- incident response

## Primary Console Modules

The console should be organized into several modules.

## 1. Source Registry

This module manages the list of all configured government sources.

Each source should display:

- source name
- jurisdiction
- agency
- source type
- cadence
- parser version
- last successful run
- next scheduled run
- current health state

Actions may include:

- activate or pause a source
- update source configuration
- trigger a manual run
- view source history

## 2. Source Health Dashboard

This should provide a high-level operational view across all sources.

Recommended dashboard metrics:

- total healthy sources
- degraded sources
- failing sources
- stale sources
- sources needing review
- runs completed today
- failed runs today
- average source freshness

Recommended filters:

- by jurisdiction type
- by state
- by source health
- by cadence
- by parser version

This dashboard should help the team answer:

- what is broken right now
- what is becoming stale
- which sources are at risk

## 3. Scrape Run Explorer

This module should allow internal users to inspect individual source runs.

Each run should display:

- source name
- start time
- end time
- duration
- run status
- discovery count
- fetched artifact count
- parsed record count
- validation hold count
- published record count
- duplicate count
- parser version
- error summary

Actions may include:

- open detailed logs
- inspect artifacts
- inspect parsed outputs
- rerun source
- rerun from a specific stage if supported

## 4. Raw Artifact Viewer

This module should allow internal users to inspect the raw source material that was fetched.

Supported artifact views may include:

- HTML source
- rendered page snapshot if available later
- PDF file
- extracted PDF text
- JSON payload

The artifact viewer should show:

- source URL
- fetch timestamp
- content hash
- artifact type
- related scrape run
- parser version at fetch time

This module is critical for debugging parser failures and source changes.

## 5. Parser Diagnostics

This module should focus on extraction quality.

It should help internal users answer:

- what fields failed to parse
- whether a parser change caused volume or quality drift
- whether a source layout change broke extraction
- whether a record is partially parsed or fully parsed

Useful views include:

- parser warnings by source
- parser error counts by source and run
- extraction field coverage
- comparison between parser versions
- historical parse counts per source

## 6. Restaurant Match Review

This module should support review of ambiguous or problematic restaurant matches.

Recommended capabilities:

- review unmatched restaurants
- review possible matches
- compare candidate master restaurants
- confirm, reject, or create a new master restaurant
- view historical match decisions
- review duplicate master restaurant candidates

Important displayed information:

- source restaurant name
- normalized name
- source address
- candidate master restaurants
- confidence scores
- identifiers such as permit or source listing id
- match explanation

This module should align closely with `RESTAURANT_MATCHING.md`.

## 7. Duplicate Review

This module should surface suspected duplicate inspections, findings, or restaurants.

Recommended capabilities:

- compare duplicate candidates side-by-side
- accept deduplication recommendation
- keep records separate
- merge duplicate master restaurant records through controlled workflows
- record reviewer decision and rationale

## 8. Validation and Publication Review

This module should show records that were held back from publication or approved with warnings.

Recommended capabilities:

- review validation failures
- inspect records with missing critical fields
- review records with suspicious score or grade values
- view records awaiting publication approval if manual gating is used
- approve, reject, or reprocess records

## 9. Source Change and Diff Review

This module should help analysts review records that changed materially from previously published versions.

Recommended capabilities:

- compare old and new inspection records
- compare old and new finding text
- detect score or grade changes
- review newly added or removed findings
- classify the change as material or non-material

Useful outcomes:

- accept updated canonical version
- flag for follow-up review
- note whether tenant-linked workflows may be affected

## 10. Reprocessing and Recovery Controls

The console should support operational recovery without requiring direct database editing or ad hoc scripts.

Recommended controls:

- rerun a source
- rerun parsing from stored artifacts
- rerun normalization
- republish validated records
- retry failed artifact fetches
- trigger a one-off refresh for a source

Important rule:

These controls should be guarded by permissions and produce audit logs.

## 11. Coverage and Freshness Reporting

This module should help the team understand what parts of the public inspection landscape are covered and how current that coverage is.

Recommended views:

- coverage by state
- coverage by jurisdiction type
- sources by freshness age
- sources with no recent successful runs
- inspection volume by source over time

This is especially useful as the platform expands from statewide sources into county and city-level sources.

## Core Operational States

The console should use clear source health states consistently.

Suggested health states:

- `healthy`
- `degraded`
- `failing`
- `stale`
- `needs_review`
- `paused`

Suggested run states:

- `queued`
- `running`
- `completed`
- `completed_with_warnings`
- `failed`
- `partially_processed`
- `awaiting_review`

## Alerts and Notifications

The console should surface operational alerts clearly.

Recommended alert conditions:

- source did not run within freshness target
- source run failed
- parsed record count dropped unexpectedly
- parser errors exceeded threshold
- validation holds exceeded threshold
- duplicate rate spiked
- unmatched restaurant rate spiked
- PDF fetch failure rate increased sharply

Recommended alert handling:

- show alerts in dashboard views
- allow filtering by severity and age
- track acknowledgment and resolution state

Suggested alert severities:

- `info`
- `warning`
- `critical`

## Audit Logging

The console should log important internal actions for accountability.

Examples:

- source paused or resumed
- manual source rerun triggered
- parser version changed
- restaurant match overridden
- duplicate merge approved
- validation rejection approved
- record republished

Suggested audit log fields:

- actor
- action
- target entity
- before state summary
- after state summary
- timestamp
- reason or notes

## Search and Filtering Requirements

The console should provide strong search and filtering because operational teams will need to locate issues quickly.

Recommended searchable fields:

- source name
- jurisdiction
- agency
- restaurant name
- inspection id
- run id
- parser version
- health state
- date range

## Permissions and Access Control

The console should support role-based internal permissions.

Examples:

- analysts can review but not change source configuration
- admins can pause sources and trigger reruns
- engineering operators can manage parser versions and advanced recovery actions

This is important because internal tooling can affect production master data quality.

## User Experience Recommendations

The console should favor clarity, speed, and investigation support over visual polish.

Recommended UX principles:

- put health and freshness issues first
- make drill-down fast from dashboard to source to run to artifact
- use side-by-side comparisons for diffs and duplicates
- show counts and trends, not just status labels
- make failed items actionable
- preserve context so operators can understand what happened without switching tools constantly

## Suggested Data Entities Behind the Console

The console will likely rely on entities such as:

- `SourceRegistry`
- `SourceHealth`
- `ScrapeRun`
- `RawArtifact`
- `ParseResult`
- `ValidationDecision`
- `MatchReviewRecord`
- `DedupDecision`
- `SourceVersion`
- `OperationalAlert`
- `AuditLog`

These entities may exist in backend services even if they are not all exposed directly to the tenant app.

## Version 1 Scope Recommendation

For version 1, the console should prioritize the smallest set of tools needed to safely operate the first wave of sources.

Recommended version 1 scope:

- source registry list and detail view
- source health dashboard
- scrape run explorer
- raw artifact viewer
- parser error and warning view
- restaurant match review
- manual rerun controls
- alert list for stale and failed sources
- basic audit log

This is enough to support early statewide source coverage while leaving room to grow into more advanced operational workflows later.

## Future Enhancements

Potential later enhancements:

- side-by-side parser version comparison
- automated anomaly scoring
- duplicate merge recommendation engine
- bulk reprocessing workflows
- source coverage maps
- source-specific maintenance playbooks
- internal commenting and assignment on operational issues

## Summary

The FiScore Internal Operations Console should be a dedicated internal product that helps the team run, monitor, and improve the public inspection master data platform. It should provide visibility into source health, scrape runs, parser quality, restaurant matching, duplicate handling, source changes, and reprocessing workflows.

As FiScore expands across more jurisdictions, this console becomes essential for maintaining trust in the data that powers the tenant-facing product.

