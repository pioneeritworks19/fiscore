# FiScore Master Data Architecture

## Purpose

This document defines the architecture for the FiScore master data platform, which is responsible for collecting, normalizing, storing, and publishing public health department inspection data for use by the FiScore tenant applications.

This subsystem is separate from the tenant-facing mobile and web apps. It acts as a shared compliance reference data platform that sits above tenant-owned application data.

The goal of this architecture is to support:

- scheduled scraping and ingestion from government sources
- storage of normalized public inspection data
- preservation of raw source artifacts such as HTML and PDF reports
- tenant-safe publishing of relevant inspection and violation data
- restaurant matching between master records and tenant-linked restaurants
- monitoring and operations for a growing fleet of scrapers

## Product Positioning

FiScore should be treated as two connected but distinct product domains:

### 1. Master Compliance Data Platform

This is the backend ingestion and reference data system that:

- monitors government data sources
- scrapes and parses public inspection information
- stores raw and normalized inspection records
- manages source changes and parser issues
- serves approved data to tenant-facing workflows

### 2. Tenant Compliance Application

This is the customer-facing app that:

- allows tenants to register and manage restaurants
- lets users link tenant restaurants to master restaurant records
- shows public inspection data only for linked restaurants
- creates private tenant-side workflows for violations and responses
- supports audits, CAPA, scoring, media evidence, and lifecycle tracking

## Architecture Principles

### 1. Separate Master Data from Tenant Data

Public inspection records are not tenant-owned records. They belong in the master data platform and should be managed separately from tenant workflows.

### 2. Use a Canonical Master Restaurant Identity

Every public restaurant record should be anchored by a FiScore-generated canonical identifier, even when government sources provide inconsistent naming or incomplete identifiers.

### 3. Support Source Traceability

Every normalized inspection, report, and finding should be traceable back to its government source, scrape run, parser version, and raw artifacts.

### 4. Publish Tenant-Scoped Views, Not Open Master Data

Tenants should only see inspection and finding data associated with restaurants they explicitly linked into their tenant.

### 5. Never Lose Historical Context

If a government report changes, FiScore should preserve prior source versions and protect tenant workflow history from being silently rewritten.

### 6. Build for Operations Early

Scraping across many jurisdictions is an operations-heavy backend capability. Monitoring, diagnostics, reprocessing, and source health management must be first-class concerns.

## High-Level System Layers

The master data platform should be organized into the following layers:

### 1. Source Registry Layer

Stores configuration for each government source, including:

- jurisdiction
- source type
- source URL patterns
- scraping cadence
- parser version
- authentication or access constraints if any
- expected report formats

### 2. Ingestion Layer

Handles scheduled bot execution for:

- page discovery
- report fetching
- HTML retrieval
- PDF downloads
- source file retention

### 3. Parsing and Normalization Layer

Transforms raw source material into structured master records such as:

- master restaurants
- public inspections
- public findings
- report metadata

### 4. Quality and Publishing Layer

Handles:

- deduplication
- confidence checks
- anomaly detection
- correction handling
- publication of approved records to tenant-facing read models

### 5. Operations and Monitoring Layer

Provides internal tooling and metrics to manage scraper health, investigate failures, and review changed outputs.

## Canonical Public Restaurant Identity

FiScore should not use `restaurant name + zip code` as the canonical restaurant identity by itself. That combination is useful for search but too weak to act as the long-term public identity anchor.

FiScore should also avoid treating restaurant name as the primary identity anchor in general. Names are useful for search and display, but they are less stable than the physical operating location.

### Recommendation

Use a layered identity model:

- FiScore canonical identity: `masterRestaurantId`
- primary canonical match anchor: `locationFingerprint`
- strongest source identity: `jurisdiction + official permit/license number` when available
- strong fallback identity: normalized physical location fields
- search identity: `zip code + name search`

### Why Name + Zip Alone Is Not Enough

- restaurant names may change
- names may be spelled differently across sources
- chain restaurants may share similar names in the same zip code
- zip codes can contain many nearby businesses
- public data may contain abbreviations or formatting inconsistencies

### Why a Location-First Model Is Stronger

- inspections are tied to physical operating locations
- health departments often regulate a facility or premises, not just a brand name
- names change more often than addresses
- official identifiers may be missing, but physical location data is usually present
- the same restaurant concept may appear with minor naming differences across sources while still operating at the same premises

### Recommended Canonical Identity Model

#### Master Restaurant

Suggested fields:

- `masterRestaurantId`
- `locationFingerprint`
- `normalizedName`
- `displayName`
- `normalizedAddress1`
- `normalizedUnit`
- `normalizedAddress2`
- `city`
- `state`
- `zip`
- `country`
- `latitude`
- `longitude`
- `status`

#### Master Restaurant Identifier

Suggested fields:

- `id`
- `masterRestaurantId`
- `identifierType`
- `identifierValue`
- `jurisdictionId`
- `sourceSystemId`
- `isPrimary`
- `confidence`

Suggested `identifierType` values:

- `permit_number`
- `license_number`
- `agency_restaurant_id`
- `source_listing_id`
- `location_fingerprint`

