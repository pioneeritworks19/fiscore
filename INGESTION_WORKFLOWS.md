# FiScore Ingestion Workflows

## Purpose

This document defines the operational workflows for the FiScore master data ingestion platform. It describes how scheduled bots and backend services should discover, fetch, parse, normalize, validate, and publish public health department inspection data from government sources.

This document complements:

- `MASTER_DATA_ARCHITECTURE.md`
- `RESTAURANT_MATCHING.md`
- `DATA_MODEL.md`

The goal is to turn the master data platform into an implementation-ready ingestion system that can scale from a small number of state-wide sources to a much larger network of state, county, and city scrapers.

## Objectives

- ingest public inspection data reliably from many government sources
- preserve raw source artifacts for traceability and reprocessing
- normalize source-specific data into a shared FiScore master schema
- detect and handle parser failures and source changes
- prevent duplicate inspections and findings
- publish tenant-safe inspection data for linked restaurants
- support operational visibility across tens or hundreds of source pipelines

## Ingestion Design Principles

### 1. Raw Before Refined

Always preserve raw source material before or alongside parsing. This gives FiScore a defensible source trail and a path to reprocess data when parsers improve or source websites change.

### 2. Stage the Pipeline

The ingestion process should be broken into explicit stages so failures are isolated, diagnosable, and retryable.

### 3. Source-Specific Logic, Shared Output Model

Each government source may require custom discovery and parsing logic, but all successful outputs should map into a common FiScore master data model.

### 4. Publish Only Validated Data

Not every parsed record should immediately become tenant-visible. FiScore should pass records through deduplication and quality checks first.

### 5. Preserve Version History

If a source report changes, the system should preserve the prior version and publish the updated canonical version without destroying history.

## High-Level Workflow

At a high level, each source should move through these stages:

1. Discover
2. Fetch
3. Store Raw Artifacts
4. Parse
5. Normalize
6. Match Restaurants
7. Deduplicate
8. Validate
9. Version and Diff
10. Publish
11. Monitor and Alert

## Source Registry and Scheduling

Every scraper-managed data source should be defined in a source registry.

### Source Registry Responsibilities

- define jurisdiction coverage
- define source type and access pattern
- define scraping cadence
- define parser implementation and parser version
- define expected output shape
- define source health and freshness targets

### Suggested Source Registry Fields

- `sourceId`
- `jurisdictionId`
- `agencyId`
- `sourceName`
- `sourceType`
- `baseUrl`
- `cadenceType`
- `targetFreshnessDays`
- `parserId`
- `parserVersion`
- `status`
- `lastSuccessfulRunAt`
- `nextScheduledRunAt`

### Supported Cadence Types

- `weekly`
- `monthly`
- `manual`

Weekly and monthly are appropriate based on your current product direction, with manual reruns for support or correction workflows.

## Workflow Stage 1: Discover

The discovery stage identifies the records or artifacts that should be fetched from a source.

### Discovery Examples

- index pages that list recent inspections
- searchable restaurant result pages
- report detail pages
- PDF report links
- API endpoints if a source exposes them

### Discovery Outputs

- source page URLs
- report identifiers
- candidate inspection identifiers
- candidate artifact URLs

### Discovery Failure Modes

- source structure changed
- list pages return no data unexpectedly
- pagination broke
- authentication or anti-bot behavior changed

### Discovery Best Practices

- log the discovery count per run
- compare discovery volume to historical averages
- preserve discovery metadata for debugging

## Workflow Stage 2: Fetch

The fetch stage downloads the raw source materials discovered earlier.

### Fetch Targets

- HTML pages
- PDFs
- JSON payloads
- CSV exports
- images only if required for report completeness

### Fetch Requirements

- preserve original URL
- preserve fetch timestamp
- preserve HTTP status and relevant headers
- preserve content type
- support retries for transient failures

### Fetch Failure Modes

- timeouts
- DNS failures
- 403 or 429 responses
- changed URL patterns
- corrupted or truncated PDFs

### Fetch Best Practices

- retry transient failures with backoff
- mark persistent failures for review
- avoid losing already fetched data when one artifact fails

## Workflow Stage 3: Store Raw Artifacts

All important fetched materials should be stored durably before parsing or at least before publication.

### Raw Artifact Types

- raw HTML
- raw PDF
- extracted PDF text
- raw JSON or CSV payload
- screenshots only if useful for source diagnostics later

### Suggested Raw Artifact Metadata

