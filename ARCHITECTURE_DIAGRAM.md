# FiScore Architecture Diagram

## Purpose

This document provides high-level architecture diagrams for the FiScore platform.

The goals are to:

- visualize the separation between the tenant application and the public-data backend
- clarify how data moves through the ingestion pipeline
- show where different storage layers live
- support future implementation, onboarding, and architecture discussions

This document is intended to complement the written architecture and schema documents, not replace them.

## Architecture Principles Reflected Here

- the tenant app and the ingestion/master-data platform are separate systems
- public source data is processed through raw, parsed, and canonical layers
- tenant users only see data for linked restaurants
- tenant workflows remain private to the tenant
- Google Cloud is the initial backend hosting direction

## 1. High-Level System Architecture

```mermaid
flowchart LR
    subgraph Public["Public Data Sources"]
        S1["Sword Solutions Counties"]
        S2["Future State/County/City Sources"]
        S3["Regulatory Clause Sources<br/>e.g. Michigan Food Code"]
    end

    subgraph GCP["Google Cloud Backend Platform"]
        subgraph Run["Cloud Run"]
            API["Backend API"]
            WORKER["Ingestion Worker"]
        end

        subgraph Storage["Storage"]
            GCS["Cloud Storage<br/>Raw Artifacts"]
            PG["Cloud SQL PostgreSQL<br/>ops / ingestion / master"]
            SM["Secret Manager"]
            SCH["Cloud Scheduler"]
        end
    end

    subgraph Tenant["Tenant Application Platform"]
        APP["Flutter App<br/>iOS / Android / Web"]
        FS["Cloud Firestore<br/>Tenant Data + Projections"]
        FBS["Firebase Storage<br/>Tenant Uploads"]
    end

    subgraph Internal["Internal Operations"]
        OPSUI["Ops Console / Internal UI"]
    end

    S1 --> WORKER
    S2 --> WORKER
    S3 --> WORKER

    SCH --> WORKER
    SM --> API
    SM --> WORKER

    WORKER --> GCS
    WORKER --> PG
    API --> PG

    WORKER --> FS
    APP --> FS
    APP --> FBS
    API --> FS

    OPSUI --> API
    OPSUI --> PG
```

## Diagram Explanation

### Public Sources

These are the external websites, portals, and regulatory reference sources FiScore ingests from.

Examples:

- Sword Solutions county inspection sites
- future statewide or county-specific public health sources
- regulatory code sources for clause reference libraries

### Google Cloud Backend Platform

This is the ingestion and master-data platform.

Main responsibilities:

- fetch and store raw source artifacts
- parse source data
- normalize records into canonical master data
- maintain operations tracking
- publish tenant-facing projections

### Tenant Application Platform

This is the customer-facing app stack.

Main responsibilities:

- tenant onboarding
- restaurant overview and drill-in
- audit workflows
- violation workflows
- public inspection viewing
- tenant-uploaded onsite report handling

### Internal Operations

This is the internal-only operational layer for running and monitoring the ingestion platform.

## 2. Backend Data Layer Architecture

```mermaid
flowchart TD
    subgraph GCS["Cloud Storage"]
        RAW["Raw HTML / PDFs / Source Artifacts"]
    end

    subgraph PG["Cloud SQL PostgreSQL"]
        subgraph OPS["ops schema"]
            SRC["source_registry"]
            RUN["scrape_run"]
            HEALTH["source_health"]
            ALERT["operational_alert"]
            RERUN["rerun_request"]
        end

        subgraph ING["ingestion schema"]
            ART["raw_artifact_index"]
            PARSE["parse_result"]
            WARN["parser_warning"]
        end

        subgraph MASTER["master schema"]
            MR["master_restaurant"]
            MRI["master_restaurant_identifier"]
            MI["master_inspection"]
            MF["master_inspection_finding"]
            CLAUSE["source_clause_reference"]
            VER["source_version"]
        end
    end

    RAW --> ART
    SRC --> RUN
    RUN --> ART
    ART --> PARSE
    PARSE --> WARN
    PARSE --> MR
    PARSE --> MI
    PARSE --> MF
    PARSE --> CLAUSE
    MI --> VER
    MF --> VER
    SRC --> HEALTH
    RUN --> ALERT
    SRC --> RERUN
```

