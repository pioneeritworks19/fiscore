# FiScore Sword Solutions Parser Rules

## Purpose

This document defines the parser rules and extraction behavior for the Sword Solutions inspections platform.

The goal is to make the first Sword ingestion pipeline implementation-ready by describing:

- how the source should be navigated
- what parser stages should exist
- how source records should be identified
- how fields should be extracted
- how county-specific differences should be handled
- how changes should be detected over time

This document complements:

- `SWORD_SOLUTIONS_INGESTION_PLAN.md`
- `SWORD_SOLUTIONS_FIELD_MAPPING.md`
- `MASTER_DATA_SCHEMA.md`
- `INGESTION_WORKFLOWS.md`

## Parser Design Principles

### 1. Separate Fetch from Parse

The parser should not depend on live site availability during every debugging session. Raw HTML should be fetched and stored first, then parsed from stored artifacts.

### 2. Preserve Source Semantics

The parser should preserve the official Sword display values before normalizing them.

### 3. Prefer Stable Identifiers Over Display-Only Values

When a reliable identifier exists, use it. When it does not, derive one in a consistent and explainable way.

### 4. Be County-Aware but Platform-Shared

Sword Solutions should be treated as one platform with one shared parser family, but the parser should allow county-specific overrides if the page structure or field presentation differs.

### 5. Detect Change Safely

The parser must support change detection for inspections and findings without depending on brittle assumptions.

## Source Characteristics

The public Sword Solutions inspections page currently shows:

- county selection
- restaurant name search
- address search
- city search
- license number search
- date range filters
- partial-search option

The site describes the published records as food service inspection summaries for participating governmental agencies.

## Parser Workflow Overview

The Sword parser family should be implemented in stages:

1. source request builder
2. search result parser
3. detail page parser
4. normalization mapper
5. key derivation and identity logic
6. change detector

## 1. Source Request Builder Rules

Each Sword county should be treated as a separate source, but use the same request builder pattern.

### Required Source Inputs

- county identifier or county selection value
- optional restaurant name
- optional address
- optional city
- optional license number
- optional date range

### Backfill Request Strategy

Because the plan calls for full historical backfill, the parser should support:

- county-wide discovery patterns
- date-ranged queries if required by the platform
- repeated paginated fetching if search results are split across pages

### Request Builder Rules

- preserve the exact county parameter used
- preserve query parameters used for each search request
- record whether the request was full-county, targeted restaurant, or targeted license rerun
- persist the exact request metadata with the raw artifact

## 2. Search Result Parsing Rules

The first parsing responsibility is to extract restaurant-level and inspection-summary-level candidates from the search results.

### Search Result Parser Must Extract

- county context
- restaurant name
- license number when present
- address
- city
- state when displayed or inferred
- summary inspection fields shown in the result set
- detail-page navigation target

### Search Result Parsing Rules

- trim and preserve raw display text before normalization
- extract visible labels exactly as shown
- preserve source ordering for traceability
- capture row position when useful

### Search Result Parser Output

Each parsed row should produce a candidate record with:

- parsed restaurant payload
- parsed inspection summary payload if present
- detail navigation reference
- source metadata

## 3. Detail Page Parsing Rules

The detail page parser should extract the full inspection and violation details used for canonical storage and tenant workflows.

### Detail Parser Must Extract

- restaurant header fields
- inspection header fields
- violations
- codes, clauses, and categories when present
- correction or compliance notes when present

### Detail Parser Rules

- preserve the official text exactly as displayed
- do not collapse multiple violations into one text block unless the source truly presents them that way
- preserve field grouping when the site distinguishes inspection header from violation content
- capture raw text blocks for recovery when structured extraction is imperfect

### Multi-Inspection Handling

If a detail page contains more than one inspection:

- parse each inspection separately
- maintain ordering from the source
- attach all violations to the correct inspection instance

## 4. Restaurant Extraction Rules

The parser should extract restaurant header fields from the most authoritative location available on the page.

### Restaurant Field Priority

If the same field appears on both search and detail pages:

- prefer detail page value as the authoritative value for canonical storage
- retain the search page value in parsed snapshots for lineage and debugging

### Restaurant Name Rules

- preserve `restaurant_name_raw` exactly
- derive `restaurant_name_normalized` separately
- do not strip meaningful business wording from the preserved display name

### Address Rules

- preserve full raw address text
- derive normalized address fields separately
- parse unit/suite if reliably detectable
- do not over-normalize when the parser is uncertain

### License Number Rules

- preserve exactly as displayed
- trim whitespace
- avoid numeric coercion if leading zeros may matter
- treat county + license number as the strongest Sword source identifier

