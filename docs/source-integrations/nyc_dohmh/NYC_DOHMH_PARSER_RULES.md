# FiScore NYC DOHMH Parser Rules

## Purpose

This document defines parser rules for the first NYC DOHMH dataset adapter.

## Parser Family

Recommended parser id:

- `nyc-dohmh`

The parser family should support:

- metadata fetch
- columns fetch
- row page fetch
- grouped inspection parsing
- repeat comparison runs

## Primary Surface

Primary surface:

- dataset rows from `43nn-pn8j`

Secondary audit surface:

- ABCEats public website

The website should not be a hard dependency for routine ingestion success.

## Core Parsing Model

Each fetched dataset row should first be treated as a row candidate.

Rows should then be grouped into inspections before normalization.

## Grouping Rules

Recommended grouping fields:

- `camis`
- `inspection_date`
- `inspection_type`
- `action`
- `score`
- `grade`

If implementation shows that one of these fields is too unstable within a single inspection event, refine the grouping set while keeping behavior deterministic.

## Row Handling Rules

### Preserve Raw Values

Preserve official raw values for:

- restaurant fields
- inspection fields
- violation fields
- source metadata fields

### Blank Violation Rows

If violation fields are blank but the row otherwise represents a real inspection:

- create the grouped inspection payload
- allow zero findings
- emit a warning only if the row is internally inconsistent

### `1900-01-01`

Rows with `1900-01-01` should be treated as special source-state rows.

The parser should:

- preserve the raw date
- mark the payload as not-yet-inspected when supported by the row
- avoid presenting it as a normal completed inspection without later normalization rules

## Parsed Payload Shape

Recommended grouped payload sections:

- `source_metadata`
- `restaurant`
- `inspection`
- `findings`

## Warning Rules

Create warnings for cases such as:

- missing `CAMIS`
- missing core grouping fields
- duplicate rows within the same page
- conflicting repeated inspection values within one group
- suspicious partial finding rows
- unparseable dates or scores

Warnings should not fail the run unless the row cannot be safely assigned to a restaurant or grouped inspection.

## Summary

The NYC parser should be dataset-first, group row-level records into deterministic inspection payloads, derive source keys from stable official fields, and preserve raw values for traceability across backfill, incremental, and reconciliation runs.
