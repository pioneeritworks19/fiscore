# FiScore Cost-Effective Ingestion Stack

## Purpose

This document defines the recommended cost-effective technology approach for the FiScore public inspection ingestion platform.

The goal is to balance:

- low initial infrastructure cost
- low engineering complexity
- strong fit for scraping and normalization work
- a clean path to scale later without rewriting the platform

This document focuses on the ingestion and master data backend, not the tenant-facing mobile and web app stack.

## Recommendation Summary

The most cost-effective honest recommendation is:

- start with a lean ingestion platform built on `Python + PostgreSQL + object storage`
- add operational complexity only when scale justifies it
- avoid forcing the ingestion backend into Firebase-only patterns
- use browser automation selectively, not as the default

The recommended version 1 platform should be intentionally smaller than the eventual target architecture, while still using technology choices that will hold up as the product grows.

## Core Recommendation

### Recommended Version 1 Stack

- `Python`
- `FastAPI`
- `PostgreSQL`
- `Object storage` such as Google Cloud Storage or Amazon S3
- `Scheduled jobs` using a simple scheduler or platform cron
- `HTML parsing` with lightweight request-based scraping where possible
- `PDF extraction` with Python PDF tools
- `Minimal internal operations UI` or lightweight admin views

### Add Later Only When Needed

- `Redis`
- `Celery` or a more formal worker queue
- `Playwright` for dynamic sites that cannot be scraped reliably with direct requests
- richer internal operations dashboards
- advanced search or matching services

## Why This Is the Honest Recommendation

This approach is cost-effective because it optimizes for total cost, not just monthly hosting cost.

For FiScore, the ingestion side must handle:

- many public websites with inconsistent structures
- PDF report handling
- normalization into a shared schema
- restaurant matching
- change detection
- operational monitoring

Trying to do this too cheaply with the wrong stack often creates hidden costs in:

- slower development
- fragile parsers
- difficult debugging
- painful maintenance
- eventual rework

The recommended approach avoids those traps while still staying lean early on.

## Cost-Effective Principles

### 1. Keep the Foundation Strong

Use technologies that fit the ingestion problem well from the start:

- Python for scraping and parsing
- PostgreSQL for structured backend data
- object storage for raw artifacts

These are inexpensive relative to the value they provide.

### 2. Delay Distributed Complexity

Do not begin with a heavily distributed backend if version 1 only covers a small number of sources.

It is usually cheaper to start with:

- one API service
- one worker process
- one database
- one storage bucket

than to launch multiple infrastructure layers before they are justified.

### 3. Use Browser Automation Sparingly

Browser automation is powerful, but it is also the easiest place for infrastructure cost and operational complexity to grow.

Use direct HTTP fetching and HTML parsing first whenever possible. Add browser automation only for sources that truly require it.

### 4. Build Minimal but Real Operations Support

Do not overbuild the internal operations console at the start, but do not skip operational visibility entirely.

Version 1 should still have:

- source health visibility
- run history
- error visibility
- manual rerun support

without attempting to build a full enterprise console on day one.

## Recommended Version 1 Architecture

The cost-effective version 1 ingestion platform should look like this:

### Application Layer

- `FastAPI` service for:
  - internal APIs
  - source registry endpoints
  - run inspection endpoints
  - lightweight internal admin pages if desired

### Worker Layer

- one Python worker process for:
  - scheduled scraping
  - parsing
  - normalization
  - publication steps

This can begin as a simple process triggered by cron or cloud scheduler jobs.

### Data Layer

- `PostgreSQL` for:
  - source registry
  - scrape runs
  - normalized restaurants
  - normalized inspections and findings
  - matching records
  - audit and operational metadata

### Artifact Layer

- `Object storage` for:
  - raw HTML
  - report PDFs
  - extracted text
  - parser artifacts when useful

### Scheduling Layer

- platform scheduler or cron for:
  - weekly jobs
  - monthly jobs
  - manual rerun triggers

This matches your current expected freshness model well.

## Version 1 Tools by Responsibility

### Scraping and HTTP

Recommended:

- `httpx` or `requests`
- `BeautifulSoup`
- `lxml`

Use these for the majority of simple or moderately structured sources.

### Browser Automation

Recommended only when needed:

- `Playwright`

Use this only for:

- heavy JavaScript sites
- difficult pagination flows
- sessions that require browser execution

### PDF Handling

Recommended:

- `pdfplumber`
- `PyMuPDF`
- `pypdf`

Start with text-based extraction first. Add OCR only if a meaningful number of jurisdictions require it.

### Data Validation

Recommended:

