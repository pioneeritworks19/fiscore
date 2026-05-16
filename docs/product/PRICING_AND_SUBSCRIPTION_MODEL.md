# FiScore Pricing And Subscription Model

## Purpose

This document defines the recommended version 1 monetization model for FiScore.

The goal is to keep pricing:

- simple for self-signup restaurant operators
- aligned with site-based product value
- clear inside the app and on the public pricing page
- flexible enough to support a founding or initial cohort discount
- expandable later for larger multi-site operators

## Recommended Version 1 Pricing Philosophy

FiScore should be priced primarily by `site count`, not by:

- number of audits
- number of violations
- number of users
- number of uploaded photos
- number of notifications

This keeps the pricing model aligned with the customer's mental model:

- one restaurant location
- a few restaurant locations
- many restaurant locations

For FiScore version 1, self-serve pricing should stay simple and should avoid enterprise-style packaging on the public self-signup path.

## Recommended Version 1 Self-Serve Pricing

### Starter Annual Plan

Recommended public price:

- `$99/year`

Includes:

- `1 site`
- public inspection visibility for linked sites
- internal audits
- violations
- violation thread and structured response
- training assignment and completion
- core notifications
- basic operational reporting

Target customer:

- single-location restaurant
- owner-operator
- small restaurant team

### Additional Site Pricing

Recommended public price:

- `+$79/year per additional site`

Examples:

- `1 site = $99/year`
- `2 sites = $178/year`
- `3 sites = $257/year`
- `4 sites = $336/year`
- `5 sites = $415/year`

This keeps the upgrade path smooth for restaurants with exactly two locations, which is likely to be a common customer profile.

### Enterprise Threshold

For version 1 self-serve, FiScore should support self-service pricing up to `5 sites`.

Recommended rule:

- `6+ sites = contact FiScore for enterprise pricing`

This gives FiScore room to handle larger customers with:

- custom rollout support
- negotiated pricing
- higher-touch onboarding
- future premium requirements

## Initial Cohort Discount

FiScore should support a limited founding or initial cohort discount for early adopters.

Recommended structure:

- Starter public price: `$99/year`
- Initial cohort Starter discount: `$79/year` for the first billing term
- Additional site public price: `+$79/year per site`
- Initial cohort additional site discount: `+$59/year per site` for the first billing term

Best-practice expectations:

- the discount should be explicitly labeled as a limited early-adopter or founding-customer offer
- the product should state whether the discount is first-year only or locked for a defined term
- the discounted price should not permanently replace the standard list price in the public pricing model

Recommended product wording:

- `Founding customer pricing`
- `Early adopter annual pricing`

Avoid vague discount framing that makes the standard pricing look unstable.

## Recommended In-App Monetization Journey

FiScore should let users experience meaningful value before requiring payment.

Recommended journey:

1. user signs up
2. user creates tenant
3. user adds first site
4. user sees imported public inspections if available
5. FiScore allows brief exploration of the product
6. FiScore presents subscription choice after the user has seen initial value
7. FiScore eventually requires subscription before continued operational expansion

### Soft Prompt Timing

Recommended soft-prompt moments:

- second or third meaningful login
- after first site setup is complete
- after public inspection history is visible for a linked site

This prompt should be dismissible at first.

### Hard-Gate Timing

Recommended hard-gate moments:

- before creating the first internal audit after a short preview period
- or before inviting additional team members beyond a small starter limit
- or after a limited time-based preview window

Recommended version 1 approach:

- allow tenant setup and first-site setup before payment
- require subscription before the tenant begins repeated operational usage

### Site Expansion Upgrade Moment

When a tenant tries to add a second site, the app should use a clear site-based upgrade flow.

Recommended message pattern:

- current plan includes `1 site`
- adding this site adds `+$79/year`
- founding-customer discount, if active, is shown clearly

This is easier for small operators to understand than forcing a broad plan jump such as `Growth`.

## Pricing Presentation In The Product

For the public pricing page and billing screens, FiScore should present pricing as:

### 1. Starter

- `1 site`
- `$99/year`
- `Best for one restaurant`

### 2. Add Sites As You Grow

- `+$79/year per additional site`
- `Best for small operators with 2 to 5 sites`

### 3. Enterprise

- `6+ sites`
- `Contact Us`

The annual price should be primary. Version 1 does not need to emphasize monthly pricing.

## Recommended Billing Access

Billing and subscription management should be tenant-level administrative capabilities.

Recommended roles:

- `tenant_owner`
- `admin`

Managers may see plan status in context when attempting an upgrade-triggering action, but they should not necessarily be the primary billing managers in version 1 unless product policy expands later.

## Suggested Version 1 Billing Rules

### Site Entitlement

The tenant's current subscription should define:

- included site count
- current active site count
- whether additional self-serve site expansion is allowed
- whether the tenant has reached enterprise threshold

### Plan Enforcement

The system should:

- allow viewing already-created data even if billing needs attention, within reason
- avoid blocking critical safety workflows in the middle of active work
- enforce billing at clean transition points such as adding a site or beginning deeper operational use

### Billing-Related Statuses

Recommended billing or subscription statuses:

- `trial`
- `active`
- `past_due`
- `cancelled`
- `expired`
- `enterprise_managed`

## Recommended In-App Upgrade UX

### After Initial Value

Use a lightweight annual-plan prompt after the user has seen real value.

Example:

- `FiScore is ready for your restaurant`
- `Continue with the Starter annual plan for 1 site`
- show standard annual price and any active founding-customer discount

### Adding A Second Site

Use a direct site-expansion confirmation.

Example:

- `Add this site to your FiScore plan`
- `Your current plan includes 1 site. This additional site adds $79/year.`

If founding pricing is active:

- `Founding customer price: $59/year for this site for your first term`

### Enterprise Threshold

When the tenant attempts to exceed self-serve site count:

- explain that FiScore supports larger operators through enterprise pricing
- provide a clear `Contact FiScore` path

## Why This Model Fits FiScore

This pricing model fits the current product because:

- FiScore's value scales naturally by restaurant site
- one-site and two-site operators need a gentle upgrade path
- larger operators should be handled more deliberately
- the product includes operational workflows serious enough to justify business pricing
- a very low consumer-style price point would likely undervalue the product and weaken long-term economics

## Future Expansion Options

Later pricing evolution may include:

- premium training library add-ons
- premium checklist packs
- advanced analytics
- premium support
- implementation or setup services

These should not complicate the version 1 self-serve story.

## Summary

For version 1, FiScore should use an annual-first, site-based pricing model:

- `Starter: $99/year for 1 site`
- `Additional sites: +$79/year per site`
- `Enterprise: 6+ sites by contact`

FiScore should also support an explicit initial cohort discount so early adopters receive a clearly framed annual founding-customer offer without confusing the long-term pricing structure.
