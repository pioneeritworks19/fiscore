from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta

from fiscore_backend.ingestion.core.source_registry import SourceRegistryRecord
from fiscore_backend.models import RunMode


@dataclass(frozen=True)
class GeorgiaRunPlan:
    run_mode: RunMode
    strategy: str
    date_from: date | None
    date_to: date | None
    request_context: dict[str, str | bool | None]


def build_run_plan(source: SourceRegistryRecord, run_mode: RunMode) -> GeorgiaRunPlan:
    today = datetime.now(UTC).date()
    county_name = source.source_config.get("county_name")

    if run_mode == "backfill":
        return GeorgiaRunPlan(
            run_mode=run_mode,
            strategy="county_scoped_full_history_backfill",
            date_from=None,
            date_to=None,
            request_context={
                "platform": source.platform_name,
                "source_name": source.source_name,
                "jurisdiction_name": source.jurisdiction_name,
                "base_url": source.base_url.rstrip("/") + "/",
                "county_name": county_name,
                "permit_type_label": "Food Service",
                "partition_mode": "target_single_county_from_landing_page",
                "notes": (
                    "Georgia county sources should resolve a single county option from the landing "
                    "page and run that county without date filters for full-history backfill."
                ),
            },
        )

    lookback_days = 30 if run_mode == "incremental" else 180
    date_from = today - timedelta(days=lookback_days)
    return GeorgiaRunPlan(
        run_mode=run_mode,
        strategy="statewide_county_partition_date_refresh",
        date_from=date_from,
        date_to=today,
        request_context={
            "platform": source.platform_name,
            "source_name": source.source_name,
            "jurisdiction_name": source.jurisdiction_name,
            "base_url": source.base_url.rstrip("/") + "/",
            "county_name": county_name,
            "permit_type_label": "Food Service",
            "partition_mode": "target_single_county_from_landing_page",
            "from_date": date_from.isoformat(),
            "to_date": today.isoformat(),
            "notes": (
                "Date filters should narrow search scope while a county-specific source keeps "
                "execution bounded and operationally simple."
            ),
        },
    )
