# FiScore Master Data Schema

## Purpose

This document defines the logical schema for the FiScore master data platform.

The master data platform is the backend subsystem responsible for:

- storing the canonical restaurant master list
- tracking government sources and jurisdictions
- ingesting and normalizing public inspection data
- linking source records to FiScore master restaurants
- preserving raw source artifacts and source version history
- publishing tenant-safe inspection and finding data for linked restaurants

This schema is separate from the tenant-facing application schema. It supports the public inspection ingestion side of FiScore and should be treated as its own system of record.

## Scope

This schema focuses on:

- jurisdictions and agencies
- source registry and scraper runs
- raw artifacts and parsing outputs
- canonical master restaurant identity
- source identifiers and location-first matching
- inspections, reports, and findings
- source versioning and change tracking
- publication state
- internal operational review support

This is a logical relational schema intended to fit well with PostgreSQL.

## Design Principles

### 1. Canonical Identity Is FiScore-Owned

The stable restaurant identity is `master_restaurant_id`, not a third-party source identifier.

### 2. Location-First Matching

The primary canonical match anchor is `location_fingerprint`, generated from normalized location fields. Official agency identifiers are strong supporting proofs when available.

### 3. Source Traceability

Every inspection, finding, and normalized record should be traceable to source, scrape run, parser version, and raw artifacts.

### 4. Version-Aware Public Data

Government reports can change. The schema should preserve prior source versions and mark the latest canonical version clearly.

### 5. Publishing Is Controlled

Master data is global and internal. Tenant-facing data should be published through explicit projections or linked read models, not by exposing raw master tables directly.

## Core Schema Areas

The schema is organized into these main areas:

- geography and agencies
- source registry and ingestion runs
- master restaurants and identifiers
- inspections and findings
- artifacts and parsing
- versioning and publication
- review and operational support

## 1. Jurisdiction

Represents the authority boundary for a data source.

### Table: `jurisdiction`

Suggested fields:

- `jurisdiction_id` UUID PK
- `jurisdiction_type` text
- `name` text
- `state_code` text
- `county_name` text nullable
- `city_name` text nullable
- `country_code` text default `US`
- `status` text
- `created_at` timestamp
- `updated_at` timestamp

Suggested `jurisdiction_type` values:

- `state`
- `county`
- `city`

## 2. Government Agency

Represents the agency publishing public inspection data.

### Table: `government_agency`

Suggested fields:

- `agency_id` UUID PK
- `jurisdiction_id` UUID FK -> `jurisdiction.jurisdiction_id`
- `name` text
- `agency_type` text
- `website_url` text
- `status` text
- `created_at` timestamp
- `updated_at` timestamp

## 3. Source Registry

Represents a configured public data source managed by the ingestion platform.

### Table: `source_registry`

Suggested fields:

- `source_id` UUID PK
- `jurisdiction_id` UUID FK -> `jurisdiction.jurisdiction_id`
- `agency_id` UUID FK -> `government_agency.agency_id`
- `source_name` text
- `source_type` text
- `base_url` text
- `access_method` text
- `cadence_type` text
- `target_freshness_days` integer
- `parser_id` text
- `parser_version` text
- `status` text
- `last_successful_run_at` timestamp nullable
- `next_scheduled_run_at` timestamp nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `source_type` values:

- `html_listing`
- `html_detail`
- `pdf_reports`
- `api`
- `csv`
- `arcgis`

Suggested `cadence_type` values:

- `weekly`
- `monthly`
- `manual`

## 4. Scrape Run

Represents one execution of a source ingestion workflow.

### Table: `scrape_run`

Suggested fields:

- `scrape_run_id` UUID PK
- `source_id` UUID FK -> `source_registry.source_id`
- `run_status` text
- `started_at` timestamp
- `completed_at` timestamp nullable
- `duration_ms` bigint nullable
- `discovery_count` integer default 0
- `artifact_count` integer default 0
- `parsed_record_count` integer default 0
- `normalized_record_count` integer default 0
- `validation_hold_count` integer default 0
- `published_record_count` integer default 0
- `duplicate_count` integer default 0
- `error_count` integer default 0
- `warning_count` integer default 0
- `parser_version` text
- `trigger_type` text
- `error_summary` text nullable
- `created_at` timestamp

