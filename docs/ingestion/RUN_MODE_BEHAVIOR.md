# FiScore Ingestion Run Mode Behavior

## Purpose

This document defines the intended FiScore-wide behavior for:

- `backfill`
- `incremental`
- `reconciliation`
- targeted restaurant refresh

The goal is to make run behavior consistent across ingestions so operators and product features can rely on one mental model instead of source-specific surprises.

This document should be treated as the desired platform contract for Georgia, Sword, NYC, and future ingestions.

## Why This Matters

Without a shared run-mode contract, different sources end up behaving differently in ways that are hard to explain operationally.

Examples of confusion:

- whether date windows limit discovery only or actual inspection processing
- whether an already-known inspection is skipped or refreshed
- whether a broader run repairs old findings or only inserts new records
- whether a restaurant refresh is shallow or full-history

FiScore should make these behaviors explicit and consistent.

## Recommended Standard

FiScore should use the following pattern:

| Run Type | Default Window | Existing Inspections | Existing Findings | Scope |
|---|---|---|---|---|
| `backfill` | source-defined baseline window | skip | skip | broad |
| `incremental` | 30 days | skip | skip | broad |
| `reconciliation` | 180 days | update / upsert | update / upsert | broad |
| targeted restaurant refresh | full history | update / upsert | update / upsert | one restaurant |

This should become the common run-mode contract across ingestions.

## Detailed Behavior

### 1. Backfill

Backfill is for baseline coverage.

Recommended behavior:

- retrieve records within the source's configured baseline window
- insert inspections and findings not already present
- skip inspections already known to FiScore
- skip findings under skipped inspections

Backfill should be optimized for:

- establishing baseline coverage
- keeping broad historical loads reasonably efficient
- avoiding unnecessary churn on already-known records

Backfill is not the preferred mechanism for refreshing old records repeatedly.

### 2. Incremental

Incremental is for regular freshness.

Recommended behavior:

- use a standard **30-day** lookback window
- discover inspections in that window
- insert new inspections and findings
- skip inspections already known to FiScore

Incremental should be cheap and operationally predictable.

Its purpose is:

- pick up newly posted inspections
- pick up newly discovered restaurants
- avoid repeatedly reprocessing old known records

### 3. Reconciliation

Reconciliation is for repair and correction.

Recommended behavior:

- use a standard **180-day** lookback window
- discover inspections in that window
- insert missing inspections
- update existing inspections already present
- insert missing findings
- update existing findings already present

Reconciliation exists because broad backfill and incremental runs should be optimized for speed and coverage, not full mutation of already-known historical records.

Reconciliation should be the normal answer when FiScore needs to:

- catch late-posted inspections
- pick up corrected scores or grades
- pick up changed reports
- pick up findings that appear later or were corrected

### 4. Targeted Restaurant Refresh

Targeted restaurant refresh is for deep repair of one restaurant.

Recommended behavior:

- fetch the restaurant's full available inspection history
- update or upsert all inspections for that restaurant
- update or upsert all findings for those inspections
- refresh report metadata and artifacts where available

This should be available across all ingestions as a common product capability, not just for Sword.

## Date Window Rule

FiScore should make one rule explicit:

- broad run windows should limit **both discovery and processing**

That means:

- if an inspection is outside the current incremental or reconciliation window, it should not be processed during that broad run
- the only normal exception is targeted restaurant refresh, which intentionally performs a full-history pass

This rule keeps broad runs understandable and bounded.

## Existing Record Rule

FiScore should make another rule explicit:

- `backfill` and `incremental` are **skip-existing**
- `reconciliation` and targeted refresh are **update-existing**

This means the meaning of "process" should be:

### Skip-existing

- do not normalize the inspection again
- do not refresh findings under that inspection
- do not refresh report metadata under that inspection

### Update-existing

- normalize inspection again
- update existing inspection fields
- insert or update findings under that inspection
- refresh report metadata where supported

## No Normal Ops Skip Flag

