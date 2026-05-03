# FiScore NYC DOHMH Ingestion Plan

## Purpose

This document defines the first ingestion plan for the NYC DOHMH restaurant inspection source.

The primary source is the NYC Open Data dataset:

- dataset: `DOHMH New York City Restaurant Inspection Results`
- dataset id: `43nn-pn8j`
- metadata API: `https://data.cityofnewyork.us/api/views/43nn-pn8j`
- columns API: `https://data.cityofnewyork.us/api/views/43nn-pn8j/columns.json`
- row API: `https://data.cityofnewyork.us/resource/43nn-pn8j.json`

The public ABCEats site should be treated as a secondary audit surface:

- `https://a816-health.nyc.gov/ABCEatsRestaurants/#!/Search`

## Platform and Source Model

### Platform

- `platform_slug = nyc-dohmh`
- `platform_name = NYC DOHMH`

### Source

Start with one citywide source:

- `source_slug = nyc_dohmh_restaurant_inspections`
- `source_name = NYC DOHMH Restaurant Inspection Results`
- `jurisdiction_name = New York City, NY`
- `source_type = api_dataset`

NYC boroughs should be runtime partitions only, not separate FiScore sources.

## Source Characteristics

The current dataset metadata states:

- establishments are uniquely identified by `CAMIS`
- inspection rows may repeat because each violation is stored as a separate row
- active-status restaurants are included
- `1900-01-01` inspection dates indicate restaurants that have not yet received an inspection
- the public grading site and dataset come from the same underlying source

This means FiScore should treat:

- `CAMIS` as the strongest source restaurant identifier
- grouped inspection rows as the true inspection-level unit
- the dataset as a rolling operational source, not a guaranteed all-time archive

## Fetch Strategy

NYC should be dataset-first.

### Before Every Run

Fetch and store:

- metadata JSON
- columns JSON
- request manifest for the row query

This supports:

- freshness tracking
- schema awareness
- repeatability for ops

### Backfill

Recommended baseline approach:

- fetch the full current dataset through paginated API reads or a bulk snapshot
- group rows into inspections before normalization
- create the first baseline of restaurants, inspections, findings, and source versions

Important limitation:

This is a baseline backfill of the currently available dataset, not a guaranteed lifetime history load.

### Incremental

Recommended default:

- daily or weekly incremental refresh
- overlap the recent window by `30 days`
- compare grouped payloads against existing stored records

Why:

- protects against delayed publication
- protects against scheduler gaps
- keeps fetch volume manageable

### Reconciliation

Recommended default:

- monthly reconciliation
- rolling `180 day` lookback

Why:

- catches late-posted inspections
- catches corrected source records
- validates that narrow incrementals are not missing changes

### Periodic Full Snapshot

Support a wider citywide refresh periodically:

- recommended cadence: quarterly

This helps catch edge cases tied to active-status scope and older corrections.

## Identity Rules

### Source Restaurant Identity

Strongest identifier:

- `CAMIS`

Recommended source restaurant key:

- `nyc-camis:{camis}`

### Source Inspection Identity

Because the dataset is row-oriented, derive one grouped inspection key from repeated inspection-level fields.

Recommended derived inputs:

- `CAMIS`
- `inspection_date`
- `inspection_type`
- `action`
- `score`

Recommended key:

- `hash(camis + inspection_date + inspection_type + action + score)`

### Source Finding Identity

Recommended derived inputs:

- `source_inspection_key`
- `violation_code`
- `violation_description`
- `critical_flag`
- `finding_order`

Recommended key:

- `hash(source_inspection_key + violation_code + violation_description + critical_flag + finding_order)`

## Website Role

The ABCEats site should not be the primary ingestion system of record.

Use it for:

- targeted audit
- suspicious-record validation
- freshness investigation when dataset updates appear delayed

## Summary

NYC should be implemented as a dataset-first source with one citywide source record, borough-aware runtime partitioning, `CAMIS`-based restaurant identity, grouped inspection parsing, and overlap-based incremental refreshes.
