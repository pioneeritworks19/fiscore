# FiScore Technology Stack

## Purpose

This document defines the recommended technology stack for the overall FiScore platform.

FiScore is not a single application with one uniform backend. It is a multi-part product with distinct technical responsibilities:

- tenant-facing mobile and web applications
- tenant application backend and data services
- public inspection ingestion and master data platform
- internal operations tooling for source monitoring and data quality management

Because these responsibilities are different, the stack should be chosen as a coordinated platform rather than forcing every part of the product into the same technology choices.

## Stack Philosophy

The recommended stack for FiScore should optimize for:

- speed of product development
- strong fit for mobile-first delivery
- offline-first capability
- cost-effective early implementation
- operational scalability over time
- clear separation between tenant workflows and public master data ingestion

## Platform Overview

FiScore should be thought of as four connected layers:

### 1. Tenant Applications

Customer-facing mobile apps for iOS and Android, plus a lighter companion web app.

### 2. Tenant Application Services

Authentication, tenant data, audits, violations, responses, scoring, sync state, and user workflows.

### 3. Master Data and Ingestion Platform

Scheduled bots and backend services that collect and normalize public health department inspection data from government sources.

### 4. Internal Operations Console

Internal web tooling for operating and maintaining the ingestion platform.

## Recommended Stack by Product Area

## 1. Tenant Mobile Application

### Recommended Stack

- `Flutter`

### Why

- strong cross-platform support for iOS and Android
- one codebase for both primary mobile platforms
- good fit for mobile-first product direction
- supports rich UI workflows such as audits, violations, scoring, media capture, and offline-first behavior

### Key Responsibilities

- user authentication
- tenant onboarding
- restaurant selection and switching
- audit checklist execution
- violation response workflows
- CAPA workflows
- offline data entry
- background sync visibility
- image and short video capture

## 2. Companion Web Application

### Recommended Stack

- `Flutter Web` for a lighter companion web app if the product stays close to the mobile app experience

### Recommendation Note

This is reasonable if the web app is intended to remain lightweight and mostly aligned with the mobile app workflows.

If the web app grows into a much heavier operational product later, the team can reevaluate whether a dedicated web stack is better. For now, staying aligned with Flutter is the simpler product choice.

## 3. Tenant Authentication

### Recommended Stack

- `Firebase Authentication`

### Why

- supports Google login
- supports Apple login
- good fit with Flutter
- reduces custom authentication complexity
- integrates well for mobile-first products

### Recommended Providers

- Google Sign-In
- Sign in with Apple

## 4. Tenant Application Data Layer

### Recommended Stack

- `Cloud Firestore`

### Why

- fits well with Flutter and Firebase
- works well for tenant-scoped product data
- supports real-time patterns where useful
- supports offline persistence
- can accelerate early product development for app workflows

### Recommended Use

Use Firestore for tenant-owned application data such as:

- tenant records
- restaurant membership and selection state
- audit sessions
- audit responses
- tenant violations
- violation responses
- CAPA workflows
- attachments metadata
- user-facing sync state

### Important Boundary

Firestore should not be the main system of record for the public inspection ingestion backend. It is better suited to tenant-facing workflows than to source ingestion operations and master data management.

## 5. Mobile Offline and Local Storage

### Recommended Approach

- use Firestore offline persistence where useful
- add explicit local persistence for stronger offline-first control when needed

### Recommendation Note

Because FiScore has trust-sensitive offline requirements, the app should not rely only on implicit offline sync behavior. It will likely benefit from an explicit local persistence layer for:

- queued writes
- sync status tracking
- conflict handling support
- more predictable offline UX

The exact local database choice can be finalized later, but the product should be designed as offline-first regardless.

## 6. Media Storage for Tenant Workflows

### Recommended Stack

- `Firebase Storage`

### Why

- fits well with mobile upload workflows
- good for storing photos, short videos, and documents
- integrates naturally with Firebase-backed tenant workflows

### Recommended Use

- audit evidence
- violation response evidence
- CAPA attachments

### Best-Practice Note

Media should be optimized before upload to control storage, sync time, and mobile bandwidth use.

## 7. Tenant Backend Logic

### Recommended Stack

- `Firebase Cloud Functions` for lightweight app-side backend logic where appropriate

### Recommended Use

- notifications
- derived counters or summaries
- selected validation workflows
- integration glue between app data and backend services

### Caution

Do not force the ingestion platform into Cloud Functions. Use them only for tenant-application-side backend logic where they are a natural fit.

## 8. Public Inspection Ingestion Platform

### Recommended Stack

- `Python`
- `FastAPI`
- `PostgreSQL`
- `Object storage`

### Why

This part of FiScore has different technical requirements from the app:

- scraping websites
- parsing HTML
- handling PDFs
- normalization and deduplication
- restaurant matching
- source versioning
- operational monitoring

Python and PostgreSQL are a much better fit for this work than trying to force it into the same backend pattern as the tenant app.

### Recommended Responsibilities

- scheduled scraping
- source discovery
- PDF retrieval and extraction
- normalization into master records
- canonical restaurant matching
- source version tracking
- publication to tenant-scoped projections

