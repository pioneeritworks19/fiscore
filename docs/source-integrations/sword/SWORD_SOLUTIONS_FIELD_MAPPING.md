# FiScore Sword Solutions Field Mapping

## Purpose

This document defines how data from the Sword Solutions inspections platform should map into FiScore's ingestion and master data model.

The goal is to provide a practical field-level reference for:

- parser implementation
- normalization logic
- master data storage
- tenant-facing projection logic

This document should be used alongside:

- `SWORD_SOLUTIONS_INGESTION_PLAN.md`
- `MASTER_DATA_SCHEMA.md`
- `MASTER_DATA_ARCHITECTURE.md`
- `RESTAURANT_MATCHING.md`

## Scope

This mapping covers the fields relevant to:

- restaurant header data
- inspection header data
- violation data

The intent is to capture the fields that matter for FiScore product behavior, not every possible source field that may appear in the Sword interface.

## Source Overview

The Sword Solutions inspections site presents search and inspection data across multiple Michigan counties using a shared interface.

From the public search page, the search criteria visibly include:

- state/county
- address
- city
- license number
- restaurant name
- from date
- to date
- show partial

The site also states that it is publishing food service inspection summaries for participating health departments.

## Mapping Philosophy

### 1. Preserve Source Meaning

Official inspection and violation text should be preserved in source form wherever possible.

### 2. Normalize Only What Helps Product Use

Normalization should improve:

- restaurant identity
- inspection history
- violation workflows
- tenant-facing usability

without destroying the original source meaning.

### 3. Separate Source Fields from Canonical Fields

Sword fields should map into:

- raw source storage
- parsed intermediate payloads
- normalized master records

### 4. Use County + License Number as the Strongest Source Identifier

When a license number exists, the combination of:

- county
- license number

should be treated as the strongest Sword-source establishment identifier.

## Source Entity Model

For mapping purposes, the Sword Solutions source can be thought of as producing three core entity types:

- `source_restaurant`
- `source_inspection`
- `source_violation`

## 1. Restaurant Header Mapping

This section maps restaurant-level fields from Sword into FiScore structures.

## Source Restaurant Fields

Expected or likely source fields:

- county
- restaurant name
- address
- city
- state
- zip code if present
- license number

## Parsed Restaurant Payload

Recommended parsed payload fields:

- `platform`
- `source_id`
- `county_name`
- `restaurant_name_raw`
- `address_raw`
- `city_raw`
- `state_raw`
- `zip_raw`
- `license_number_raw`
- `source_restaurant_key`

### Recommended Derived Parsed Fields

- `restaurant_name_normalized`
- `address_normalized`
- `unit_normalized`
- `location_fingerprint_candidate`

## Normalized Master Mapping

### Map to `master_restaurant`

| Sword parsed field | FiScore target field | Notes |
|---|---|---|
| `restaurant_name_raw` | `display_name` | Preserve readable source name |
| `restaurant_name_normalized` | `normalized_name` | Used for matching and search |
| `address_raw` | `address_line1` / `address_line2` | Split if parser can do so reliably |
| `address_normalized` | `normalized_address1` | Used for location matching |
| `unit_normalized` | `normalized_unit` | Nullable |
| `city_raw` | `city` | Preserve source city |
| `state_raw` | `state_code` | Expected `MI` |
| `zip_raw` | `zip_code` | Nullable if absent |
| derived location hash | `location_fingerprint` | Primary canonical match anchor |
| county name | `primary_jurisdiction_id` | Resolve through jurisdiction mapping |

### Map to `master_restaurant_identifier`

| Sword parsed field | FiScore target field | Notes |
|---|---|---|
| `license_number_raw` | `identifier_value` | Strongest source identifier |
| constant | `identifier_type = permit_number` or `license_number` | Choose based on actual Sword semantics |
| county source | `jurisdiction_id` | County-scoped identifier |
| county + license | supporting composite identity logic | Not necessarily a single field in schema |

### Map to `master_restaurant_source_link`

| Sword parsed field | FiScore target field | Notes |
|---|---|---|
| `source_restaurant_key` | `source_restaurant_key` | If available, else derive |
| county + license | `match_method` | Usually `exact_identifier_match` when stable |
| county + license | `match_status` | Usually `matched` when confidence is strong |