The standard run-mode contract should remove the need for a source-specific operator flag such as:

- `skip_existing_inspections`

Instead:

- skip/update behavior should be defined by run mode
- not by per-source toggles during ordinary operations

That makes operator expectations much cleaner.

## Internal Override Guidance

Even though FiScore should remove skip/update ambiguity from normal operations, it is still reasonable to preserve an internal-only override path for diagnostics or emergency correction.

Examples:

- `force_update_existing`
- `force_skip_existing = false`

This should be:

- internal-only
- hidden from normal product and routine ops usage
- used sparingly

## Source-by-Source Expected Shape Under This Standard

### Georgia DPH

Recommended broad behavior:

- `backfill`: county search window + process only inspections in window + skip existing inspections
- `incremental`: 30-day county search window + process only inspections in window + skip existing inspections
- `reconciliation`: 180-day county search window + process only inspections in window + update/upsert inspections and findings
- targeted refresh: full facility history + update/upsert

### Sword

Recommended broad behavior:

- `backfill`: source-defined broad search + process only broad-run inspection rows + skip existing inspections
- `incremental`: 30-day broad search + process discovered inspections + skip existing inspections
- `reconciliation`: 180-day broad search + process discovered inspections + update/upsert inspections and findings
- targeted refresh: full restaurant history using `get_locations -> get_inspections -> get_details` + update/upsert

### NYC DOHMH

Recommended broad behavior:

- `backfill`: dataset snapshot or bounded baseline window + skip existing inspections
- `incremental`: 30-day dataset window + skip existing inspections
- `reconciliation`: 180-day dataset window + update/upsert inspections and findings
- targeted refresh: full restaurant refresh by `CAMIS` or equivalent restaurant key + update/upsert

## Why This Pattern Is Good

This pattern gives FiScore four clear operational jobs:

### Backfill

- establish baseline
- do not spend unnecessary work on already-known inspections

### Incremental

- pick up new records regularly
- stay fast and predictable

### Reconciliation

- repair drift
- absorb source corrections
- refresh findings and metadata

### Targeted Refresh

- repair one restaurant deeply
- support product-side and ops-side exception handling

This makes the ingestion platform easier to reason about, easier to explain, and easier to support in the UI.

## Product and UI Recommendation

FiScore should expose targeted restaurant refresh as a first-class action across ingestions.

Recommended UI label:

- `Refresh Restaurant`

Recommended support text:

- `Reload this restaurant's full inspection history and findings from the source.`

Recommended confirmation copy:

- `This refresh reloads the restaurant's full available inspection history from the source and updates FiScore records for that restaurant.`

This should be consistent across:

- Sword
- Georgia
- NYC
- future ingestions

## Implementation Guidance

To align the codebase with this standard:

### Shared changes

1. standardize `incremental_default = 30`
2. standardize `reconciliation_default = 180`
3. remove normal operator-facing skip/update flags
4. add or preserve a shared targeted refresh contract

### Source-specific changes

#### Georgia

- keep date-window filtering at the inspection-processing layer
- add skip-existing behavior for `backfill` and `incremental`
- use update/upsert behavior for `reconciliation`
- add targeted facility refresh path

#### Sword

- change incremental default from `45` to `30`
- keep broad run behavior focused on discovered inspection rows
- add skip-existing behavior for `backfill` and `incremental`
- keep update/upsert behavior for `reconciliation`
- preserve targeted full-history refresh behavior

#### NYC

- keep dataset date windowing
- remove the public meaning of `skip_existing_inspections`
- make skip/update behavior depend on run mode
- add targeted restaurant refresh behavior by restaurant key

## Final Recommendation

FiScore should adopt this run-mode pattern as the standard ingestion contract:

- `backfill` = broad baseline, skip existing
- `incremental` = 30-day refresh, skip existing
- `reconciliation` = 180-day repair window, update/upsert existing
- targeted restaurant refresh = full-history restaurant repair, update/upsert existing

This is a clean and durable model for both ingestion operations and product-facing refresh behavior.