Suggested `run_status` values:

- `queued`
- `running`
- `completed`
- `completed_with_warnings`
- `failed`
- `awaiting_review`

## 5. Raw Artifact

Represents a fetched source artifact.

### Table: `raw_artifact`

Suggested fields:

- `raw_artifact_id` UUID PK
- `source_id` UUID FK -> `source_registry.source_id`
- `scrape_run_id` UUID FK -> `scrape_run.scrape_run_id`
- `artifact_type` text
- `source_url` text
- `source_reference` text nullable
- `storage_path` text
- `content_hash` text
- `content_type` text
- `file_size_bytes` bigint nullable
- `fetched_at` timestamp
- `parser_version_at_fetch` text nullable
- `http_status_code` integer nullable
- `created_at` timestamp

Suggested `artifact_type` values:

- `html`
- `pdf`
- `json`
- `csv`
- `text_extract`

## 6. Master Restaurant

Represents the FiScore-owned canonical restaurant identity.

### Table: `master_restaurant`

Suggested fields:

- `master_restaurant_id` UUID PK
- `location_fingerprint` text not null
- `display_name` text
- `normalized_name` text
- `alternate_names` jsonb nullable
- `address_line1` text
- `address_line2` text nullable
- `normalized_address1` text
- `normalized_unit` text nullable
- `city` text
- `state_code` text
- `zip_code` text
- `country_code` text default `US`
- `latitude` numeric nullable
- `longitude` numeric nullable
- `primary_jurisdiction_id` UUID nullable FK -> `jurisdiction.jurisdiction_id`
- `status` text
- `source_count` integer default 0
- `first_seen_at` timestamp nullable
- `last_seen_at` timestamp nullable
- `created_at` timestamp
- `updated_at` timestamp

### Recommended Indexes

- unique-ish index on `location_fingerprint` with care for edge cases
- index on `zip_code`
- index on `normalized_name`
- index on `(state_code, city, zip_code)`

### Important Note

`location_fingerprint` is the primary canonical match anchor, but it should not be treated as a perfect uniqueness guarantee in all cases. Shared kitchens, ownership changes, food halls, and multi-concept addresses may require review logic beyond a simple unique constraint.

## 7. Master Restaurant Identifier

Represents external identifiers associated with a master restaurant.

### Table: `master_restaurant_identifier`

Suggested fields:

- `master_restaurant_identifier_id` UUID PK
- `master_restaurant_id` UUID FK -> `master_restaurant.master_restaurant_id`
- `jurisdiction_id` UUID nullable FK -> `jurisdiction.jurisdiction_id`
- `source_id` UUID nullable FK -> `source_registry.source_id`
- `identifier_type` text
- `identifier_value` text
- `is_primary` boolean default false
- `confidence` numeric nullable
- `first_seen_at` timestamp nullable
- `last_seen_at` timestamp nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `identifier_type` values:

- `permit_number`
- `license_number`
- `agency_restaurant_id`
- `source_listing_id`
- `location_fingerprint`

## 8. Master Restaurant Source Link

Tracks how a master restaurant is connected to a specific source record.

### Table: `master_restaurant_source_link`

Suggested fields:

- `master_restaurant_source_link_id` UUID PK
- `master_restaurant_id` UUID FK -> `master_restaurant.master_restaurant_id`
- `source_id` UUID FK -> `source_registry.source_id`
- `source_restaurant_key` text
- `match_method` text
- `match_confidence` numeric nullable
- `match_status` text
- `matched_by` text
- `matched_at` timestamp
- `review_notes` text nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `match_method` values:

- `exact_identifier_match`
- `location_fingerprint_match`
- `name_address_match`
- `manual_review_match`

Suggested `match_status` values:

- `matched`
- `possible_match`
- `manual_review_required`
- `rejected`

## 9. Master Inspection

Represents a normalized public inspection record.

### Table: `master_inspection`

Suggested fields:

- `master_inspection_id` UUID PK
- `master_restaurant_id` UUID FK -> `master_restaurant.master_restaurant_id`
- `source_id` UUID FK -> `source_registry.source_id`
- `agency_id` UUID FK -> `government_agency.agency_id`
- `jurisdiction_id` UUID FK -> `jurisdiction.jurisdiction_id`
- `source_inspection_key` text
- `inspection_date` date
- `inspection_type` text nullable
- `score` numeric nullable
- `grade` text nullable
- `official_status` text nullable
- `report_url` text nullable
- `current_source_version_id` UUID nullable
- `is_current` boolean default true
- `published_at` timestamp nullable
- `created_at` timestamp
- `updated_at` timestamp

### Recommended Constraints

- unique composite candidate on `(source_id, source_inspection_key)` where source keys are stable

## 10. Master Inspection Report

Represents report-level metadata and linked artifacts for an inspection.

### Table: `master_inspection_report`

Suggested fields:

- `master_inspection_report_id` UUID PK
- `master_inspection_id` UUID FK -> `master_inspection.master_inspection_id`
- `raw_artifact_id` UUID nullable FK -> `raw_artifact.raw_artifact_id`
- `report_type` text
- `report_url` text nullable
- `storage_path` text nullable
- `content_hash` text nullable
- `report_date` date nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `report_type` values:

- `official_pdf`
- `html_detail`
- `text_extract`

## 11. Master Inspection Finding

Represents a normalized public finding or violation from an inspection.

### Table: `master_inspection_finding`

Suggested fields:

- `master_inspection_finding_id` UUID PK
- `master_inspection_id` UUID FK -> `master_inspection.master_inspection_id`
- `source_id` UUID FK -> `source_registry.source_id`
- `source_finding_key` text nullable
- `finding_order` integer nullable
- `official_code` text nullable
- `official_clause_reference` text nullable
- `source_clause_reference_id` UUID nullable
- `official_text` text
- `normalized_title` text nullable
- `normalized_category` text nullable
- `severity` text nullable
- `risk_level` text nullable
- `is_current` boolean default true
- `current_source_version_id` UUID nullable
- `created_at` timestamp
- `updated_at` timestamp

### Recommended Notes

- preserve official source text even when normalized titles or categories are added
- source finding keys may be absent for some jurisdictions, so ordering and text hashes may also matter for deduplication

## 11A. Source Clause Reference

Represents source-specific clause or rule reference data linked from findings.

This entity should store clause reference content separately from inspection-specific finding narratives because:

- the same clause may appear across many findings
- clause descriptions are reference material, not the observed violation instance itself
- clause wording may vary by source and may even vary by county within the same platform

### Table: `source_clause_reference`

Suggested fields:

- `source_clause_reference_id` UUID PK
- `source_id` UUID FK -> `source_registry.source_id`
- `jurisdiction_id` UUID nullable FK -> `jurisdiction.jurisdiction_id`
- `clause_code` text
- `violation_category` text nullable
- `clause_description` text
- `content_hash` text nullable
- `first_seen_at` timestamp nullable
- `last_seen_at` timestamp nullable
- `is_current` boolean default true
- `created_at` timestamp
- `updated_at` timestamp

### Recommended Notes

- uniqueness should be scoped by source and jurisdiction context, not assumed globally by clause code alone
- the same clause code may carry different wording across different sources or counties
- findings should reference this entity when clause enrichment is available

## 12. Parse Result

Represents structured outputs or warnings from parsing.

### Table: `parse_result`

Suggested fields:

- `parse_result_id` UUID PK
- `scrape_run_id` UUID FK -> `scrape_run.scrape_run_id`
- `raw_artifact_id` UUID nullable FK -> `raw_artifact.raw_artifact_id`
- `source_id` UUID FK -> `source_registry.source_id`
- `parser_version` text
- `record_type` text
- `source_record_key` text nullable
- `parse_status` text
- `payload` jsonb
- `warning_count` integer default 0
- `error_count` integer default 0
- `created_at` timestamp