### Recommended Location Fingerprint

FiScore should generate a deterministic `locationFingerprint` from normalized location fields such as:

- normalized address line 1
- normalized unit or suite when available
- city
- state
- zip

Illustrative concept:

`hash(normalizedAddress1 + normalizedUnit + city + state + zip)`

This fingerprint should act as the primary canonical match anchor when a strong official identifier is not available.

### Important Caveat

The location fingerprint should not be treated as a perfect one-field identity by itself. It is best used together with:

- official identifiers when available
- alternate names
- source provenance
- manual review for ambiguous cases

## Tenant-to-Master Linking Model

Tenants should not freely browse the entire master dataset in a raw form. Instead, they should explicitly add restaurants by selecting them from a controlled search and match flow.

### Recommended User Workflow

1. Tenant user enters a zip code.
2. FiScore returns candidate master restaurants in that area.
3. User filters or searches by restaurant name.
4. User selects the correct restaurant.
5. FiScore creates a tenant-to-master restaurant link.
6. FiScore publishes the relevant public inspection history into the tenant context.

This user-assisted matching model reduces false positives and keeps linking explicit.

### Tenant Restaurant Link

Suggested fields:

- `id`
- `tenantId`
- `tenantRestaurantId`
- `masterRestaurantId`
- `matchMethod`
- `matchStatus`
- `matchConfidence`
- `linkedAt`
- `linkedBy`
- `overrideReason`

Suggested `matchMethod` values:

- `user_selected`
- `exact_identifier_match`
- `name_address_match`
- `manual_admin_link`

Suggested `matchStatus` values:

- `matched`
- `possible_match`
- `manual_review_required`
- `unmatched`

## Master Data Domain Model

The master data layer should contain the canonical public data that exists outside of tenants.

### Core Master Entities

- `Jurisdiction`
- `GovernmentAgency`
- `SourceRegistry`
- `ScrapeRun`
- `RawArtifact`
- `MasterRestaurant`
- `MasterRestaurantIdentifier`
- `MasterInspection`
- `MasterInspectionReport`
- `MasterInspectionFinding`
- `MasterSourceVersion`

### Example Entity Purposes

#### Jurisdiction

Defines the geography or authority boundary, such as:

- state
- county
- city

#### Government Agency

Represents the public health or inspection authority responsible for the source data.

#### Source Registry

Stores the configuration and status of each scraper-managed data source.

#### Raw Artifact

Stores fetched source material such as:

- HTML pages
- PDFs
- extracted text
- JSON responses if available

#### Master Inspection

Represents a normalized public inspection record linked to a master restaurant.

#### Master Inspection Finding

Represents a normalized violation or finding from a public inspection record.

## Tenant Publishing Model

Tenants should not read master data live in a broad, unrestricted way. They should only see public inspection data related to restaurants they added into their tenant.

### Recommendation

Use tenant-scoped projections or tenant-readable linked records rather than direct open access to the master domain.

This means:

- master data remains global and internally managed
- tenant-facing records are created only for linked restaurants
- public source facts remain read-only in tenant views
- tenant workflows such as responses, closures, and CAPA remain private tenant-owned records

### Tenant-Published Data

When a restaurant is linked into a tenant, the platform should make available:

- recent and historical public inspections
- public report references and PDF metadata
- public findings and violations
- source dates and agency references
- summary metrics for display in the app

### Public Findings to Tenant Violations

Public findings for a linked restaurant should be brought into the tenant so the tenant can track internal response and lifecycle.

Recommended model:

- preserve the master public finding as the source-of-truth reference record
- create a tenant violation record linked to the master finding
- keep the tenant violation private to the tenant
- allow the tenant to manage internal remediation, CAPA, attachments, review, and closure
- never expose tenant responses back to the public source or agency

This supports internal operational readiness while keeping public and tenant data boundaries clean.

## Ingestion Pipeline

The master data platform should process public data through clear stages instead of using ad hoc one-step scraping scripts.

### Recommended Pipeline Stages

#### 1. Discover

Find relevant pages, listings, API endpoints, inspection reports, and report PDFs.

#### 2. Fetch

Retrieve HTML, PDFs, and other source artifacts and store them durably.

#### 3. Parse

Extract restaurants, inspections, report metadata, scores, grades, clauses, and findings.

#### 4. Normalize

Map source-specific structures into the FiScore master schema.

#### 5. Match and Link

Match inspection records to the correct master restaurant identity.

#### 6. Deduplicate

Detect and prevent duplicate inspections and duplicate findings.

#### 7. Validate

Apply data quality checks and anomaly detection before publishing.

#### 8. Publish

Make approved records available to tenant-scoped projections and downstream app queries.

#### 9. Monitor

Track source freshness, parser health, volume changes, and operational anomalies.

## Raw Artifact Retention

Raw source material should be preserved whenever practical.

Recommended retained artifacts:

- fetched HTML
- original PDFs
- extracted text
- parser version used
- fetch timestamps
- source URLs

This is important for:

- debugging parser failures
- investigating source changes
- comparing older and newer source versions
- preserving defensible traceability

## Handling Corrected or Changed Government Reports