## Source Restaurant Identity Rules

### Source Restaurant Key Recommendation

If Sword exposes a stable internal record key, use it.

If not, derive a source record key from:

- county
- license number

Fallback if license is unavailable:

- county
- normalized restaurant name
- normalized address

## 2. Inspection Header Mapping

This section maps inspection-level fields from Sword into FiScore structures.

## Source Inspection Fields

Expected or likely source fields:

- inspection date
- inspection type
- score
- grade
- status or result
- summary details
- linked restaurant context

## Parsed Inspection Payload

Recommended parsed payload fields:

- `source_restaurant_key`
- `county_name`
- `license_number_raw`
- `inspection_date_raw`
- `inspection_type_raw`
- `inspection_score_raw`
- `inspection_grade_raw`
- `inspection_status_raw`
- `inspection_summary_raw`
- `source_inspection_key`

## Normalized Inspection Mapping

### Map to `master_inspection`

| Sword parsed field | FiScore target field | Notes |
|---|---|---|
| `source_inspection_key` | `source_inspection_key` | Use if stable |
| resolved restaurant | `master_restaurant_id` | From match pipeline |
| county source | `source_id` | County-specific source |
| county jurisdiction | `jurisdiction_id` | County-level jurisdiction |
| `inspection_date_raw` | `inspection_date` | Parse to date |
| `inspection_type_raw` | `inspection_type` | Preserve raw meaning |
| `inspection_score_raw` | `score` | Numeric if available |
| `inspection_grade_raw` | `grade` | Text if available |
| `inspection_status_raw` | `official_status` | Preserve official result language |
| detail/report URL if available | `report_url` | Optional |

### Derived Inspection Identity Recommendation

If Sword does not expose a stable inspection identifier, derive one using:

- county
- license number
- inspection date
- inspection type if available

This should be treated as a derived source inspection key, not as a globally canonical FiScore identity.

## 3. Violation Mapping

This section maps Sword violation or finding fields into FiScore's inspection finding model.

## Source Violation Fields

Expected or likely source fields:

- violation category or grouping
- violation code if available
- clause reference if available
- violation text
- compliance or correction notes
- severity cues if available

## Parsed Violation Payload

Recommended parsed payload fields:

- `source_inspection_key`
- `violation_order`
- `violation_category_raw`
- `violation_title_raw`
- `violation_code_raw`
- `violation_clause_raw`
- `violation_clause_category_raw`
- `violation_clause_description_raw`
- `violation_items_raw`
- `violation_problem_raw`
- `violation_correction_raw`
- `violation_comments_raw`
- `violation_description_raw`
- `correction_note_raw`
- `compliance_timeline_raw`
- `source_finding_key`

## Normalized Finding Mapping

### Map to `master_inspection_finding`

| Sword parsed field | FiScore target field | Notes |
|---|---|---|
| resolved inspection | `master_inspection_id` | From inspection match |
| county source | `source_id` | County-specific source |
| `source_finding_key` | `source_finding_key` | Use if stable, else derive |
| `violation_order` | `finding_order` | Helpful fallback identifier |
| `violation_code_raw` | `official_code` | Nullable |
| `violation_clause_raw` | `official_clause_reference` | Nullable |
| resolved clause reference | `source_clause_reference_id` | Link to source-specific clause reference when available |
| `violation_description_raw` | `official_text` | Combined source-of-truth description for FiScore workflows |
| `violation_title_raw` | `normalized_title` | Best available short title or summary line |
| derived classification | `normalized_category` | Optional normalization |
| derived severity | `severity` | Only if derived reliably |

### Notes

- `official_text` is the most important violation field and should always be preserved
- for Sword, `official_text` should be the combined violation description assembled from structured source parts
- `violation_items_raw`, `violation_problem_raw`, `violation_correction_raw`, and `violation_comments_raw` should still be preserved in parsed payloads and source version payloads
- some Sword violations may contain only `Comments` beyond the title/category line, so missing `Items`, `Problems`, or `Corrections` must be treated as valid
- clause descriptions should be stored separately as reference data and not merged into `official_text`