Suggested `record_type` values:

- `restaurant`
- `inspection`
- `finding`

Suggested `parse_status` values:

- `parsed`
- `parsed_with_warnings`
- `failed`
- `partial`

## 13. Validation Decision

Represents a validation outcome for normalized records.

### Table: `validation_decision`

Suggested fields:

- `validation_decision_id` UUID PK
- `scrape_run_id` UUID FK -> `scrape_run.scrape_run_id`
- `entity_type` text
- `entity_id` UUID nullable
- `decision_status` text
- `decision_reason` text nullable
- `details` jsonb nullable
- `decided_by` text nullable
- `decided_at` timestamp
- `created_at` timestamp

Suggested `decision_status` values:

- `approved`
- `approved_with_warnings`
- `hold_for_review`
- `rejected`

## 14. Source Version

Represents a versioned source snapshot for an inspection or finding when government data changes.

### Table: `source_version`

Suggested fields:

- `source_version_id` UUID PK
- `source_id` UUID FK -> `source_registry.source_id`
- `entity_type` text
- `entity_id` UUID nullable
- `source_entity_key` text nullable
- `version_number` integer
- `is_current` boolean default false
- `change_type` text
- `change_summary` text nullable
- `raw_payload` jsonb nullable
- `content_hash` text nullable
- `effective_at` timestamp
- `created_at` timestamp

Suggested `change_type` values:

- `new`
- `non_material_update`
- `material_update`
- `superseded`

## 15. Publish Record

Tracks whether a master record has been published to downstream tenant-facing projections or read models.

### Table: `publish_record`

Suggested fields:

- `publish_record_id` UUID PK
- `entity_type` text
- `entity_id` UUID
- `source_version_id` UUID nullable FK -> `source_version.source_version_id`
- `publish_target` text
- `publish_status` text
- `published_at` timestamp nullable
- `last_attempted_at` timestamp nullable
- `attempt_count` integer default 0
- `error_summary` text nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `publish_target` values:

- `tenant_projection`
- `analytics_projection`

Suggested `publish_status` values:

- `pending`
- `published`
- `failed`
- `skipped`

## 16. Match Review Record

Represents ambiguous restaurant match reviews.

### Table: `match_review_record`

Suggested fields:

- `match_review_record_id` UUID PK
- `source_id` UUID FK -> `source_registry.source_id`
- `source_restaurant_key` text
- `candidate_master_restaurant_ids` jsonb
- `review_status` text
- `review_notes` text nullable
- `reviewed_by` text nullable
- `reviewed_at` timestamp nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `review_status` values:

- `pending`
- `approved`
- `rejected`
- `needs_more_work`

## 17. Dedup Decision

Represents duplicate review and merge decisions.

### Table: `dedup_decision`

Suggested fields:

- `dedup_decision_id` UUID PK
- `entity_type` text
- `primary_entity_id` UUID
- `duplicate_entity_id` UUID
- `decision` text
- `decision_reason` text nullable
- `decided_by` text nullable
- `decided_at` timestamp
- `created_at` timestamp

Suggested `decision` values:

- `merge`
- `keep_separate`
- `supersede`

## 18. Source Health

Represents the operational status of a source.

### Table: `source_health`

Suggested fields:

- `source_health_id` UUID PK
- `source_id` UUID FK -> `source_registry.source_id`
- `health_status` text
- `freshness_age_days` integer nullable
- `last_evaluated_at` timestamp
- `signal_summary` jsonb nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `health_status` values:

- `healthy`
- `degraded`
- `failing`
- `stale`
- `needs_review`
- `paused`

## 19. Operational Alert

Represents issues surfaced by monitoring or validation.

### Table: `operational_alert`

Suggested fields:

- `operational_alert_id` UUID PK
- `source_id` UUID nullable FK -> `source_registry.source_id`
- `scrape_run_id` UUID nullable FK -> `scrape_run.scrape_run_id`
- `alert_type` text
- `severity` text
- `status` text
- `title` text
- `message` text
- `acknowledged_by` text nullable
- `acknowledged_at` timestamp nullable
- `resolved_by` text nullable
- `resolved_at` timestamp nullable
- `created_at` timestamp
- `updated_at` timestamp

Suggested `severity` values:

- `info`
- `warning`
- `critical`

Suggested `status` values:

- `open`
- `acknowledged`
- `resolved`

## 20. Audit Log

Represents internal operational actions on the master data platform.

### Table: `master_data_audit_log`

Suggested fields:

- `master_data_audit_log_id` UUID PK
- `actor_id` text nullable
- `actor_type` text nullable
- `action_type` text
- `target_entity_type` text
- `target_entity_id` UUID nullable
- `before_state` jsonb nullable
- `after_state` jsonb nullable
- `reason` text nullable
- `created_at` timestamp

## Relationship Summary

High-level relationships:

- `jurisdiction` -> many `government_agency`
- `government_agency` -> many `source_registry`
- `source_registry` -> many `scrape_run`
- `scrape_run` -> many `raw_artifact`
- `scrape_run` -> many `parse_result`
- `master_restaurant` -> many `master_restaurant_identifier`
- `master_restaurant` -> many `master_restaurant_source_link`
- `master_restaurant` -> many `master_inspection`
- `master_inspection` -> many `master_inspection_report`
- `master_inspection` -> many `master_inspection_finding`
- version-sensitive entities -> many `source_version`

## Suggested Uniqueness and Index Strategy

The exact physical schema can evolve, but these constraints are strong candidates:

- `source_registry`: unique meaningful key by source name or agency/source combination
- `master_restaurant_identifier`: unique on `(identifier_type, identifier_value, jurisdiction_id)` where safe
- `master_inspection`: unique on `(source_id, source_inspection_key)` where source keys are stable
- `master_inspection_finding`: unique on `(source_id, source_finding_key)` where source keys are stable
- indexes for `location_fingerprint`, `zip_code`, `normalized_name`, `inspection_date`, and `health_status`

## Example Location Fingerprint Inputs

FiScore should generate `location_fingerprint` from normalized location inputs such as:

- `normalized_address1`
- `normalized_unit`
- `city`
- `state_code`
- `zip_code`

Illustrative concept:

`hash(normalized_address1 + normalized_unit + city + state_code + zip_code)`

This fingerprint should be used as the primary canonical match anchor, especially when official permit or facility identifiers are unavailable.

## Important Caveats

The master schema should not assume that location alone is always enough for uniqueness.

Examples of edge cases:

- ownership change at the same location
- multiple concepts in one physical address
- food halls or shared kitchens
- permit turnover with stable address

Because of that:

- `location_fingerprint` should be a strong match anchor, not an unquestionable truth
- source identifiers still matter
- duplicate review and match review workflows remain important

## Suggested Version 1 Priority Tables

For version 1, the highest-value tables to implement first are:

- `jurisdiction`
- `government_agency`
- `source_registry`
- `scrape_run`
- `raw_artifact`
- `master_restaurant`
- `master_restaurant_identifier`
- `master_restaurant_source_link`
- `master_inspection`
- `master_inspection_report`
- `master_inspection_finding`
- `source_version`
- `source_health`
- `operational_alert`

These are enough to support the first working ingestion and publication pipeline.

## Future Extensions

Potential later additions:

- source-specific field mapping tables
- parser performance analytics
- richer publication dependency tracking
- merge history tables for master restaurant consolidation
- confidence scoring history
- search index support tables

## Summary

The FiScore master data schema should use a FiScore-owned canonical restaurant identity, anchored by `master_restaurant_id` and strengthened through a location-first `location_fingerprint` model plus official source identifiers. The schema should preserve source traceability, support government data changes through versioning, and provide the operational structure needed to run a growing public inspection ingestion platform.