- `artifactId`
- `sourceId`
- `scrapeRunId`
- `artifactType`
- `sourceUrl`
- `storagePath`
- `contentHash`
- `contentType`
- `fetchedAt`
- `parserVersionAtFetch`

### Why This Matters

- source websites change over time
- parsers can be improved later
- PDF extraction may need to be rerun
- operational teams need a way to inspect what was actually fetched

## Workflow Stage 4: Parse

The parse stage extracts structured fields from the raw source artifacts.

### Typical Parsed Outputs

- restaurant name
- restaurant address
- inspection date
- inspection score
- inspection grade
- report reference
- findings or violations
- violation clause or code
- violation text

### Parsing Sources

- HTML structure parsing
- PDF text extraction
- OCR only where truly necessary later
- API response field extraction when available

### Parse Failure Modes

- field not found due to layout change
- malformed table structures
- PDF extraction quality issues
- multiple inspections merged incorrectly
- findings separated poorly from narrative text

### Parse Best Practices

- preserve parser version used
- capture extraction warnings, not only hard failures
- distinguish between partial parse and full parse
- record field-level confidence where useful

## Workflow Stage 5: Normalize

The normalization stage maps source-specific parsed data into the FiScore master data model.

### Normalized Entities

- `MasterRestaurant`
- `MasterRestaurantIdentifier`
- `MasterInspection`
- `MasterInspectionReport`
- `MasterInspectionFinding`

### Normalization Responsibilities

- standardize address fields
- normalize names for matching
- map source score or grade representations
- normalize severity when possible
- convert source-specific dates to standard format
- preserve official text and codes as source snapshots

### Important Rule

Normalization should not destroy official source meaning. FiScore should preserve original codes, clauses, and text while also creating normalized fields for product use.

## Workflow Stage 6: Match Restaurants

Once records are normalized, the system should match them to canonical master restaurants.

### Matching Inputs

- official identifiers
- normalized restaurant name
- normalized address
- city, state, zip
- source-specific identifiers

### Match Outcomes

- matched to an existing master restaurant
- new master restaurant created
- ambiguous match flagged for review

### Best Practices

- prefer official identifiers over heuristic matching
- avoid merging records on weak evidence
- record match confidence and match method
- route ambiguity to internal review where needed

This stage should align with `RESTAURANT_MATCHING.md`.

## Workflow Stage 7: Deduplicate

Government sources and repeated scraper runs may produce duplicates. FiScore should deduplicate before publication.

### Deduplication Targets

- repeated inspections from multiple pages
- repeated report PDFs
- duplicate findings within the same inspection
- duplicate restaurant records created during matching

### Example Deduplication Signals

- same source inspection id
- same restaurant + inspection date + agency
- same report hash
- same finding code + text + inspection

### Deduplication Best Practices

- prefer deterministic keys where available
- preserve duplicate candidates for review instead of dropping blindly
- track deduplication decisions for auditability

## Workflow Stage 8: Validate

The validation stage determines whether normalized records are safe to publish.

### Validation Checks

- required fields present
- restaurant identity resolved or intentionally pending
- inspection date valid
- score or grade within expected ranges
- findings count within plausible limits
- source-to-parse volume not suspiciously low
- parser warnings below critical threshold

### Validation Outcomes

- `approved`
- `approved_with_warnings`
- `hold_for_review`
- `rejected`

### Best Practices

- keep validation rules source-aware where needed
- do not block the entire run because of one bad record
- make reviewable issues visible to internal ops

## Workflow Stage 9: Version and Diff

Public inspection data may change over time. FiScore should compare newly normalized records to existing canonical versions before publication.

### Diff Responsibilities

- detect newly added inspections
- detect updated inspection score or grade
- detect changed finding text or severity
- detect removed or newly added findings
- classify changes as material or non-material

### Versioning Policy

- preserve prior source artifacts
- preserve prior normalized versions where changes are material
- mark current canonical version clearly
- link tenant workflows to both source snapshots and latest master references when useful

### Change Classifications

#### Non-Material

- typo correction
- formatting cleanup
- PDF metadata change only

#### Material

- score change
- grade change
- finding added or removed
- violation text changed in a meaningful way
- severity changed

## Workflow Stage 10: Publish

Only validated and approved master records should move into the publish stage.

### Publish Targets

- master canonical data store
- tenant-readable projections for linked restaurants
- downstream analytics summaries if needed

### Publishing Rules

- only linked restaurant data becomes tenant-visible
- published public data remains read-only in tenant views
- linked public findings can create or update tenant-side actionable records according to product policy
- tenant responses remain private and separate from master data