- `Pydantic`

This helps define structured parsed and normalized outputs clearly and reduces data-shape drift.

## What to Avoid in Version 1

To keep the backend cost-effective, FiScore should avoid these choices early on:

### Avoid Firebase-Only Ingestion Architecture

Firestore and Firebase can still be useful for the tenant-facing app, but they are not the best system of record for:

- scraper runs
- source versioning
- deduplication workflows
- matching review
- operational querying

### Avoid Browser Automation for Every Source

This drives up:

- compute cost
- runtime
- maintenance burden
- failure rate

### Avoid Overbuilding Worker Infrastructure Too Early

If the initial number of sources is small, you may not need:

- Redis
- Celery
- multiple asynchronous workers
- complicated orchestration frameworks

### Avoid Large Custom Ops Console Scope at the Start

Begin with the smallest useful operational surface and grow it based on actual workload.

## Recommended Growth Path

The most cost-effective approach is staged growth.

## Stage 1: Lean Launch

Best for:

- small number of statewide sources
- weekly and monthly refresh cycles
- early product validation

Recommended stack:

- Python
- FastAPI
- PostgreSQL
- object storage
- simple scheduler
- direct HTTP scraping
- PDF parsing
- lightweight internal admin tools

Benefits:

- low monthly cost
- fast iteration
- lower engineering overhead
- enough structure to avoid a full redesign later

## Stage 2: Controlled Scale

Best for:

- dozens of sources
- more frequent retries
- more operational incidents
- more need for queueing and retries

Add:

- Redis
- Celery or similar worker queue
- stronger monitoring
- richer operations console
- stage-specific reruns

Benefits:

- better reliability
- cleaner separation of work
- easier retries and pipeline control

## Stage 3: Broader Platform Scale

Best for:

- many state, county, and city sources
- heavier change management
- significant operations team usage

Possible additions:

- search index for matching or source lookup
- more advanced anomaly detection
- parser version comparison tooling
- more formal workflow orchestration
- richer coverage analytics

These should be added only when the business and source count justify them.

## Suggested Deployment Strategy

For a cost-conscious version 1, deploy a small number of managed services.

### Sensible Setup

- 1 API service
- 1 worker service
- 1 managed PostgreSQL instance
- 1 object storage bucket
- 1 scheduler

This can run comfortably in:

- Google Cloud
- AWS
- Azure
- or another environment with equivalent managed services

### Good Cloud Fit

Because the rest of your product may already lean toward Firebase and Google, a practical choice would be:

- `Cloud Run` for API and worker containers
- `Cloud SQL` for PostgreSQL
- `Cloud Storage` for artifacts
- `Cloud Scheduler` for timed runs

This keeps the stack aligned without forcing the ingestion model into Firebase-native limitations.

## Monthly Cost Mindset

The biggest cost drivers are usually not the core stack itself. They are:

- too many browser-based scrapers
- too-frequent scraping schedules
- OCR-heavy document handling
- excessive retention of expensive compute tasks
- overbuilt infrastructure too early

The core stack of Python, Postgres, and object storage is generally a cost-efficient foundation.

## Engineering Cost Mindset

Engineering cost often matters more than infrastructure cost in the early product stage.

The recommended stack is strong because:

- Python reduces implementation friction for scraping and parsing
- PostgreSQL makes matching and operational queries easier
- object storage keeps large artifacts cheap and manageable
- FastAPI is fast to build and maintain

This lowers the cost of iteration, debugging, and future onboarding.

## Recommended Version 1 Build Order

If the goal is to launch the ingestion side cheaply and sensibly, the build order should be:

1. source registry
2. scrape run tracking
3. raw artifact storage
4. parser and normalization pipeline
5. master restaurant and inspection storage
6. tenant publication for linked restaurants
7. lightweight internal monitoring views
8. manual rerun support

Only after that should the team consider:

- worker queues
- advanced dashboarding
- broader automation

## Honest Final Recommendation

The most cost-effective path for FiScore is:

- use `Python + PostgreSQL + object storage` as the core ingestion foundation
- keep the initial deployment small and simple
- avoid heavy browser automation unless required
- add `Redis`, `Celery`, and richer operations tooling only when source count and operational complexity justify them

This gives FiScore a backend that is affordable now, practical to build, and strong enough to grow without a painful architectural reset.

## Related Documents

This document pairs well with:

- `MASTER_DATA_ARCHITECTURE.md`
- `INGESTION_WORKFLOWS.md`
- `INTERNAL_OPS_CONSOLE.md`
- `RESTAURANT_MATCHING.md`