## 5. Inspection Extraction Rules

The parser should extract inspection header fields in a way that supports both display and history tracking.

### Required Inspection Extraction Targets

- inspection date
- inspection type if shown
- score if shown
- grade if shown
- status or result if shown
- any report-level summary text

### Inspection Date Rules

- preserve raw date string
- parse to normalized date field separately
- reject silently only if a date cannot be parsed at all
- record parser warning when date format is unexpected

### Score and Grade Rules

- preserve raw values
- normalize score to numeric only when safe
- preserve grade as text
- do not invent grade if only score exists
- do not derive score if only grade exists unless product rules later require it

### Inspection Key Derivation Rules

If the source exposes a stable inspection identifier, use it.

If not, derive:

- county
- license number
- inspection date
- inspection type if available

Derived key concept:

`source_inspection_key = hash(county + license_number + inspection_date + inspection_type)`

## 6. Violation Extraction Rules

Violation extraction is one of the highest-value parser responsibilities.

### Required Violation Extraction Targets

- violation order or sequence if visible
- violation title or summary line
- violation code if visible
- violation clause if visible
- clause category from popup when available
- clause description from popup when available
- items field when present
- problems field when present
- corrections field when present
- comments field when present
- combined violation description
- correction or compliance note if present
- category label if present

### Violation Text Rules

- preserve each structured source component exactly as displayed
- keep line breaks or sentence structure if they carry meaning
- avoid over-cleaning punctuation
- store normalized copies separately if needed for hashing or comparison
- assemble one combined violation description from the structured source parts for canonical downstream storage

### Code and Clause Rules

- preserve as text
- allow null when absent
- do not attempt to infer clause if it is only implied in prose

### Clause Popup Enrichment Rules

When the clause link can be opened and parsed, capture:

- clause code
- clause category
- clause description

Important rules:

- treat clause popup capture as enrichment, not as a hard dependency for ingestion success
- keep clause description separate from the observed violation description
- store clause reference content as source-specific, county-aware reference data
- do not assume clause wording is globally reusable across all sources

### Sword Structured Violation Rules

Sword violation blocks appear to support a structure where the title/category line is followed by zero or more of:

- `Items`
- `Problems`
- `Corrections`
- `Comments`

Parser rules:

- extract the title/category line separately from the descriptive fields
- extract each labeled field separately when present
- treat missing `Items`, `Problems`, or `Corrections` as valid
- treat comment-only violations as valid structured findings
- assemble a combined violation description from the non-empty labeled fields

### Combined Description Assembly

For Sword-specific parsing, build the combined violation description in this order:

1. `Items`
2. `Problems`
3. `Corrections`
4. `Comments`

Assembly rules:

- include only non-empty fields
- preserve the original wording of each field
- keep field boundaries in parsed snapshots
- allow the combined description to consist only of comments when that is all the source provides

### Separation Rule

For Sword:

- the combined violation description represents what was observed or documented in this inspection
- the clause popup description represents the underlying rule reference

These must remain separate in parsed outputs and normalized storage.

### Violation Grouping Rules

If the source groups violations under headings:

- preserve heading/category separately if possible
- do not append the category into the official violation text unless necessary

### Finding Key Derivation Rules

If no stable source finding identifier exists, derive:

- source inspection key
- finding order
- violation code if present
- text hash of normalized combined violation description

Derived key concept:

`source_finding_key = hash(source_inspection_key + finding_order + violation_code + violation_description_hash)`

## 6A. Clause Reference Extraction Rules

If the clause link opens a popup or detail panel, the parser should attempt to extract a clause reference payload.

### Clause Reference Extraction Targets

- `clause_code`
- `violation_category`
- `clause_description`
- county source context

### Clause Extraction Rules

- preserve clause code exactly as shown
- preserve category exactly as shown
- preserve description text exactly as shown
- normalize only for comparison and hashing in separate fields
- associate the clause reference with the current county source

### Clause Reference Key Recommendation

If no stable source-side identifier exists for the clause reference, derive one from:

- county source id
- clause code
- content hash of clause description

### Clause Extraction Failure Rules

If clause popup extraction fails:

- do not fail the entire finding or inspection parse
- store the clause code already visible on the main inspection page if available
- log a parser warning for clause enrichment failure

## 7. Normalization Rules

The parser layer should stop short of business-heavy normalization. It should produce parsed values plus safe derived candidates.

### Safe Parser-Level Normalization

- lowercase for normalized comparison fields
- trim surrounding whitespace
- collapse repeated internal spaces
- standardize obvious address abbreviations only in normalized fields
- extract safe date values

