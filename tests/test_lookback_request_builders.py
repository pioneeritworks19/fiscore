from fiscore_backend.models import WorkerRunRequest
from fiscore_backend.ingestion.core.source_registry import SourceRegistryRecord
from fiscore_backend.ingestion.sources.ga_healthinspections.request_builder import (
    build_run_plan as build_ga_run_plan,
)
from fiscore_backend.ingestion.sources.nyc_dohmh.request_builder import (
    build_run_plan as build_nyc_run_plan,
)
from fiscore_backend.ingestion.sources.sword.request_builder import (
    build_run_plan as build_sword_run_plan,
)


def _source_record(*, slug: str, platform_name: str, jurisdiction_name: str, parser_id: str) -> SourceRegistryRecord:
    return SourceRegistryRecord(
        source_id="00000000-0000-0000-0000-000000000001",
        platform_id="00000000-0000-0000-0000-000000000002",
        platform_slug=slug,
        source_slug=slug,
        source_name=slug,
        platform_name=platform_name,
        jurisdiction_name=jurisdiction_name,
        base_url="https://example.com/",
        source_config={},
        parser_id=parser_id,
        parser_version="v1",
    )


def test_ga_request_builder_supports_small_incremental_override() -> None:
    source = _source_record(
        slug="ga_fulton_food_service",
        platform_name="Georgia",
        jurisdiction_name="Georgia - Fulton County",
        parser_id="ga-healthinspections",
    )
    request = WorkerRunRequest(
        source_slug=source.source_slug,
        run_mode="incremental",
        request_context={"lookback_days": 7},
    )

    plan = build_ga_run_plan(source, request)

    assert plan.request_context["lookback_days"] == "7"
    assert plan.strategy == "statewide_county_partition_small_incremental_refresh"


def test_sword_request_builder_supports_small_incremental_override() -> None:
    source = _source_record(
        slug="sword_mi_wayne",
        platform_name="Sword Solutions",
        jurisdiction_name="Wayne County, MI",
        parser_id="sword",
    )
    request = WorkerRunRequest(
        source_slug=source.source_slug,
        run_mode="incremental",
        request_context={"lookback_days": 7},
    )

    plan = build_sword_run_plan(source, request)

    assert plan.request_context["lookback_days"] == "7"
    assert plan.strategy == "date_filtered_small_incremental_refresh"


def test_nyc_request_builder_supports_small_incremental_override() -> None:
    source = _source_record(
        slug="nyc_dohmh_restaurant_inspections",
        platform_name="NYC DOHMH",
        jurisdiction_name="New York City, NY",
        parser_id="nyc-dohmh",
    )
    request = WorkerRunRequest(
        source_slug=source.source_slug,
        run_mode="incremental",
        request_context={"lookback_days": 7},
    )

    plan = build_nyc_run_plan(source, request)

    assert plan.request_context["lookback_days"] == 7
    assert plan.strategy == "small_overlap_window_dataset_refresh"
