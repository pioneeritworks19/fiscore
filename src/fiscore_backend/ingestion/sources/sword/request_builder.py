from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta

from fiscore_backend.ingestion.core.source_registry import SourceRegistryRecord
from fiscore_backend.models import RunMode


@dataclass(frozen=True)
class SwordRunPlan:
    run_mode: RunMode
    strategy: str
    date_from: date | None
    date_to: date | None
    request_context: dict[str, str | bool | None]


def _resolve_inspections_url(base_url: str) -> str:
    normalized = base_url.rstrip("/")
    if normalized.endswith("/inspections"):
        return f"{normalized}/"
    return f"{normalized}/inspections/"


def _resolve_county_value(jurisdiction_name: str) -> str | None:
    county_lookup = {
        "Allegan County, MI": "38",
        "Grand Traverse County, MI": "40",
        "Livingston County, MI": "31",
        "Marquette County, MI": "39",
        "Muskegon County, MI": "32",
        "Oakland County, MI": "65",
        "Washtenaw County, MI": "28",
        "Wayne County, MI": "33",
    }
    return county_lookup.get(jurisdiction_name)


def build_run_plan(source: SourceRegistryRecord, run_mode: RunMode) -> SwordRunPlan:
    today = datetime.now(UTC).date()
    inspections_url = _resolve_inspections_url(source.base_url)
    county_value = _resolve_county_value(source.jurisdiction_name)

    if run_mode == "backfill":
        return SwordRunPlan(
            run_mode=run_mode,
            strategy="full_county_no_date_restriction",
            date_from=None,
            date_to=None,
            request_context={
                "platform": source.platform_name,
                "source_name": source.source_name,
                "jurisdiction_name": source.jurisdiction_name,
                "base_url": inspections_url,
                "county_value": county_value,
                "show_partial": True,
                "notes": "Backfill mode should use the broadest safe county scope available.",
            },
        )

    lookback_days = 45 if run_mode == "incremental" else 180
    date_from = today - timedelta(days=lookback_days)

    return SwordRunPlan(
        run_mode=run_mode,
        strategy="date_filtered_county_refresh",
        date_from=date_from,
        date_to=today,
        request_context={
            "platform": source.platform_name,
            "source_name": source.source_name,
            "jurisdiction_name": source.jurisdiction_name,
            "base_url": inspections_url,
            "county_value": county_value,
            "show_partial": True,
            "from_date": date_from.isoformat(),
            "to_date": today.isoformat(),
            "notes": (
                "Date filters narrow fetch scope, but FiScore comparison logic remains the "
                "source of truth for inserts, updates, removals, and versioning."
            ),
        },
    )
