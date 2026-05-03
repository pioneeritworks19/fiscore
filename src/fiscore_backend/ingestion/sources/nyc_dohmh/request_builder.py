from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta

from fiscore_backend.ingestion.core.lookback import is_small_incremental_run, resolve_lookback_days
from fiscore_backend.ingestion.core.source_registry import SourceRegistryRecord
from fiscore_backend.models import RunMode, WorkerRunRequest


DEFAULT_BOROUGHS = ("Bronx", "Brooklyn", "Manhattan", "Queens", "Staten Island")


@dataclass(frozen=True)
class NYCDOHMHRunPlan:
    run_mode: RunMode
    strategy: str
    date_from: date | None
    date_to: date | None
    borough_partitions: tuple[str, ...]
    request_context: dict[str, str | bool | int | None]


def build_run_plan(source: SourceRegistryRecord, request: WorkerRunRequest) -> NYCDOHMHRunPlan:
    run_mode = request.run_mode
    today = datetime.now(UTC).date()
    borough_partitions = tuple(source.source_config.get("borough_partitions") or DEFAULT_BOROUGHS)
    dataset_id = str(source.source_config.get("dataset_id") or "43nn-pn8j")
    resource_url = str(
        source.source_config.get("resource_url")
        or f"https://data.cityofnewyork.us/resource/{dataset_id}.json"
    )
    metadata_url = str(
        source.source_config.get("metadata_url")
        or f"https://data.cityofnewyork.us/api/views/{dataset_id}"
    )
    columns_url = str(
        source.source_config.get("columns_url")
        or f"https://data.cityofnewyork.us/api/views/{dataset_id}/columns.json"
    )

    if run_mode == "backfill":
        return NYCDOHMHRunPlan(
            run_mode=run_mode,
            strategy="citywide_dataset_snapshot_backfill",
            date_from=None,
            date_to=None,
            borough_partitions=borough_partitions,
            request_context={
                "platform": source.platform_name,
                "source_name": source.source_name,
                "jurisdiction_name": source.jurisdiction_name,
                "dataset_id": dataset_id,
                "resource_url": resource_url,
                "metadata_url": metadata_url,
                "columns_url": columns_url,
                "page_size": 5000,
                "notes": (
                    "Backfill should establish a baseline from the current NYC dataset while "
                    "using boroughs only as runtime retrieval partitions."
                ),
            },
        )

    lookback_days = resolve_lookback_days(
        request=request,
        incremental_default=30,
        reconciliation_default=180,
    )
    date_from = today - timedelta(days=lookback_days)
    return NYCDOHMHRunPlan(
        run_mode=run_mode,
        strategy=(
            "small_overlap_window_dataset_refresh"
            if is_small_incremental_run(request=request)
            else "overlap_window_dataset_refresh"
        ),
        date_from=date_from,
        date_to=today,
        borough_partitions=borough_partitions,
        request_context={
            "platform": source.platform_name,
            "source_name": source.source_name,
            "jurisdiction_name": source.jurisdiction_name,
            "dataset_id": dataset_id,
            "resource_url": resource_url,
            "metadata_url": metadata_url,
            "columns_url": columns_url,
            "page_size": 5000,
            "lookback_days": lookback_days,
            "from_date": date_from.isoformat(),
            "to_date": today.isoformat(),
            "notes": (
                "Incremental and reconciliation runs should use overlapping windows to limit "
                "fetch scope while letting FiScore comparison logic determine final changes."
            ),
        },
    )