Government sources may revise inspection reports after initial publication. FiScore should handle this with version-aware source management instead of silently rewriting history.

### Recommended Policy

- Keep the newest published government data as the current canonical master version
- Preserve prior source versions and raw artifacts
- Mark materially changed records as updated from source
- Protect tenant workflow history from silent mutation

### Types of Changes

#### Non-Material Changes

Examples:

- formatting changes
- corrected typos
- PDF replacement with equivalent content

Recommended handling:

- update canonical master record
- keep prior raw artifact and version history
- no tenant alert unless business value exists

#### Material Changes

Examples:

- score changed
- grade changed
- finding added or removed
- severity changed
- clause or official violation text changed

Recommended handling:

- create a new source version
- mark the master inspection or finding as materially updated
- preserve the prior normalized version
- flag linked tenant-side read models if the change affects active workflows

### Tenant Workflow Protection

If a tenant already created or is managing a violation based on a public finding that later changes:

- keep the tenant violation record intact
- preserve the source snapshot used at the time the tenant record was created
- link the tenant record to the latest master source version
- optionally surface a review notification if the source change is significant

This avoids confusing users by silently changing the historical basis of their internal work.

## Data Freshness Strategy

The platform should support source-specific freshness cadences rather than one universal schedule.

### Recommended Freshness Model

- weekly for active statewide sources with frequent changes
- monthly for lower-volume or slower-moving sources
- manual rerun capability for high-value support cases or urgent investigations

### Source Registry Freshness Fields

Suggested fields:

- `cadenceType`
- `targetFreshnessDays`
- `lastSuccessfulRunAt`
- `nextScheduledRunAt`
- `sourceHealthStatus`
- `stalenessReason`

This allows FiScore to scale gradually from a small number of state-level sources to a much broader jurisdiction set.

## Jurisdiction Rollout Strategy

The rollout strategy should prioritize coverage efficiency and operational maintainability.

### Recommended Phasing

#### Phase 1

Start with states that expose inspection data statewide.

Benefits:

- broad coverage per source
- fewer scraper variants
- simpler operations

#### Phase 2

Expand into states where inspection data is county-specific.

#### Phase 3

Expand into city-specific sources where business opportunity justifies the additional source complexity.

This staged approach helps the team avoid taking on too much scraper maintenance too early.

## Monitoring and Failure Detection

Managing a large fleet of scrapers requires strong operational visibility. Scrapers will fail over time as source websites change structure, permissions, layouts, and publication formats.

### Source Operations Must Track

- run success and failure rate
- freshness age by source
- pages fetched
- reports downloaded
- inspections parsed
- findings parsed
- duplicate rates
- unmatched restaurant rates
- parser exceptions
- PDF retrieval errors

### Recommended Health States

- `healthy`
- `degraded`
- `failing`
- `stale`
- `needs_review`

### Useful Anomaly Signals

- zero records parsed where records are normally expected
- sudden drop in extraction counts
- large increase in parser errors
- change in source structure signature
- spike in duplicate outputs
- missing previously reliable fields

### Recommended Operational Capabilities

- source health dashboard
- scraper run history
- parser error queue
- raw artifact viewer
- manual rerun controls
- stale source alerting
- jurisdiction coverage visibility

## Internal Operations Console

The master data platform should include an internal-facing operations console separate from the tenant app.

This console should support:

- source registry management
- scrape run monitoring
- parser diagnostics
- raw artifact inspection
- restaurant match review
- source freshness review
- data quality correction workflows
- manual publish or reprocess controls where needed

This is not optional at scale. Once the platform supports dozens or hundreds of sources, internal operations tooling becomes a core part of the product.

## Security and Data Boundaries

The platform should enforce clean separation between internal source operations and tenant-facing data.

### Master Data Access

- internal systems and admins can manage source records, raw artifacts, parser outputs, and source health
- tenant users should not access arbitrary master records outside their linked restaurants

### Tenant Data Access

- tenants should only see records associated with restaurants they explicitly linked
- tenant responses, CAPA plans, closures, and evidence must remain private to the tenant
- government agencies and the public should not see tenant remediation data through FiScore

## Recommended Initial Supporting Docs

The following documents remain relevant and are still strongly recommended as the next supporting architecture set:

- `RESTAURANT_MATCHING.md`
  Defines canonical matching rules, confidence, manual review handling, and user-assisted linking logic
- `INGESTION_WORKFLOWS.md`
  Defines discover, fetch, parse, normalize, deduplicate, validate, and publish flows in more operational detail
- `INTERNAL_OPS_CONSOLE.md`
  Defines the internal tooling needed to monitor, debug, and maintain the scraper fleet

These docs complement this architecture document and help turn the master data platform into an implementation-ready subsystem.

## Summary

FiScore should treat public health department inspection data as a centralized master data platform that exists outside the tenant app. The platform should use canonical master restaurant identities, preserve raw source artifacts, publish tenant-scoped views for linked restaurants, automatically create private tenant workflows from public findings, and manage corrected source reports through versioned historical handling.

Because scraper coverage will grow across states, counties, and cities, the platform must also include strong monitoring, operational tooling, and source health management from early in its lifecycle.