## Diagram Explanation

### `ops` Schema

Tracks:

- source definitions
- run history
- health state
- alerts
- rerun controls

### `ingestion` Schema

Tracks:

- raw artifact metadata
- parsed snapshots
- parser warnings

### `master` Schema

Stores canonical public data:

- restaurants
- identifiers
- inspections
- findings
- source-specific clause references
- source versions

## 3. Public Data Flow to Tenant App

```mermaid
flowchart LR
    A["Public Website / Regulatory Source"] --> B["Fetch Source Content"]
    B --> C["Store Raw Artifacts<br/>Cloud Storage"]
    C --> D["Parse Structured Data"]
    D --> E["Store Parsed Snapshots<br/>ingestion schema"]
    E --> F["Normalize + Match + Version"]
    F --> G["Canonical Master Records<br/>master schema"]
    G --> H["Publish Linked Restaurant Projections"]
    H --> I["Firestore Public Inspection Projections"]
    I --> J["Tenant User Views Inspections"]
    I --> K["Latest Public Findings Become<br/>Tenant Violations"]
```

## Diagram Explanation

This shows the public-data path:

1. fetch source data
2. store raw artifacts
3. parse into structured snapshots
4. normalize into canonical master records
5. publish only linked restaurant data into Firestore
6. expose it inside the tenant app

## 4. Tenant Workflow Data Flow

```mermaid
flowchart LR
    A["Public Inspection Projection"] --> B["Tenant Violation Created<br/>Latest Findings Only"]
    C["Internal Audit"] --> D["Audit Responses"]
    D --> E["Submitted Audit"]
    E --> F["Audit-Triggered Violations"]

    B --> G["Tenant Violation Workflow"]
    F --> G

    G --> H["Response / CAPA"]
    H --> I["Manager Review"]
    I --> J["Closed or Reopened"]

    K["Onsite Inspection Report Upload"] --> L["Firebase Storage"]
    K --> M["Firestore Report Metadata"]
    M --> N["Public Inspection Detail Screen"]
    L --> N
```

## Diagram Explanation

This shows the tenant-private workflow path:

- public findings can create tenant violations
- internal audits can also create tenant violations
- tenant users respond privately
- managers review and close
- onsite uploaded inspection reports stay in the tenant document/file layer

## 5. Restaurant-Centered App Model

```mermaid
flowchart TD
    TENANT["Tenant"] --> RESTLIST["Restaurants Overview"]
    RESTLIST --> REST1["Selected Restaurant Context"]
    REST1 --> DASH["Restaurant Dashboard"]
    REST1 --> VIOL["Violations"]
    REST1 --> AUD["Audits"]
    REST1 --> INSP["Inspections"]
    REST1 --> FUT["Future Modules<br/>Assets / Complaints / More"]
```

## Diagram Explanation

This reflects the updated product direction:

- users can see a portfolio-level restaurant overview
- detailed work still happens in one selected restaurant context at a time
- the app is designed to grow beyond inspections and violations

## Recommended Reading Order with Other Docs

This diagram set pairs especially well with:

- `MASTER_DATA_ARCHITECTURE.md`
- `MASTER_DATA_SCHEMA.md`
- `FIRESTORE_SCHEMA.md`
- `APP_NAVIGATION.md`
- `WORKFLOWS.md`
- `BACKEND_BOOTSTRAP_CHECKLIST.md`

## Summary

FiScore is best understood as two connected platforms:

- a tenant-facing restaurant operations application
- a Google Cloud-hosted ingestion and master-data backend

Public data flows from websites and regulatory sources into raw artifacts, parsed snapshots, and canonical master records before being projected into tenant-facing Firestore documents for linked restaurants. Tenant users then operate privately on that projected data through audits, violations, remediation workflows, and uploaded onsite documents.

