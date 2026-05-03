# FiScore NYC DOHMH Field Mapping

## Purpose

This document maps the NYC DOHMH restaurant inspection dataset into FiScore's parsed and normalized model.

Use alongside:

- `NYC_DOHMH_INGESTION_PLAN.md`
- `MASTER_DATA_SCHEMA.md`
- `MASTER_DATA_ARCHITECTURE.md`
- `RESTAURANT_MATCHING.md`

## Source Shape

The dataset is row-oriented.

That means:

- restaurant fields repeat across many rows
- inspection fields repeat across many rows
- violation fields appear once per violation row
- inspections with no violations may still appear as one row

The parser should therefore group rows into inspections before normalization.

## Restaurant Mapping

### Primary Source Fields

- `camis`
- `dba`
- `boro`
- `building`
- `street`
- `zipcode`
- `phone`
- `cuisine_description`

### Parsed Payload

- `camis_raw`
- `dba_raw`
- `boro_raw`
- `building_raw`
- `street_raw`
- `zipcode_raw`
- `phone_raw`
- `cuisine_description_raw`
- `address_line1_raw`
- `source_restaurant_key`

### Normalized Mapping

| NYC field | FiScore target | Notes |
|---|---|---|
| `dba_raw` | `display_name` | Preserve official name |
| normalized `dba_raw` | `normalized_name` | Matching/search |
| `address_line1_raw` | `address_line1` | Derived from building + street |
| normalized address | `normalized_address1` | Canonical location matching |
| `boro_raw` | `city` | Preserve source borough text for now |
| constant `NY` | `state_code` | Source-wide constant |
| `zipcode_raw` | `zip_code` | Nullable |
| derived hash | `location_fingerprint` | Canonical match anchor |

### Identifier Mapping

| NYC field | FiScore target | Notes |
|---|---|---|
| `camis_raw` | `identifier_value` | Strongest source identifier |
| constant | `identifier_type = camis` | NYC-specific identifier type |
| `source_restaurant_key` | `source_restaurant_key` | `nyc-camis:{camis}` |

## Inspection Mapping

### Primary Source Fields

- `inspection_date`
- `inspection_type`
- `action`
- `score`
- `grade`
- `grade_date`
- `record_date`

### Parsed Payload

- `inspection_date_raw`
- `inspection_type_raw`
- `action_raw`
- `score_raw`
- `grade_raw`
- `grade_date_raw`
- `record_date_raw`
- `source_inspection_key`

### Normalized Mapping

| NYC field | FiScore target | Notes |
|---|---|---|
| `source_inspection_key` | `source_inspection_key` | Derived grouped key |
| resolved restaurant | `master_restaurant_id` | From source link/match flow |
| `inspection_date_raw` | `inspection_date` | Parse to date |
| `inspection_type_raw` | `inspection_type` | Preserve official text |
| `score_raw` | `score` | Numeric when parseable |
| `grade_raw` | `grade` | Preserve official grade |
| `action_raw` | `official_status` | Preserve official action wording |
| `record_date_raw` | source metadata | Useful for comparison context |

### Special Handling

If `inspection_date_raw` is `1900-01-01`:

- preserve the restaurant as present in source
- preserve the raw value
- do not assume this is a normal completed inspection event

## Finding Mapping

### Primary Source Fields

- `violation_code`
- `violation_description`
- `critical_flag`

### Parsed Payload

- `violation_code_raw`
- `violation_description_raw`
- `critical_flag_raw`
- `finding_order`
- `source_finding_key`

### Normalized Mapping

| NYC field | FiScore target | Notes |
|---|---|---|
| `source_finding_key` | `source_finding_key` | Derived key |
| `violation_code_raw` | `violation_code` | Preserve official code |
| `violation_description_raw` | `finding_text` | Preserve official wording |
| `critical_flag_raw` | source detail/severity metadata | Preserve raw flag |
| `finding_order` | ordering metadata | Preserve row order when stable |

## Summary

NYC should map from a row-oriented open dataset into grouped inspection payloads with `CAMIS` as the strongest restaurant identifier and derived grouped-inspection and finding keys based on official source fields.