## 9. Ingestion Job Execution

### Cost-Effective Version 1 Recommendation

- simple scheduled Python jobs
- one worker process
- platform scheduler or cron

### Add Later Only When Needed

- `Redis`
- `Celery`

### Why

This lets FiScore start lean while keeping a clear path to a more robust worker architecture as source count grows.

## 10. Ingestion Parsing and Extraction Tools

### Recommended Tools

- `httpx` or `requests`
- `BeautifulSoup`
- `lxml`
- `pdfplumber`
- `PyMuPDF`
- `pypdf`

### Browser Automation

Recommended selectively:

- `Playwright`

### Recommendation Note

Use browser automation only for sources that truly require it. It should not be the default for every scraper because it increases cost and operational complexity.

## 11. Ingestion Master Data Store

### Recommended Stack

- `PostgreSQL`

### Why

PostgreSQL is the best fit for:

- source registry and scrape runs
- master restaurants
- public inspections and findings
- matching records
- diff and version history
- operational review workflows

It supports the relational and operational nature of the ingestion platform better than Firestore.

## 12. Raw Artifact Storage

### Recommended Stack

- `Google Cloud Storage` or `Amazon S3`

### Recommended Use

- raw HTML
- report PDFs
- extracted text artifacts
- source files and rerun artifacts

### Why

Large unstructured artifacts belong in object storage, not in the primary relational database.

## 13. Internal Operations Console

### Recommended Stack

- `Next.js` or `React`
- backed by `FastAPI`

### Why

The internal console will likely be:

- dashboard-heavy
- table-heavy
- comparison-heavy
- filter-heavy

That type of UI is usually faster and easier to build with a dedicated web stack than with Flutter.

### Responsibilities

- source registry management
- source health monitoring
- scrape run explorer
- raw artifact viewer
- parser diagnostics
- restaurant match review
- duplicate review
- rerun and reprocessing controls

## 14. Internal Monitoring and Observability

### Recommended Capabilities

- structured logging
- error tracking
- operational alerts
- source health metrics

### Suggested Tools

- cloud-native logging and metrics
- `Sentry` for error tracking
- metrics dashboards as needed later

### Why

The ingestion platform depends on external websites that change over time. Monitoring is essential, not optional.

## 15. Cloud Hosting Recommendation

### Recommended Overall Direction

Because the tenant app already aligns well with Firebase and Google services, a Google Cloud-oriented deployment model is a practical choice.

### Suggested Hosting Pattern

Tenant side:

- Firebase Authentication
- Firestore
- Firebase Storage
- Cloud Functions where needed

Ingestion side:

- `Cloud Run` for FastAPI and worker containers
- `Cloud SQL` for PostgreSQL
- `Cloud Storage` for raw artifacts
- `Cloud Scheduler` for scheduled ingestion runs

### Why This Is a Good Fit

- keeps the app and backend in a broadly aligned cloud ecosystem
- still allows the ingestion platform to use the right tools
- avoids forcing everything into Firebase-native constraints

## 16. Recommended Version 1 Technology Summary

### Tenant App

- Flutter
- Firebase Authentication
- Firestore
- Firebase Storage
- Cloud Functions where useful

### Ingestion Platform

- Python
- FastAPI
- PostgreSQL
- Google Cloud Storage or S3
- simple scheduled jobs
- HTML and PDF parsing tools
- Playwright only where needed

### Internal Ops Console

- Next.js or React
- FastAPI backend APIs

## 17. Recommended Future Additions

These should be added only when scale or product needs justify them.

### Tenant Platform

- stronger explicit local database for offline queue control
- more advanced sync conflict tooling

### Ingestion Platform

- Redis
- Celery
- more advanced workflow orchestration
- search indexing for matching or source lookup
- automated anomaly detection

### Internal Operations

- richer dashboards
- parser version comparison tools
- bulk reprocessing tools
- issue assignment workflows

## 18. What Not to Force into One Stack

FiScore should avoid these architecture mistakes:

- forcing the ingestion backend entirely into Firebase
- using Firestore as the primary ingestion master-data store
- using Flutter for the internal operations console by default
- using browser automation for every scraper
- overbuilding queue infrastructure too early

## Final Recommendation

The recommended FiScore platform stack is:

- `Flutter + Firebase` for the tenant-facing mobile and lightweight web app
- `Python + FastAPI + PostgreSQL + object storage` for the ingestion and master data platform
- `Next.js/React + FastAPI` for the internal operations console

This gives FiScore the right technology choices for each part of the product without overcomplicating version 1 or forcing mismatched responsibilities into the same backend model.

## Related Documents

- `README.md`
- `FEATURES.md`
- `SYNC_STRATEGY.md`
- `SCORING_RULES.md`
- `DATA_MODEL.md`
- `MASTER_DATA_ARCHITECTURE.md`
- `RESTAURANT_MATCHING.md`
- `INGESTION_WORKFLOWS.md`
- `INTERNAL_OPS_CONSOLE.md`
- `COST_EFFECTIVE_STACK.md`