### Avoid at Parser Layer

- aggressive category classification
- overconfident severity inference
- business-specific score reinterpretation
- cross-source record merges

These belong in downstream normalization or business logic layers.

## 8. County Override Rules

Although the Sword platform is shared, counties may differ in detail layout or field availability.

### Recommended Parser Structure

- one base Sword parser family
- county override configuration layer

### County Override Candidates

- field label variants
- score or grade presence
- violation block structure
- date formatting quirks
- county-specific missing fields

### Rule

Do not fork the full parser per county unless absolutely necessary. Prefer:

- shared parser
- small county-specific selectors or extraction overrides

## 9. Raw Artifact Rules

Every fetched page used by parsing should be stored as a raw artifact.

### Raw Artifact Types for Sword

- search result HTML
- inspection detail HTML

### Raw Artifact Metadata to Preserve

- county source id
- fetch timestamp
- request parameters
- platform name
- content hash
- fetch status

### Reason

This supports:

- re-parsing after parser improvements
- debugging county-specific issues
- comparing changed records later

## 10. Parsed Snapshot Rules

The parser should create parsed snapshots for:

- restaurant candidate extraction
- inspection extraction
- finding extraction

### Parsed Snapshot Should Include

- raw extracted values
- normalized candidate fields
- parser warnings
- parser version
- source lineage
- derived source keys

### Warning Examples

- missing license number
- unparseable date
- missing score
- suspiciously empty violation text
- multiple inspections with unclear boundaries

## 11. Change Detection Rules

The Sword parser family must support repeat ingestion and change detection.

### Inspection Change Detection

Treat these as possible material inspection changes:

- inspection score changed
- inspection grade changed
- inspection type changed
- inspection status changed

### Finding Change Detection

Treat these as possible material finding changes:

- new finding appeared
- existing finding disappeared
- combined violation description changed materially
- code or clause changed

### Clause Reference Change Detection

Treat these as clause reference changes:

- clause description changed
- clause category changed

These should create or update source-specific clause reference versions, but should not automatically be treated as the same thing as an inspection finding change unless the finding content itself also changed.

### Hashing Recommendation

Maintain hashes for:

- normalized inspection header content
- normalized finding content

This supports efficient comparison while preserving full source versions.

## 12. Error Handling Rules

The parser should distinguish between hard failures and partial extraction.

### Hard Failure Examples

- page could not be fetched
- expected page structure completely missing
- no parseable content at all

### Partial Extraction Examples

- restaurant parsed but score missing
- inspection parsed but one violation block unclear
- violation text extracted but code missing

### Rule

Partial extraction should not always fail the entire county run. Instead:

- store parsed output with warnings
- mark records for QA or review when needed

## 13. QA Rules

The parser should support the manual QA process defined in the ingestion plan.

### QA Sample Workflow

For each county:

1. sample 20 restaurants
2. compare restaurant name, license number, address, inspection date, and violation text against live pages
3. log mismatches
4. classify parser issue as:
   - extraction bug
   - county override needed
   - source inconsistency

### Acceptance Goal

County parser quality should be good enough that:

- restaurant identity is reliable
- inspection history is trustworthy
- violation text is preserved accurately

## 14. Rerun Rules

The parser pipeline should support reruns at multiple scopes.

### Required Rerun Scopes

- full county rerun
- targeted restaurant rerun
- targeted license rerun
- full platform rerun eventually

### Rerun Requirement

Reruns should reuse the same parser and normalization rules while preserving run history and source version history.

## 15. Recommended Parser Output Contract

Each parsed restaurant/inspection bundle should produce:

- source metadata
- restaurant parsed payload
- inspection parsed payload
- zero or more finding parsed payloads
- derived source keys
- parser warnings

This contract should be stable enough for:

- normalization
- change detection
- QA review
- tenant publication

## 16. Open Validation Questions

These should be confirmed during implementation:

- whether the search results expose all inspections or only filtered summaries
- whether detail pages have stable URLs or form-based postbacks
- whether a stable Sword internal identifier exists in HTML or links
- whether all counties use identical detail layouts
- whether some counties omit license number, score, or grade more often than others

These do not block parser design, but they should be explicitly checked early.

## Summary

The Sword Solutions parser should use a shared platform parser with county-aware overrides, preserve official restaurant, inspection, and violation content, derive stable source keys when the platform does not expose them directly, and support version-aware repeat ingestion. The parser should be built for operational durability, not just one-time extraction, with raw artifact storage, parsed snapshots, warning handling, and rerun support from the beginning.
