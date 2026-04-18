# FiScore Restaurant Matching

## Purpose

This document defines how FiScore should identify, match, and link restaurants between the master public inspection data platform and tenant-owned restaurant records in the FiScore application.

Restaurant matching is one of the most important data quality problems in the overall product. If the wrong public restaurant is linked to a tenant restaurant, the tenant may see the wrong inspections, the wrong violations, and the wrong compliance history. Because of that, FiScore should favor traceability and safety over aggressive automation.

## Goals

- create a reliable link between tenant restaurants and master public restaurants
- reduce false-positive matches
- support user-assisted search and selection
- preserve confidence and traceability for every match
- support future automation without losing human control
- allow manual review when data is ambiguous

## Non-Goals

- fully automatic matching for all jurisdictions in version 1
- silent auto-linking based only on weak heuristics
- relying on restaurant name and zip code alone as canonical identity

## Matching Principles

### 1. Canonical Identity Belongs to the Master Data Platform

FiScore should use a FiScore-generated `masterRestaurantId` as the canonical public restaurant identity.

This identity should be anchored primarily by a location-first model and may be associated with:

- permit numbers
- license numbers
- agency restaurant ids
- source-specific listing ids
- location fingerprint
- normalized name and address data

The tenant app should link to `masterRestaurantId`, not to a raw source page or a loose text string.

### 2. Search Keys Are Not Canonical Keys

Search-friendly fields such as restaurant name and zip code are useful for user discovery but should not be treated as the long-term canonical identity.

### 3. User Selection Is the Safest Primary Matching Method

In version 1, the most reliable flow is:

1. the tenant user searches by zip code
2. FiScore shows likely restaurants in that area
3. the user searches or filters by name
4. the user chooses the correct restaurant
5. FiScore creates the tenant-to-master link

This approach gives the user direct control and minimizes accidental matches.

### 4. Matching Must Be Explainable

Every match should record:

- how the match was made
- what data supported the match
- how confident the system was
- who confirmed it if a human was involved

### 5. Ambiguous Matches Must Not Be Silently Accepted

If multiple candidates look plausible, FiScore should require user selection or internal review rather than making a hidden guess.

## Identity Layers

FiScore should use a layered identity strategy.

## 1. Strong External Identifiers

These are the best matching signals when available:

- state permit number
- health department license number
- agency restaurant id
- official source listing id

These identifiers should be stored as part of the master data model and used preferentially when present.

## 2. Strong Location Identity

When no official identifier exists, use normalized physical location data:

- normalized street address
- normalized suite or unit when available
- city
- state
- zip code

This should be represented by a FiScore-generated `locationFingerprint`, which acts as the primary canonical match anchor when stronger official identifiers are unavailable.

This is much stronger than name + zip alone and usually more stable than name-based identity.

## 3. Name as Supporting Identity

Restaurant name should still be used, but as supporting identity rather than the primary anchor.

Useful name fields include:

- display name
- normalized name
- alternate names
- DBA variants

## 4. Search Identity

This is optimized for the tenant UI:

- zip code
- searchable display name
- city or neighborhood if useful later

This is for discovery and selection, not canonical identity.

## Matching Inputs

The platform should consider these matching inputs:

- official identifiers from public sources
- normalized restaurant name
- DBA name and alternate names
- street address
- suite or unit information when available
- city
- state
- zip code
- phone number if available
- latitude and longitude if available

## Normalization Rules

Before matching, FiScore should normalize source and tenant restaurant data consistently.

Recommended normalization steps:

- lowercase text values for matching
- trim whitespace
- normalize punctuation
- remove extra spaces
- standardize common abbreviations such as `st`, `street`, `ave`, `avenue`
- normalize directional values such as `n`, `north`
- standardize business suffix noise where appropriate
- preserve a display version separately from normalized matching fields

Address normalization should be especially consistent because it drives the location-first identity model.

Important note:

Normalization should help comparison, but the original source values must still be preserved for auditability and display.

## Recommended Location Fingerprint

FiScore should compute a deterministic `locationFingerprint` from normalized location fields such as:

- normalized address line 1
- normalized suite or unit
- city
- state
- zip

Illustrative concept:

`hash(normalizedAddress1 + normalizedUnit + city + state + zip)`

This fingerprint should be used as the main canonical match anchor when official identifiers are not available.

Important note:

- the location fingerprint is stronger than name-based identity
- it is still not perfect in edge cases such as shared kitchens, ownership changes, or multiple concepts at one address
- ambiguous cases should still go to review rather than silent merge

## Match Types

Every restaurant link should record a match type.

Suggested values:

- `user_selected`
- `exact_identifier_match`
- `exact_name_address_match`
- `fuzzy_name_address_match`
- `manual_admin_link`
- `system_suggested_user_confirmed`

## Match Status

FiScore should explicitly track the state of each match attempt or link.

Suggested values:

- `matched`
- `possible_match`
- `manual_review_required`
- `unmatched`
- `rejected`

## Match Confidence

Even when a user selects a restaurant, it is useful to capture a system confidence score for internal quality analysis.

Suggested confidence scale:

- `high`
- `medium`
- `low`

Or numeric:

- `0.00` to `1.00`

Recommended usage:

- high confidence can support better ranking in search results
- medium confidence may still be shown, but with less prominence
- low confidence should not be auto-linked

## Version 1 Matching Workflow

The version 1 matching flow should prioritize explicit user selection over background automation.

### Recommended Flow

1. user starts tenant setup or adds a restaurant
2. user enters zip code
3. FiScore returns candidate master restaurants for that zip code
4. user filters by restaurant name
5. system ranks likely results using normalized name matching
6. user selects the correct restaurant
7. FiScore creates a `TenantRestaurantLink`
8. FiScore publishes public inspection history for that linked restaurant into the tenant context