## Clause Reference Mapping

When the clause link popup is available, Sword should also produce a source-specific clause reference payload.

### Parsed Clause Reference Payload

Recommended fields:

- `violation_clause_raw`
- `violation_clause_category_raw`
- `violation_clause_description_raw`
- `county_name`
- `source_id`

### Map to `source_clause_reference`

| Sword parsed field | FiScore target field | Notes |
|---|---|---|
| county source | `source_id` | County-specific source |
| county jurisdiction | `jurisdiction_id` | County-level jurisdiction |
| `violation_clause_raw` | `clause_code` | The clause or rule reference |
| `violation_clause_category_raw` | `violation_category` | Preserve source category |
| `violation_clause_description_raw` | `clause_description` | Full popup description text |

### Important Rule

Clause reference data is enrichment and should be stored separately from the inspection-specific finding narrative.

For Sword specifically:

- `official_text` remains the observed violation description assembled from Items/Problems/Corrections/Comments
- `source_clause_reference` stores the reusable rule explanation shown when the clause link is opened

### Source Variance Rule

Clause code and clause description should be treated as source-scoped and county-aware.

Do not assume:

- the same clause code means the same wording across all sources
- the same clause code means the same wording across all counties within a platform

Because of that, uniqueness and linking should be source-aware rather than global.

## Source Finding Identity Recommendation

If Sword does not expose a stable finding key, derive one using a combination of:

- source inspection key
- finding order
- violation code if present
- text hash of combined violation description

This helps detect:

- new findings
- changed findings
- removed findings

## Sword Description Assembly Rule

For Sword Solutions specifically, the normalized violation description should be assembled from the structured fields in this order when present:

1. `Items`
2. `Problems`
3. `Corrections`
4. `Comments`

Assembly rules:

- include only non-empty fields
- preserve label boundaries in the parsed snapshot
- create one combined `violation_description_raw` for normalized storage and tenant workflow use
- do not fail extraction when only `Comments` exists
- keep the title/category line separate from the combined description

Example:

- title line: `Backflow Prevention Device, Wh`
- combined description:
  - `Items: Backflow prevention`
  - `Problems: Not provided`
  - `Corrections: A designated employee storage/locker area shall be provided and used.`
  - `Comments: Observed food-grade hose hooked up...`

This combined description becomes the best source text for FiScore's canonical finding record.

## 4. Raw Artifact Mapping

The first pipeline should store raw HTML for both search and detail views.

### Raw Search Artifact

Store:

- county source
- query parameters used
- returned HTML
- fetch timestamp

### Raw Detail Artifact

Store:

- source record URL or source navigation reference
- detail HTML
- fetch timestamp

### Map to `raw_artifact`

| Source artifact | FiScore target field | Notes |
|---|---|---|
| county source | `source_id` | County-specific source |
| search/detail page | `artifact_type` | Likely `html` |
| request URL or resolved path | `source_url` | Preserve exactly if possible |
| stored HTML file path | `storage_path` | Object storage or equivalent |
| fetch hash | `content_hash` | Supports change detection |

## 5. Parsed Snapshot Mapping

Parsed snapshots should be stored for:

- restaurant-level extraction
- inspection-level extraction
- violation-level extraction

### Map to `parse_result`

| Parsed entity | `record_type` |
|---|---|
| restaurant parsed payload | `restaurant` |
| inspection parsed payload | `inspection` |
| violation parsed payload | `finding` |

Suggested payload content:

- raw extracted values
- normalized candidate values
- parser warnings
- source lineage

## 6. Source Version Mapping

The Sword pipeline should create source versions whenever a monitored entity changes materially.

### Inspection Change Triggers

- score changes
- grade changes
- status/result changes
- detail summary changes

### Finding Change Triggers

- new finding appears
- finding removed
- violation text changes
- code or clause changes

### Map to `source_version`

| Change type | Entity type |
|---|---|
| inspection header update | `inspection` |
| violation change | `finding` |

Recommended stored payload:

- parsed snapshot at time of versioning
- change summary
- content hash

## 7. Tenant Projection Mapping

Only linked restaurants should be projected into tenant-facing Firestore data.

