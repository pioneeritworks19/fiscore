from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta

from fiscore_backend.ingestion.core.lookback import is_small_incremental_run, resolve_lookback_days
from fiscore_backend.ingestion.core.source_registry import SourceRegistryRecord
from fiscore_backend.models import RunMode, WorkerRunRequest


@dataclass(frozen=True)
class SwordRunPlan:
    run_mode: RunMode
    strategy: str
    date_from: date | None
    date_to: date | None
    request_context: dict[str, str | bool | None]
    city_partitions: tuple[str, ...] | None = None
    target_source_restaurant_keys: tuple[str, ...] | None = None


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


def _resolve_city_partitions(source: SourceRegistryRecord) -> tuple[str, ...] | None:
    configured = source.source_config.get("city_partitions")
    if not isinstance(configured, list):
        return None

    cleaned = tuple(str(value).strip() for value in configured if str(value).strip())
    return cleaned or None


def _resolve_target_source_restaurant_keys(request: WorkerRunRequest) -> tuple[str, ...] | None:
    configured = request.request_context.get("target_source_restaurant_keys")
    if not isinstance(configured, list):
        return None
    cleaned = tuple(str(value).strip() for value in configured if str(value).strip())
    return cleaned or None


def build_run_plan(source: SourceRegistryRecord, request: WorkerRunRequest) -> SwordRunPlan:
    run_mode = request.run_mode
    today = datetime.now(UTC).date()
    inspections_url = _resolve_inspections_url(source.base_url)
    county_value = _resolve_county_value(source.jurisdiction_name)
    city_partitions = _resolve_city_partitions(source)
    target_source_restaurant_keys = _resolve_target_source_restaurant_keys(request)

    if target_source_restaurant_keys:
        return SwordRunPlan(
            run_mode=run_mode,
            strategy="targeted_source_restaurant_refresh",
            date_from=None,
            date_to=None,
            request_context={
                "platform": source.platform_name,
                "source_name": source.source_name,
                "jurisdiction_name": source.jurisdiction_name,
                "base_url": inspections_url,
                "county_value": county_value,
                "show_partial": True,
                "targeted_refresh": True,
                "notes": "Targeted refresh is scoped to explicit source restaurant keys from the admin console.",
            },
            city_partitions=None,
            target_source_restaurant_keys=target_source_restaurant_keys,
        )

    if run_mode == "backfill":
        return SwordRunPlan(
            run_mode=run_mode,
            strategy=(
                "county_partitioned_city_backfill"
                if city_partitions
                else "full_county_no_date_restriction"
            ),
            date_from=None,
            date_to=None,
            request_context={
                "platform": source.platform_name,
                "source_name": source.source_name,
                "jurisdiction_name": source.jurisdiction_name,
                "base_url": inspections_url,
                "county_value": county_value,
                "show_partial": True,
                "notes": (
                    "Backfill mode uses county-scoped city partitions where available to avoid broad-result "
                    "caps on Sword county searches."
                ),
            },
            city_partitions=city_partitions,
            target_source_restaurant_keys=None,
        )

    lookback_days = resolve_lookback_days(
        request=request,
        incremental_default=30,
        reconciliation_default=180,
    )
    date_from = today - timedelta(days=lookback_days)

    return SwordRunPlan(
        run_mode=run_mode,
        strategy=(
            "date_filtered_small_incremental_refresh"
            if is_small_incremental_run(request=request)
            else "date_filtered_county_refresh"
        ),
        date_from=date_from,
        date_to=today,
        request_context={
            "platform": source.platform_name,
            "source_name": source.source_name,
            "jurisdiction_name": source.jurisdiction_name,
            "base_url": inspections_url,
            "county_value": county_value,
            "show_partial": True,
            "lookback_days": str(lookback_days),
            "from_date": date_from.isoformat(),
            "to_date": today.isoformat(),
            "notes": (
                "Date filters narrow fetch scope, but FiScore comparison logic remains the "
                "source of truth for inserts, updates, removals, and versioning."
            ),
        },
        target_source_restaurant_keys=None,
    )