### Why This Works Well

- it matches your intended user experience
- it keeps the master dataset controlled
- it avoids risky silent matching
- it still leaves room for better search and recommendation later

## Search and Ranking Recommendations

Although the final choice should come from the user, result ranking matters a lot.

Recommended ranking signals:

- exact zip code match
- exact or near-exact location fingerprint candidate
- exact normalized name match
- name prefix match
- fuzzy name similarity
- exact address match where available
- identifier match where available
- recently active or valid master restaurant records first

The search result should show enough information to help the user choose accurately, such as:

- restaurant name
- address
- city/state/zip
- optional permit or agency identifier if understandable

## Recommended Link Entity

The tenant-to-master relationship should be stored explicitly.

### TenantRestaurantLink

Suggested fields:

- `id`
- `tenantId`
- `tenantRestaurantId`
- `masterRestaurantId`
- `locationFingerprint`
- `matchMethod`
- `matchStatus`
- `matchConfidence`
- `matchedBy`
- `matchedAt`
- `selectedSearchQuery`
- `selectedZipCode`
- `matchExplanation`
- `reviewNotes`

This makes the match auditable and easier to debug later.

## Candidate Generation Rules

The search experience should generate candidate master restaurants using controlled filters.

### Version 1 Candidate Generation

Primary filter:

- zip code

Secondary filter:

- user-entered name search

Optional later enhancements:

- city
- street name
- permit number
- geolocation proximity

## Duplicate and Ambiguity Handling

FiScore should expect ambiguity in public restaurant datasets.

Examples:

- same chain name appearing multiple times in one zip code
- very similar names at the same address after ownership change
- restaurant plus ghost kitchen or related business at the same location
- spelling or formatting inconsistencies across jurisdictions

Recommended handling:

- show multiple candidates when needed
- never auto-select based only on name + zip
- surface address clearly in the candidate list
- support manual admin review for difficult cases

## Re-Linking and Correction

Sometimes a tenant may choose the wrong restaurant or the master record may later be corrected.

FiScore should support controlled re-linking.

### Re-Link Requirements

- existing link can be replaced only through a deliberate workflow
- previous link history should be preserved
- tenant-visible data impacted by the re-link should be reviewed carefully
- if public findings were already imported, the system should define whether they remain historically linked or are corrected forward

Recommended policy:

- preserve historical tenant workflow records
- avoid silently reassigning closed tenant violations to a different public source
- create a link history record whenever re-linking occurs

## Manual Review Workflow

Some restaurant matches will require internal review.

Examples:

- multiple plausible candidates
- conflicting source identifiers
- unclear or incomplete address data
- duplicate master restaurant records

Recommended manual review flow:

1. system marks match as `manual_review_required`
2. internal ops user reviews source and candidate records
3. ops user confirms, rejects, or merges records
4. decision is logged for traceability

## Suggested Supporting Entities

## 1. MasterRestaurant

Suggested matching-relevant fields:

- `masterRestaurantId`
- `locationFingerprint`
- `displayName`
- `normalizedName`
- `normalizedAddress1`
- `normalizedUnit`
- `city`
- `state`
- `zip`
- `status`

## 2. MasterRestaurantIdentifier

Suggested fields:

- `id`
- `masterRestaurantId`
- `identifierType`
- `identifierValue`
- `jurisdictionId`
- `sourceSystemId`
- `isPrimary`
- `confidence`

## 3. TenantRestaurantLink

Suggested fields:

- `id`
- `tenantId`
- `tenantRestaurantId`
- `masterRestaurantId`
- `matchMethod`
- `matchStatus`
- `matchConfidence`
- `matchedBy`
- `matchedAt`

## 4. MatchReviewRecord

Suggested fields:

- `id`
- `tenantRestaurantLinkId`
- `candidateMasterRestaurantIds`
- `reviewStatus`
- `reviewNotes`
- `reviewedBy`
- `reviewedAt`

## Matching Quality Metrics

The internal platform should monitor matching quality over time.

Recommended metrics:

- percentage of user searches resulting in a successful link
- percentage of links later corrected
- manual review rate
- unmatched search rate
- duplicate master restaurant rate
- tenant support issues related to wrong restaurant linkage

These metrics help improve both the search UX and the master data quality.

## Future Matching Enhancements

After version 1, FiScore may expand into more advanced matching capabilities.

Potential enhancements:

- stronger permit/license-based lookup where jurisdictions provide identifiers
- address autocomplete and structured address search
- fuzzy ranking improvements
- duplicate master restaurant merge workflows
- confidence-based suggested auto-link with user confirmation
- support-assisted linking flows for difficult restaurant records

These should be introduced carefully and only after the master data quality is strong enough.

## Recommended Product Rules

To keep the platform safe and predictable, FiScore should adopt these rules:

- do not treat `restaurant name + zip code` as canonical identity
- do not treat restaurant name alone as the primary identity anchor
- use `masterRestaurantId` as the stable public restaurant anchor
- use a location-first identity model with `locationFingerprint` as the primary match anchor when official identifiers are unavailable
- use user-assisted selection as the default matching flow in version 1
- keep a full record of how each restaurant was linked
- require review for ambiguous cases
- preserve link history when corrections happen

## Summary

FiScore should use a user-assisted restaurant matching model in which tenant users search by zip code, filter by restaurant name, and explicitly select the correct master restaurant record. The canonical identity should be a FiScore-managed `masterRestaurantId`, with a location-first model anchored by `locationFingerprint` and strengthened by official identifiers where available.

This approach gives FiScore a practical and safe way to connect tenants to the master compliance dataset while minimizing false matches and preserving long-term traceability.
