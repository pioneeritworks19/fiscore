# FiScore

FiScore is a restaurant compliance and operations platform focused on public health inspections, internal audits, violations, corrective action workflows, and future operational modules.

This repository now contains the project documentation plus an initial backend scaffold for the ingestion and master-data platform.

## Documentation

Start here:

- [Documentation Index](docs/README.md)

Main sections:

- [Product Docs](docs/product/)
- [App Docs](docs/app/)
- [Backend Docs](docs/backend/)
- [Ingestion Docs](docs/ingestion/)
- [Sword Source Integration](docs/source-integrations/sword/)

## Recommended Reading Order

If you are new to the project, a good starting path is:

1. [Product Overview](docs/product/README.md)
2. [App Navigation](docs/app/APP_NAVIGATION.md)
3. [Master Data Architecture](docs/backend/MASTER_DATA_ARCHITECTURE.md)
4. [Architecture Diagrams](docs/backend/ARCHITECTURE_DIAGRAM.md)
5. [Ingestion Workflows](docs/ingestion/INGESTION_WORKFLOWS.md)
6. [Sword Ingestion Plan](docs/source-integrations/sword/SWORD_SOLUTIONS_INGESTION_PLAN.md)

## Current Focus Areas

- tenant app structure and workflows
- ingestion and master-data platform design
- Google Cloud backend bootstrap planning
- Sword Solutions as the first practical source integration
- Georgia DPH Food Service as the next platform-validation source

## Backend Scaffold

The repository now includes an initial Python backend scaffold for:

- `fiscore-api` via FastAPI
- `fiscore-worker` via FastAPI on Cloud Run
- shared config, database, and Cloud Storage integration helpers
- a dedicated ingestion structure with registry-driven adapter dispatch and source-specific adapters
- SQL bootstrap files for the first `ops`, `ingestion`, and `master` schemas
- initial Sword and Georgia source seed data

## Ingestion Control Panel

The API now includes an internal operations console for ingestion management.

Current capabilities:

- Overview dashboard
- Platform registry dashboard
- Source list with manual run triggers
- Run history and run detail
- Artifact explorer
- Parsed-record explorer
- Health dashboard
- Alert view
- Rerun request workflow
- Master lineage view
- Source version view

Current endpoints/pages:

- `/ops/sources`
- `/ops/runs`
- `/ops/runs/{scrapeRunId}`
- `/ops/artifacts`
- `/ops/artifacts/{rawArtifactId}`
- `/ops/parse-results`
- `/ops/parse-results/{parseResultId}`
- `/ops/health`
- `/ops/alerts`
- `/ops/reruns`
- `/ops/lineage`
- `/ops/versions`
- `/ops/sources/{sourceSlug}/runs`
- `/ops/control-panel`
- `/ops/control-panel/platforms`

## Ingestion Code Layout

Source ingestion code is organized under:

- `src/fiscore_backend/ingestion/core/` for shared ingestion orchestration
- `src/fiscore_backend/ingestion/sources/` for source-specific adapters
- `src/fiscore_backend/ingestion/sources/sword/` for the first Sword adapter scaffold
- `src/fiscore_backend/ingestion/sources/ga_healthinspections/` for the Georgia Tyler county-based sources

## Local Setup

1. Create a virtual environment.
2. Install the package with `pip install -e .`
3. Copy `.env.example` to `.env` and fill in your local values.
4. Run the API:

```bash
uvicorn fiscore_backend.api.main:app --reload
```

5. Run the worker:

```bash
uvicorn fiscore_backend.worker.main:app --reload --port 8080
```

## SQL Bootstrap

Bootstrap SQL lives in:

- `sql/bootstrap/001_init_schemas.sql`
- `sql/bootstrap/002_init_tables.sql`
- `sql/seeds/001_seed_sword_sources.sql`
- `sql/seeds/002_seed_georgia_healthinspections.sql`

These files are intended as the first version-controlled database foundation before a fuller migration system is added.

Once dependencies are installed and `.env` is configured with your Cloud SQL connection values, you can apply them with:

```bash
python scripts/apply_sql_bootstrap.py
```

If your local database was bootstrapped before platform grouping and richer ops run metadata were added, also apply:

- `sql/migrations/004_add_scrape_run_context_columns.sql`
- `sql/migrations/005_add_platform_registry.sql`
- `sql/migrations/006_add_inspection_and_finding_fields.sql`
- `sql/migrations/007_add_scrape_run_issue.sql`
- `sql/migrations/008_add_source_registry_config.sql`

Georgia is now modeled operationally as one source per county under the shared Tyler platform family. The Georgia seed file deactivates the old statewide source slug and inserts county-specific source rows with county config.

## GCP Deployment

For the current rollout order and deploy helpers, use:

- `docs/backend/GCP_DEPLOYMENT_RUNBOOK.md`
- `scripts/deploy_worker.ps1`
- `scripts/deploy_api.ps1`
- `scripts/create_scheduler_jobs.ps1`
