# FiScore Master Restaurant List Strategy

## Purpose

This document defines how FiScore should build and maintain a master list of restaurants in the United States without purchasing a commercial restaurant dataset.

The goal is not to pretend that one perfect free national restaurant database already exists. Instead, the goal is to create a practical, scalable strategy for assembling a high-quality FiScore master restaurant list using free and public data sources, then improving that list over time through matching, normalization, and official jurisdiction-specific inspection data.

## Core Recommendation

FiScore should build its own master restaurant list using a layered strategy:

1. use a free national seed dataset for broad coverage
2. enrich and validate that seed with official health inspection and food establishment data where available
3. create FiScore-owned canonical restaurant identities and match logic
4. improve data quality over time through operations, review, and source expansion

This is the most realistic way to get broad U.S. restaurant coverage without paying for commercial business listing data.

## Reality Check

There is no single free, complete, authoritative, restaurant-by-restaurant master list for the entire United States that cleanly solves this problem.

Free data sources usually have one of these tradeoffs:

- broad coverage but inconsistent business quality
- official quality but fragmented jurisdiction coverage
- useful statistics but no individual establishment records

Because of that, FiScore should treat the master restaurant list as a product asset it builds and maintains, not as a one-time download.

## Recommended Source Strategy

FiScore should use a three-layer source model.

## Layer 1: National Seed Coverage

### Recommended Source

- `OpenStreetMap`

### Why

OpenStreetMap is the best practical free source for broad restaurant discovery coverage across the United States.

It is useful for:

- initial restaurant search coverage
- basic name and location data
- giving tenants something to search by zip code and name even before every official source is integrated

### Limitations

- not authoritative for compliance workflows
- inconsistent completeness by area
- may be outdated in some places
- usually does not provide permit or health department identifiers

### Recommended Use

Use OpenStreetMap as:

- a seed source
- a search and candidate-generation source
- a fallback discovery layer

Do not use it as the sole long-term source of truth for compliance-grade restaurant identity.

## Layer 2: Official Inspection and Food Establishment Data

### Recommended Source Type

- state health department datasets
- county health department datasets
- city health department datasets
- open data portals with food establishment and inspection data

### Why

These sources are much closer to FiScore's actual product need because they may include:

- official facility identifiers
- permit or license numbers
- inspection records
- public violations
- report PDFs
- agency-specific metadata

### Recommended Use

Use these official sources as the authoritative compliance layer where available.

They should:

- enrich master restaurant records
- improve matching quality
- provide the source data for public inspections and public findings
- override weaker identity assumptions from non-authoritative seed data when appropriate

### Key Limitation

There is no single national standard source for these datasets. Coverage is fragmented by jurisdiction and format.

## Layer 3: FiScore Canonical Master Layer

FiScore should create its own canonical restaurant identity and not depend on any one external source as the permanent master key.

### Recommended Canonical Identity

- `masterRestaurantId`
- `locationFingerprint` as the primary canonical match anchor

This should be FiScore-owned and stable even when:

- a restaurant changes names
- source formatting changes
- new sources are added
- source identifiers differ between jurisdictions

## Recommended Source Priority

FiScore should prioritize source integration in this order:

### Priority 1

- statewide official public inspection or food establishment datasets

### Priority 2

- county-level official inspection datasets in high-value markets

### Priority 3

- city-level official inspection datasets where coverage justifies the added source complexity

### Priority 4

- OpenStreetMap and other broad free discovery data for gaps and fallback search support

### Priority 5

- Census-based business count datasets only for coverage estimation and planning, not for per-restaurant identity

## Why This Priority Order Works

- official sources align directly with FiScore's compliance use case
- statewide sources provide better return on implementation effort
- OSM helps with broad discovery but should not dominate official identity
- Census data helps measure coverage but does not solve the restaurant identity problem directly

## Canonical Identity Strategy

FiScore should use a layered identity model.

### Preferred Identity Signals

#### Highest Quality

- official permit number
- official license number
- agency facility id
- source listing id from the inspection authority

#### Strong Fallback

- normalized street address
- normalized suite or unit when available
- city
- state
- zip code

These fields should be combined into a deterministic `locationFingerprint` used as the primary canonical match anchor when official identifiers are unavailable.

#### Supporting Identity

- display name
- normalized name
- alternate names
- DBA variants

#### Search Identity

- display name
- zip code
- city

### Important Rule

Restaurant name plus zip code is useful for search, but it should not be the canonical identity by itself.

Restaurant name should also not be treated as the primary identity anchor. FiScore should use a location-first model anchored by `locationFingerprint`.

## Suggested Master Restaurant Fields

Each master restaurant should store:

- `masterRestaurantId`
- `locationFingerprint`
- `displayName`
- `normalizedName`
- `alternateNames`
- `addressLine1`
- `addressLine2`
- `normalizedAddress1`
- `normalizedUnit`
- `city`
- `state`
- `zip`
- `country`
- `latitude`
- `longitude`
- `status`
- `primaryJurisdictionId`
- `sourceCount`
- `lastSeenAt`

## Suggested External Identifier Fields

Each master restaurant may also have one or more linked external identifiers:

- `identifierId`
- `masterRestaurantId`
- `identifierType`
- `identifierValue`
- `jurisdictionId`
- `sourceSystemId`
- `isPrimary`
- `confidence`

## Matching Strategy

FiScore should match sources into the master list in layers.

### 1. Identifier-Based Match

Use official permit or agency identifiers when available.

This should be the preferred matching path.

### 2. Name and Address Match

When official identifiers are missing, use:

- normalized address
- normalized suite or unit when available
- city
- state
- zip

These fields should produce a deterministic `locationFingerprint` that becomes the main canonical match anchor.

### 3. User-Assisted Match for Tenant Linking

When tenants add restaurants in the app:

1. search by zip code
2. filter by restaurant name
3. select the correct master restaurant

This should remain the preferred tenant linking workflow in version 1.

### 4. Manual Review for Ambiguous Cases

If the system cannot safely determine whether records represent the same restaurant, route the case for internal review.

## Suggested Ingestion Rule by Source Type

### For OpenStreetMap

Use it to:

- seed restaurant records
- provide broad search coverage
- create possible master restaurant candidates

Do not rely on it alone for:

- final compliance-grade identity
- permit-level matching
- official violation history

### For Official Health Datasets

Use them to:

- create or update authoritative master restaurant links
- attach inspections and findings
- store jurisdiction-specific identifiers
- strengthen canonical identity confidence

### For Census Business Datasets

Use them to:

- estimate total expected restaurant counts by geography
- identify under-covered geographies
- prioritize future source integrations

Do not use them to:

- create individual restaurant master records

## Coverage Strategy

FiScore should not try to achieve perfect national coverage immediately.

### Recommended Rollout Model

#### Phase 1

Build master list coverage for states with statewide official restaurant inspection or food establishment data.

#### Phase 2

Expand into selected county-based markets.

#### Phase 3

Expand into city-based markets where product demand justifies the additional source complexity.

#### Ongoing

Use national seed data to maintain broad searchability even where official depth is not yet available.

## Data Quality Strategy

The master restaurant list should be treated as a maintained asset.

### Quality Practices

- preserve source provenance
- record which source created or updated a restaurant
- track confidence for matches
- keep raw source artifacts where relevant
- support duplicate review workflows
- support relinking and correction
- maintain historical link records

### Duplicate Handling

Duplicates are expected when combining broad discovery sources and official datasets.

Common duplicate scenarios:

- same restaurant from OSM and health department dataset
- same restaurant under a slightly different name
- ownership changes at the same address
- permit changes after business transfer

The platform should prefer controlled merging over aggressive auto-merging.

Location-first identity helps reduce duplicate creation, but ambiguous cases such as shared kitchens, ownership changes, and multiple concepts at one address should still be reviewable.

## Search Strategy for Tenants

FiScore should expose a clean tenant search flow built on the master list.

### Version 1 Search Flow

1. tenant enters zip code
2. system returns candidate master restaurants in that area
3. tenant filters by name
4. tenant selects the correct restaurant
5. FiScore creates a tenant-to-master link

### Search Result Display

Search results should ideally show:

- restaurant name
- address
- city/state/zip
- optional permit or facility identifier if useful

This helps avoid incorrect restaurant selection.

## Publication Strategy

The master restaurant list should support two main product uses:

### 1. Tenant Linking

Allow a tenant to add and link the right restaurant.

### 2. Public Inspection Data Association

Once linked, attach:

- public inspections
- report references
- public findings
- source metadata

This keeps the tenant experience tied to the right restaurant identity.

## Legal and Licensing Note

Because FiScore may use open data sources such as OpenStreetMap, the team should review and comply with applicable source licenses and attribution requirements.

Important example:

- OpenStreetMap data is made available under the ODbL license

FiScore should treat source licensing as part of platform design and not as an afterthought.

## Recommended Version 1 Plan

For version 1, FiScore should do the following:

1. import a national seed dataset from OpenStreetMap or a derived U.S. extract
2. define the master restaurant schema and identifier model
3. integrate the first statewide official health datasets
4. build matching and duplicate review workflows
5. expose zip code and restaurant name search for tenant linking
6. link public inspection data to matched master restaurants
7. improve quality over time as more jurisdictions are added

## What Not to Do

FiScore should avoid these mistakes:

- assuming there is one free perfect national restaurant master file
- treating `restaurant name + zip code` as canonical identity
- treating restaurant name alone as the primary identity anchor
- relying only on non-authoritative discovery data for compliance workflows
- trying to ingest every jurisdiction before the matching and ops model is stable
- auto-merging ambiguous restaurants without traceability

## Summary

FiScore should build its own master restaurant list using a layered source strategy rather than searching for a single free perfect dataset. The best approach is to use a broad national seed such as OpenStreetMap, enrich it with official health department datasets wherever available, and anchor everything in a FiScore-owned canonical `masterRestaurantId` with a location-first identity model based on `locationFingerprint`.

This strategy is practical, cost-conscious, and aligned with FiScore's real product need: helping tenants link the correct restaurants and view the correct public inspection history without buying commercial listing data.
