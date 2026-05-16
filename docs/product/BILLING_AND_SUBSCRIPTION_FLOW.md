# FiScore Billing And Subscription Flow

## Purpose

This document defines how FiScore billing should work operationally in version 1.

It complements:

- [PRICING_AND_SUBSCRIPTION_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\PRICING_AND_SUBSCRIPTION_MODEL.md)
- [ONBOARDING_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\ONBOARDING_FLOW.md)
- [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)

This document focuses on:

- who can purchase
- when FiScore asks for payment
- how store purchases map to tenant entitlements
- how added-site upgrades should work
- how enterprise billing should coexist with self-serve billing

## Version 1 Billing Strategy

FiScore should use a hybrid billing model:

- self-serve mobile subscriptions through Apple App Store and Google Play
- enterprise pricing managed outside the app stores

Important principle:

- payment belongs to the billing provider
- entitlement belongs to the FiScore tenant

This means Apple or Google confirms payment, but FiScore remains the source of truth for:

- which tenant the subscription belongs to
- how many sites are included
- whether the tenant is enterprise-managed
- whether founding-customer pricing applies

## Billing Actors

### Billing-Capable Roles

For version 1, the main billing-capable roles should be:

- `tenant_owner`
- `admin`

Managers may see billing prompts during site expansion or other gated actions, but version 1 should not assume managers are the primary billing owners.

### Enterprise Path

Enterprise billing should be handled outside normal in-app self-serve purchase flows.

Enterprise tenants should be marked in FiScore as:

- `enterprise_managed = true`

When this is true, self-serve paywalls should generally not be shown.

## Core Billing Flows

## 1. First Subscription After Initial Value

### Goal

Let the user see product value before requiring payment.

### Flow

1. user signs in
2. user creates tenant
3. user adds first site
4. if the site is linked, FiScore imports public inspections
5. user explores the app
6. on a later meaningful session, FiScore shows the annual Starter subscription prompt
7. user purchases through Apple or Google billing
8. FiScore backend verifies the purchase and maps it to the tenant
9. tenant entitlement becomes active

### Result

The tenant gains:

- `subscriptionPlan = starter_annual`
- `subscriptionStatus = active`
- `includedSiteCount = 1`

## 2. Add Additional Site

### Goal

Support smooth site-based expansion for small operators.

### Flow

1. authorized user selects `Add Site`
2. FiScore checks:
   - current `activeSiteCount`
   - current `includedSiteCount`
   - whether tenant is `enterprise_managed`
3. if the tenant still has available entitlement, site creation continues normally
4. if the tenant needs more capacity, FiScore shows the site-expansion paywall
5. user purchases an annual additional-site subscription
6. backend verifies purchase and increases tenant entitlement
7. site creation resumes

### Result

The tenant keeps the same plan family but gains additional site entitlement.

Recommended version 1 interpretation:

- each additional-site purchase increments `includedSiteCount` by `1`

## 3. Enterprise Threshold

### Goal

Route larger operators into higher-touch sales and rollout support.

### Flow

1. user attempts to add a site beyond self-serve threshold
2. FiScore detects that the tenant would exceed self-serve limits
3. app shows enterprise threshold message instead of self-serve purchase flow
4. user is given a `Contact FiScore` action
5. FiScore internal team later activates enterprise billing state in the backend

### Result

The tenant is managed outside in-app self-serve purchase logic.

## 4. Renewal And Expiration

### Goal

Handle store renewals without tying app access to a single device account.

### Recommended behavior

- Apple or Google manages subscription renewal and cancellation
- FiScore backend listens for or periodically verifies billing-provider status
- tenant entitlement updates based on verified subscription state

Recommended result states:

- `trial`
- `active`
- `past_due`
- `cancelled`
- `expired`
- `enterprise_managed`

## Tenant Entitlement Model

FiScore should treat billing as tenant-level entitlement rather than user-level access.

### Why this matters

One tenant may have:

- one owner on iPhone
- one admin on Android
- managers and staff on multiple devices

The purchaser's device account should not be the thing that determines app access.

Instead, the billing flow should:

1. identify the purchasing user
2. identify the active tenant
3. verify the purchase with the billing provider
4. write the entitlement to the tenant
5. allow all authorized tenant members to benefit from that entitlement

### Recommended entitlement fields

At minimum, FiScore should track:

- `subscriptionPlan`
- `subscriptionStatus`
- `billingProvider`
- `includedSiteCount`
- `activeSiteCount`
- `enterpriseManaged`
- `currentPeriodStartsAt`
- `currentPeriodEndsAt`
- `foundingCohortEligible`
- `foundingCohortLabel`

## Founding-Customer Flow

If the tenant is part of the initial cohort:

- the paywall should show the discounted annual price clearly
- backend should record that the tenant is on a founding-customer offer
- the entitlement record should preserve whether the discount was applied

Best-practice expectation:

- founding-customer logic should be tied to the tenant, not only to the device or current user session

## In-App Paywall Recommendations

### First Subscription Prompt

Should emphasize:

- annual value
- one included site
- what core workflows are unlocked
- any founding-customer discount

### Add-Site Upgrade Prompt

Should emphasize:

- current plan includes one site
- this action adds one additional site entitlement
- exact annual price for the added site
- any first-term founding-customer discount

### Enterprise Threshold Prompt

Should emphasize:

- larger groups are supported
- FiScore offers enterprise pricing and rollout help
- user should contact FiScore rather than expecting self-serve checkout

## Version 1 Guardrails

- billing prompts should not interrupt active audit execution
- billing should be enforced at clean transitions such as setup, expansion, or deeper use
- existing data visibility should not disappear abruptly because of a billing issue
- site-count enforcement should be clear and understandable
- enterprise-managed tenants should bypass normal self-serve purchase logic

## Suggested Backend Responsibilities

The FiScore backend should be responsible for:

- verifying Apple or Google purchase state
- mapping verified purchases to the correct tenant
- updating tenant entitlement fields
- recording purchase history
- enforcing site-count limits for site creation and expansion
- marking enterprise tenants as externally managed

## Summary

FiScore version 1 billing should work as a tenant-level entitlement system with:

- Apple and Google handling self-serve mobile subscription payments
- FiScore backend handling entitlement mapping and enforcement
- simple site-count growth through additional-site purchases
- enterprise customers handled through a separate managed path