### Public Findings to Tenant Workflow

For linked restaurants:

- public inspections should become viewable in tenant context
- public findings should become visible and actionable
- tenant-side violation records should link back to the master finding
- tenant users can manage response lifecycle privately within their tenant

## Workflow Stage 11: Monitor and Alert

Monitoring should be continuous and should operate both per-run and over time.

### Operational Metrics

- run success rate
- run duration
- discovery count
- fetched artifact count
- parse success count
- validation hold count
- publish count
- duplicate count
- unmatched restaurant count
- stale source count

### Alerting Conditions

- source has no successful run within freshness target
- parsed record volume drops sharply
- parser errors spike
- PDF fetch failures spike
- validation rejects exceed threshold
- discovery returns zero when historical expectation is non-zero

### Recommended Health States

- `healthy`
- `degraded`
- `failing`
- `stale`
- `needs_review`

## End-to-End Example Workflows

## Workflow A: Normal Successful Weekly Source Run

1. scheduler triggers source run
2. discovery finds updated inspection listing pages
3. fetch retrieves HTML pages and linked PDFs
4. artifacts are stored
5. parser extracts restaurants, inspections, and findings
6. normalization maps records into master schema
7. records are matched to master restaurants
8. duplicates are filtered
9. validation approves records
10. diff logic identifies new inspections and findings
11. canonical master records are updated
12. linked tenant projections are refreshed
13. source run is marked successful

## Workflow B: Source Website Structure Changed

1. scheduler triggers source run
2. discovery finds pages but parser fails to extract expected fields
3. extracted inspection count drops sharply relative to prior runs
4. run is marked degraded or failing
5. artifacts and error logs are preserved
6. alert is raised to internal operations
7. source is held for parser review
8. no broken tenant publication occurs

## Workflow C: Government Report Corrected After Publication

1. new run fetches an updated report for an existing inspection
2. diff stage detects a change in score or findings
3. change is classified as material
4. prior source version is retained
5. canonical master inspection is updated to the newest version
6. linked tenant projections are updated
7. affected tenant-linked records may be flagged for review if active workflows depend on the changed finding

## Workflow D: Ambiguous Restaurant Match

1. parser extracts a restaurant without a reliable permit id
2. normalized name and address partially match multiple master restaurants
3. confidence is insufficient for safe merge
4. record is routed to review
5. internal ops confirms the correct master restaurant or creates a new one
6. publication resumes after match resolution

## Suggested Core Operational Entities

The ingestion workflow will likely rely on entities such as:

- `SourceRegistry`
- `ScrapeRun`
- `DiscoveryRecord`
- `RawArtifact`
- `ParseResult`
- `NormalizationRecord`
- `MatchDecision`
- `DedupDecision`
- `ValidationDecision`
- `SourceVersion`
- `PublishRecord`
- `SourceHealth`

These do not all need to be exposed in the tenant-facing app, but they matter to the backend and internal operations.

## Retry and Recovery Strategy

The system should support retries at the stage level rather than rerunning entire workflows unnecessarily.

### Retry Recommendations

- retry transient fetch failures automatically
- support re-parse from stored raw artifacts without re-fetching
- support re-normalization when mapping logic changes
- support re-publication after validation or matching issues are resolved

This is one of the main benefits of keeping the stages separate.

## Version 1 Scope Recommendation

For version 1, FiScore should prioritize a simple but disciplined ingestion workflow:

- source registry with weekly or monthly scheduling
- raw artifact storage
- deterministic parsing where possible
- normalized master inspection and finding model
- basic restaurant matching
- duplicate checks
- validation gates
- tenant-scoped publication for linked restaurants
- operational alerts for stale or failed sources

Version 1 does not need perfect automation everywhere. It needs a pipeline that is trustworthy, inspectable, and maintainable.

## Open Design Decisions

These items still need final implementation decisions:

- whether discovery, fetch, parse, and publish run as separate jobs or a coordinated workflow engine
- how parser versions are packaged and deployed
- whether validation is fully rule-based or partly analyst-reviewed
- how aggressively changed public findings should trigger tenant notifications
- whether tenant projections are event-driven or rebuilt on a schedule
- how much OCR support is needed for PDF-heavy jurisdictions

## Summary

FiScore should implement public inspection ingestion as a staged workflow with durable raw artifact storage, source-aware parsing, normalization into a shared master schema, cautious restaurant matching, validation before publication, and strong operational monitoring.

This approach gives the platform a practical path to scaling from a handful of government sources to a much broader and more operationally demanding ingestion network.