## Public Inspection Projection

### Map to Firestore

`tenants/{tenantId}/restaurants/{restaurantId}/publicInspections/{publicInspectionId}`

| Master data field | Firestore field |
|---|---|
| `master_inspection_id` | `masterInspectionId` |
| `source_id` | `sourceId` |
| county/jurisdiction name | `jurisdictionName` |
| inspection date | `inspectionDate` |
| inspection type | `inspectionType` |
| score | `score` |
| grade | `grade` |
| official status | `officialStatus` |
| source version | `sourceVersionId` |

## Public Finding Projection

### Map to Firestore

`tenants/{tenantId}/restaurants/{restaurantId}/publicInspections/{publicInspectionId}/findings/{findingId}`

| Master data field | Firestore field |
|---|---|
| `master_inspection_finding_id` | `masterInspectionFindingId` |
| `official_code` | `officialCode` |
| `official_clause_reference` | `officialClauseReference` |
| `official_text` | `officialText` |
| `normalized_title` | `normalizedTitle` |
| `normalized_category` | `normalizedCategory` |
| `severity` | `severity` |
| `source_version_id` | `sourceVersionId` |

## Auto-Created Tenant Violation Mapping

Per your current workflow rules:

- only findings from the latest public inspection should auto-create tenant violations

### Map from public finding to tenant violation

| Public/master field | Tenant violation field |
|---|---|
| latest inspection linkage | `sourceInspectionId` |
| `masterInspectionFindingId` | `sourceFindingId` |
| `official_text` | `summaryText` or `displayText` |
| `official_clause_reference` | `clauseReference` |
| county source classification | `sourceType = health_department_inspection` |
| normalized title if available | `title` |

### Tenant Violation Display Recommendation

For Sword-based public findings:

- use the title/category line as the short violation title
- use the combined description from `official_text` as the main violation description
- optionally expose clause description as a supporting reference panel or "Learn more" detail later

This gives the tenant app both:

- a concise title for lists
- a detailed narrative for review and remediation

## 8. Field Reliability Priorities

The first parser should prioritize correctness in this order:

### Highest Priority

- county
- license number
- restaurant name
- address
- inspection date
- violation text

### High Priority

- score
- grade
- inspection type
- violation code
- clause reference

### Medium Priority

- correction/compliance notes
- violation category labels
- display-only source embellishments

## 9. Nullability Guidance

The Sword source may not provide all fields consistently for every county or every inspection.

Fields that should be treated as nullable:

- zip code
- inspection type
- score
- grade
- violation code
- clause reference
- correction note

Fields that should usually be required for useful ingestion:

- county
- restaurant name
- address or enough location data to identify the establishment
- inspection date
- violation text for finding records

## 10. County-Specific Variance Handling

Even though Sword Solutions provides a shared platform, county-level differences may still appear in:

- field labels
- inspection detail formatting
- violation grouping
- presence or absence of score or grade

Recommended approach:

- keep one shared Sword mapping model
- allow county-specific parser overrides when needed
- do not fork the normalized schema by county

## 11. Recommended Derived Fields

The parser or normalization layer should derive these fields where helpful:

- `restaurant_name_normalized`
- `address_normalized`
- `unit_normalized`
- `location_fingerprint_candidate`
- `source_restaurant_key`
- `source_inspection_key`
- `source_finding_key`
- text hash for violation text comparison

These derived fields improve:

- matching
- deduplication
- version tracking
- tenant publishing stability

## 12. Open Questions for Parser Validation

These questions should be confirmed during implementation and QA:

- does Sword expose a stable inspection detail identifier
- does Sword expose a stable finding identifier
- are score and grade always present
- are violation codes and clauses always structured or sometimes only embedded in free text
- do all counties expose the same detail layout

These do not block the mapping model, but they should be resolved during parser QA.

## Summary

The Sword Solutions field mapping should focus on reliably extracting restaurant header data, inspection header data, and violation text into FiScore's raw, parsed, normalized, and tenant projection layers. The strongest source identity should be `county + license_number`, while FiScore's broader canonical identity should continue to rely on `masterRestaurantId` and `locationFingerprint`.
