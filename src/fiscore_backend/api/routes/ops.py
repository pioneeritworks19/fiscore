from __future__ import annotations

from collections import defaultdict
from datetime import datetime
from html import escape
import json
from math import ceil
from urllib.parse import urlencode
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Form, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse

from fiscore_backend.ingestion.core.dispatcher import dispatch_run
from fiscore_backend.models import (
    AdminRestaurantDetail,
    CreateRerunRequest,
    MasterInspectionLineageSummary,
    OpsAlertSummary,
    OpsArtifactDetail,
    OpsArtifactSummary,
    OpsHealthSummary,
    OpsMasterDataQualitySummary,
    OpsMasterFindingSummary,
    OpsMasterInspectionDetail,
    OpsMasterInspectionReportSummary,
    OpsMasterInspectionSummary,
    OpsMasterRestaurantDetail,
    OpsMasterRestaurantSummary,
    OpsParseResultSummary,
    OpsPlatformSummary,
    OpsRerunSummary,
    OpsRunDetail,
    OpsRunSummary,
    OpsSourceSummary,
    SourceVersionSummary,
    TriggerRunRequest,
    WorkerRunRequest,
    WorkerRunResponse,
)
from fiscore_backend.ops.repository import (
    create_rerun_request,
    get_admin_restaurant_detail,
    get_artifact_detail,
    get_health_summary,
    get_master_data_quality_summary,
    get_master_inspection_detail,
    get_master_restaurant_detail,
    get_parse_result_detail,
    get_run_detail,
    list_alerts,
    list_alerts_page,
    list_artifacts,
    list_artifacts_page,
    list_lineage,
    list_lineage_page,
    list_admin_restaurants_page,
    list_master_findings_page,
    list_master_inspections_page,
    list_master_reports_page,
    list_master_restaurants_page,
    list_parse_results,
    list_parse_results_page,
    list_platforms,
    list_reruns,
    list_reruns_page,
    list_runs,
    list_runs_page,
    list_source_versions,
    list_source_versions_page,
    list_sources,
    list_sources_page,
)

router = APIRouter(prefix="/ops", tags=["ops"])

NavItem = tuple[str, str]
NavSection = tuple[str | None, list[NavItem]]
OPS_NAV_SECTIONS: list[NavSection] = [
    (
        "Ingestion",
        [
            ("Platforms", "/ops/control-panel/platforms"),
            ("Sources", "/ops/control-panel/sources"),
            ("Runs", "/ops/control-panel/runs"),
            ("Reruns", "/ops/control-panel/reruns"),
        ],
    ),
    (
        "Data Flow",
        [
            ("Master Data", "/ops/control-panel/master-data"),
            ("Lineage", "/ops/control-panel/lineage"),
            ("Artifacts", "/ops/control-panel/artifacts"),
            ("Parsed", "/ops/control-panel/parse-results"),
            ("Versions", "/ops/control-panel/versions"),
        ],
    ),
    ("Monitoring", [("Health", "/ops/control-panel/health"), ("Alerts", "/ops/control-panel/alerts")]),
]
ADMIN_NAV_SECTIONS: list[NavSection] = [
    (None, [("Restaurants", "/ops/control-panel/admin/restaurants")]),
]
PAGE_SIZE_OPTIONS = (25, 50, 100, 250)
DISPLAY_TIMEZONE = ZoneInfo("America/New_York")


@router.get("/platforms", response_model=list[OpsPlatformSummary])
def get_platforms() -> list[OpsPlatformSummary]:
    return list_platforms()


@router.get("/sources", response_model=list[OpsSourceSummary])
def get_sources(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    platform_slug: str | None = None,
    never_run_only: bool = False,
) -> list[OpsSourceSummary]:
    return list_sources_page(
        page=page,
        page_size=page_size,
        query=q,
        platform_slug=platform_slug,
        never_run_only=never_run_only,
    )[0]


@router.get("/runs", response_model=list[OpsRunSummary])
def get_runs(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    source_slug: str | None = None,
) -> list[OpsRunSummary]:
    return list_runs_page(page=page, page_size=page_size, query=q, source_slug=source_slug)[0]


@router.get("/runs/{scrape_run_id}", response_model=OpsRunDetail)
def get_run(scrape_run_id: str) -> OpsRunDetail:
    detail = get_run_detail(scrape_run_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Run {scrape_run_id} was not found.")
    return detail


@router.get("/artifacts", response_model=list[OpsArtifactSummary])
def get_artifacts(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
) -> list[OpsArtifactSummary]:
    return list_artifacts_page(page=page, page_size=page_size, query=q)[0]


@router.get("/artifacts/{raw_artifact_id}", response_model=OpsArtifactDetail)
def get_artifact(raw_artifact_id: str) -> OpsArtifactDetail:
    detail = get_artifact_detail(raw_artifact_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Artifact {raw_artifact_id} was not found.")
    return detail


@router.get("/parse-results", response_model=list[OpsParseResultSummary])
def get_parse_results(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    record_type: str | None = None,
) -> list[OpsParseResultSummary]:
    return list_parse_results_page(page=page, page_size=page_size, query=q, record_type=record_type)[0]


@router.get("/parse-results/{parse_result_id}", response_model=OpsParseResultSummary)
def get_parse_result(parse_result_id: str) -> OpsParseResultSummary:
    detail = get_parse_result_detail(parse_result_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Parse result {parse_result_id} was not found.")
    return detail


@router.get("/alerts", response_model=list[OpsAlertSummary])
def get_alerts(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
) -> list[OpsAlertSummary]:
    return list_alerts_page(page=page, page_size=page_size, query=q)[0]


@router.get("/health", response_model=OpsHealthSummary)
def get_health() -> OpsHealthSummary:
    return get_health_summary()


@router.get("/reruns", response_model=list[OpsRerunSummary])
def get_reruns(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
) -> list[OpsRerunSummary]:
    return list_reruns_page(page=page, page_size=page_size, query=q)[0]


@router.post("/reruns", response_model=OpsRerunSummary)
def create_rerun(request: CreateRerunRequest) -> OpsRerunSummary:
    try:
        return create_rerun_request(request)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/lineage", response_model=list[MasterInspectionLineageSummary])
def get_lineage(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
) -> list[MasterInspectionLineageSummary]:
    return list_lineage_page(page=page, page_size=page_size, query=q)[0]


@router.get("/master-data/summary", response_model=OpsMasterDataQualitySummary)
def get_master_data_summary() -> OpsMasterDataQualitySummary:
    return get_master_data_quality_summary()


@router.get("/master-data/restaurants", response_model=list[OpsMasterRestaurantSummary])
def get_master_restaurants(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    source_slug: str | None = None,
    quality_filter: str | None = None,
) -> list[OpsMasterRestaurantSummary]:
    return list_master_restaurants_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        quality_filter=quality_filter,
    )[0]


@router.get("/master-data/restaurants/{master_restaurant_id}", response_model=OpsMasterRestaurantDetail)
def get_master_restaurant(master_restaurant_id: str) -> OpsMasterRestaurantDetail:
    detail = get_master_restaurant_detail(master_restaurant_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Master restaurant {master_restaurant_id} was not found.")
    return detail


@router.get("/master-data/inspections", response_model=list[OpsMasterInspectionSummary])
def get_master_inspections(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    source_slug: str | None = None,
    report_status: str | None = None,
    scrape_run_id: str | None = None,
) -> list[OpsMasterInspectionSummary]:
    return list_master_inspections_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        report_status=report_status,
        scrape_run_id=scrape_run_id,
    )[0]


@router.get("/master-data/inspections/{master_inspection_id}", response_model=OpsMasterInspectionDetail)
def get_master_inspection(master_inspection_id: str) -> OpsMasterInspectionDetail:
    detail = get_master_inspection_detail(master_inspection_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Master inspection {master_inspection_id} was not found.")
    return detail


@router.get("/master-data/reports", response_model=list[OpsMasterInspectionReportSummary])
def get_master_reports(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    source_slug: str | None = None,
    availability_status: str | None = None,
    missing_storage_only: bool = False,
) -> list[OpsMasterInspectionReportSummary]:
    return list_master_reports_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        availability_status=availability_status,
        missing_storage_only=missing_storage_only,
    )[0]


@router.get("/master-data/findings", response_model=list[OpsMasterFindingSummary])
def get_master_findings(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    source_slug: str | None = None,
    missing_detail_only: bool = False,
) -> list[OpsMasterFindingSummary]:
    return list_master_findings_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        missing_detail_only=missing_detail_only,
    )[0]


@router.get("/admin/restaurants", response_model=list[OpsMasterRestaurantSummary])
def get_admin_restaurants(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
    state_code: str | None = None,
    city: str | None = None,
    status: str | None = None,
    source_slug: str | None = None,
    has_inspections: bool | None = None,
) -> list[OpsMasterRestaurantSummary]:
    return list_admin_restaurants_page(
        page=page,
        page_size=page_size,
        query=q,
        state_code=state_code,
        city=city,
        status=status,
        source_slug=source_slug,
        has_inspections=has_inspections,
    )[0]


@router.get("/admin/restaurants/{master_restaurant_id}", response_model=AdminRestaurantDetail)
def get_admin_restaurant(master_restaurant_id: str) -> AdminRestaurantDetail:
    detail = get_admin_restaurant_detail(master_restaurant_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Admin restaurant {master_restaurant_id} was not found.")
    return detail


@router.get("/versions", response_model=list[SourceVersionSummary])
def get_versions(
    q: str | None = None,
    page: int = 1,
    page_size: int = 100,
) -> list[SourceVersionSummary]:
    return list_source_versions_page(page=page, page_size=page_size, query=q)[0]


@router.post("/sources/{source_slug}/runs", response_model=WorkerRunResponse)
def trigger_run(source_slug: str, request: TriggerRunRequest) -> WorkerRunResponse:
    return dispatch_run(
        WorkerRunRequest(
            source_slug=source_slug,
            run_mode=request.run_mode,
            trigger_type="manual",
        )
    )


def _build_url(path: str, **params: object) -> str:
    cleaned = {}
    for key, value in params.items():
        if value is None:
            continue
        if isinstance(value, str) and not value.strip():
            continue
        cleaned[key] = value
    if not cleaned:
        return path
    return f"{path}?{urlencode(cleaned)}"


def _nav_html(active_path: str, *, workspace: str) -> str:
    overview_active = active_path == "/ops/control-panel"
    ops_expanded = workspace == "ops"
    admin_expanded = workspace == "admin"

    ops_children: list[str] = []
    for _, items in OPS_NAV_SECTIONS:
        for label, href in items:
            active = "active" if (active_path == href or active_path.startswith(f"{href}/")) else ""
            ops_children.append(f'<a class="tree-child {active}" href="{href}">{escape(label)}</a>')

    admin_children: list[str] = []
    for _, items in ADMIN_NAV_SECTIONS:
        for label, href in items:
            active = "active" if (active_path == href or active_path.startswith(f"{href}/")) else ""
            admin_children.append(f'<a class="tree-child {active}" href="{href}">{escape(label)}</a>')

    ops_parent_class = "tree-parent active" if ops_expanded else "tree-parent"
    admin_parent_class = "tree-parent active" if admin_expanded else "tree-parent"
    overview_class = "tree-root active" if overview_active else "tree-root"
    ops_children_html = f"<div class='tree-children'>{''.join(ops_children)}</div>" if ops_expanded else ""
    admin_children_html = (
        f"<div class='tree-children tree-children-admin'>{''.join(admin_children)}</div>" if admin_expanded else ""
    )

    return (
        f"<a class='{overview_class}' href='/ops/control-panel'>Overview</a>"
        f"<div class='tree-group'>"
        f"<a class='{ops_parent_class}' href='/ops/control-panel/platforms'>Ops</a>"
        f"{ops_children_html}"
        f"</div>"
        f"<div class='tree-group'>"
        f"<a class='{admin_parent_class}' href='/ops/control-panel/admin/restaurants'>Admin</a>"
        f"{admin_children_html}"
        f"</div>"
    )


def _workspace_copy(workspace: str) -> tuple[str, str]:
    return ("FiScore", "Internal console for operations, master data diagnostics, and restaurant administration.")


def _badge_class(status: str | None) -> str:
    if status is None:
        return "badge"
    lowered = status.lower()
    if "fail" in lowered or "error" in lowered or "stale" in lowered:
        return "badge fail"
    if "warn" in lowered or "queue" in lowered or "running" in lowered or "pending" in lowered:
        return "badge warn"
    if "healthy" in lowered or "complete" in lowered or "active" in lowered or "matched" in lowered or "available" in lowered:
        return "badge ok"
    return "badge"


def _pretty(value: object) -> str:
    return escape(json.dumps(value, indent=2, default=str))


def _display(value: object | None) -> str:
    if isinstance(value, datetime):
        localized = value.astimezone(DISPLAY_TIMEZONE)
        return escape(localized.strftime("%Y-%m-%d %I:%M:%S %p ET"))
    return escape(str(value)) if value not in (None, "") else "&mdash;"


def _display_date_compact(value: object | None) -> str:
    if value in (None, ""):
        return "&mdash;"
    return escape(str(value))


def _title_case_slug(value: str | None) -> str:
    if not value:
        return "Unknown"
    return " ".join(part.capitalize() for part in value.replace("_", " ").replace("-", " ").split())


def _inspection_result_label(inspection: OpsMasterInspectionSummary) -> str:
    for candidate in (inspection.official_status, inspection.grade):
        if candidate:
            return candidate
    return "Recorded"


def _severity_sort_key(value: str | None) -> int:
    normalized = (value or "").strip().lower()
    order = {"critical": 0, "major": 1, "minor": 2}
    return order.get(normalized, 3)


def _truncate_middle(value: str, *, max_length: int = 72) -> str:
    if len(value) <= max_length:
        return value
    keep = max((max_length - 3) // 2, 8)
    return f"{value[:keep]}...{value[-keep:]}"


def _latest_badge(index: int) -> str:
    return " <span class='badge ok'>Latest</span>" if index == 0 else ""


def _meta_text(value: str) -> str:
    return f"<span class='meta-text'>{escape(value)}</span>"


def _source_runs_link(source_slug: str, source_name: str) -> str:
    return (
        f"<a href='/ops/control-panel/runs?source_slug={escape(source_slug)}'>"
        f"{escape(source_name)}</a>"
    )


def _run_tab_link(scrape_run_id: str, tab: str, label: str, *, active_tab: str) -> str:
    active = "active" if tab == active_tab else ""
    href = _build_url(f"/ops/control-panel/runs/{scrape_run_id}", tab=tab)
    return f"<a class='subtab {active}' href='{href}'>{escape(label)}</a>"


def _sorted_hint(label: str = "Newest first. Times shown in America/New_York.") -> str:
    return f"<div class='muted sorted-hint'>{escape(label)}</div>"


def _compact_link(value: str, *, href: str | None = None, max_length: int = 76) -> str:
    display_value = _truncate_middle(value, max_length=max_length)
    target = href or value
    return (
        f"<a class='compact-link' href='{escape(target)}' title='{escape(value)}'>"
        f"{escape(display_value)}</a>"
    )


def _compact_text(value: str, *, max_length: int = 76) -> str:
    display_value = _truncate_middle(value, max_length=max_length)
    return f"<span class='compact-text' title='{escape(value)}'>{escape(display_value)}</span>"


def _compact_message(value: str, *, max_length: int = 140) -> str:
    cleaned = " ".join(value.split())
    if len(cleaned) <= max_length:
        return escape(cleaned)
    preview = escape(cleaned[:max_length].rstrip() + "...")
    full = escape(cleaned)
    return (
        "<details class='cell-disclosure'>"
        f"<summary>{preview}</summary>"
        f"<div class='cell-disclosure-body'>{full}</div>"
        "</details>"
    )


def _table(headers: list[str], rows: list[str], *, empty_message: str, colspan: int | None = None) -> str:
    head_html = "".join(f"<th>{escape(header)}</th>" for header in headers)
    if not rows:
        cols = colspan or len(headers)
        rows_html = f'<tr><td colspan="{cols}" class="muted">{escape(empty_message)}</td></tr>'
    else:
        rows_html = "".join(rows)
    return f"<table><thead><tr>{head_html}</tr></thead><tbody>{rows_html}</tbody></table>"


def _summary_line(*, page: int, page_size: int, total_count: int) -> str:
    if total_count == 0:
        return '<div class="muted">0 records</div>'
    start = (page - 1) * page_size + 1
    end = min(page * page_size, total_count)
    return f'<div class="muted">Showing {start}-{end} of {total_count} records</div>'


def _pagination_controls(path: str, *, page: int, page_size: int, total_count: int, **query_params: object) -> str:
    total_pages = max(ceil(total_count / page_size), 1) if page_size else 1
    prev_url = _build_url(path, page=page - 1, page_size=page_size, **query_params) if page > 1 else None
    next_url = _build_url(path, page=page + 1, page_size=page_size, **query_params) if page < total_pages else None
    prev_button = (
        f'<a class="button secondary" href="{prev_url}">Previous</a>' if prev_url else '<span class="button secondary disabled">Previous</span>'
    )
    next_button = (
        f'<a class="button secondary" href="{next_url}">Next</a>' if next_url else '<span class="button secondary disabled">Next</span>'
    )
    return f"""
    <div class="pager">
      {_summary_line(page=page, page_size=page_size, total_count=total_count)}
      <div class="actions">
        {prev_button}
        <span class="badge">Page {page} of {total_pages}</span>
        {next_button}
      </div>
    </div>
    """


def _search_form(
    path: str,
    *,
    q: str | None,
    page_size: int,
    placeholder: str,
    extra_fields: str = "",
) -> str:
    options = "".join(
        f"<option value='{size}' {'selected' if size == page_size else ''}>{size} / page</option>"
        for size in PAGE_SIZE_OPTIONS
    )
    return f"""
    <form method="get" action="{path}" class="toolbar-form">
      <input class="control-grow" type="search" name="q" value="{escape(q or '')}" placeholder="{escape(placeholder)}" />
      <select class="control-compact" name="page_size">{options}</select>
      {extra_fields}
      <button type="submit">Apply</button>
      <a class="button secondary" href="{path}">Clear</a>
    </form>
    """


def _platform_filter_select(current: str | None) -> str:
    options = ['<option value="">All platforms</option>']
    for platform in list_platforms():
        selected = "selected" if platform.platform_slug == current else ""
        options.append(
            f"<option value='{escape(platform.platform_slug)}' {selected}>{escape(platform.platform_name)}</option>"
        )
    return f"<select name='platform_slug'>{''.join(options)}</select>"


def _source_filter_select(current: str | None) -> str:
    options = ['<option value="">All sources</option>']
    for source in list_sources(limit=250):
        selected = "selected" if source.source_slug == current else ""
        options.append(
            f"<option value='{escape(source.source_slug)}' {selected}>{escape(source.source_name)} ({escape(source.source_slug)})</option>"
        )
    return f"<select name='source_slug'>{''.join(options)}</select>"


def _checkbox_field(*, name: str, label: str, checked: bool) -> str:
    return (
        f"<label class='filter-toggle'>"
        f"<input type='checkbox' name='{escape(name)}' value='true' {'checked' if checked else ''} />"
        f"<span>{escape(label)}</span>"
        f"</label>"
    )


def _control_panel_shell(body_html: str, *, title: str, active_path: str, workspace: str = "ops") -> str:
    brand_title, brand_copy = _workspace_copy(workspace)
    return f"""<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{escape(title)}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
      :root {{
        --bg: #eef5fb;
        --surface: #ffffff;
        --surface-2: #f6faff;
        --surface-3: #edf4fb;
        --ink: #112031;
        --muted: #5d6f82;
        --line: #d7e4f2;
        --line-strong: #bed1e3;
        --accent: #0d6efd;
        --accent-2: #073b8a;
        --accent-soft: #e7f1ff;
        --shadow: rgba(21, 56, 99, 0.08);
      }}
      * {{ box-sizing: border-box; }}
      body {{
        margin: 0;
        font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
        color: var(--ink);
        background:
          radial-gradient(circle at top right, rgba(0, 171, 228, 0.18), transparent 24%),
          radial-gradient(circle at top left, rgba(13, 110, 253, 0.12), transparent 20%),
          linear-gradient(180deg, #f7fbff 0%, #edf4fb 100%);
      }}
      a {{ color: var(--accent); text-decoration: none; }}
      a:hover {{ text-decoration: underline; }}
      .layout {{
        display: grid;
        grid-template-columns: 280px minmax(0, 1fr);
        min-height: 100vh;
      }}
      .sidebar {{
        position: sticky;
        top: 0;
        align-self: start;
        height: 100vh;
        padding: 32px 20px;
        border-right: 1px solid var(--line);
        background:
          linear-gradient(180deg, rgba(10, 27, 47, 0.96) 0%, rgba(14, 41, 72, 0.94) 100%);
        box-shadow: 14px 0 32px rgba(10, 31, 54, 0.08);
      }}
      .brand {{
        margin-bottom: 22px;
      }}
      .brand h1 {{
        margin: 0;
        font-size: 1.95rem;
        letter-spacing: -0.03em;
        color: #f8fbff;
      }}
      .brand p {{
        margin: 10px 0 0;
        color: rgba(225, 236, 249, 0.78);
        line-height: 1.6;
        max-width: 210px;
      }}
      .nav {{
        display: grid;
        gap: 12px;
        margin-top: 18px;
      }}
      .tree-root,
      .tree-parent {{
        display: block;
        padding: 10px 14px;
        border-radius: 12px;
        color: rgba(232, 241, 250, 0.9);
        font-weight: 700;
        text-decoration: none;
      }}
      .tree-root.active,
      .tree-parent.active {{
        background: linear-gradient(135deg, rgba(231, 241, 255, 0.14) 0%, rgba(0, 171, 228, 0.12) 100%);
        border: 1px solid rgba(141, 192, 255, 0.32);
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.06);
      }}
      .tree-group {{
        display: grid;
        gap: 8px;
      }}
      .tree-children {{
        display: grid;
        gap: 6px;
        margin-left: 12px;
        padding: 4px 0 0 10px;
      }}
      .tree-children-admin {{
        padding-top: 2px;
      }}
      .tree-child {{
        display: block;
        padding: 8px 12px;
        border-radius: 10px;
        color: rgba(220, 233, 246, 0.84);
        font-weight: 500;
        text-decoration: none;
      }}
      .tree-child.active {{
        background: linear-gradient(135deg, rgba(231, 241, 255, 0.18) 0%, rgba(0, 171, 228, 0.16) 100%);
        border-color: rgba(141, 192, 255, 0.42);
        color: #ffffff;
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
      }}
      .tree-root:hover,
      .tree-child:hover {{
        text-decoration: none;
        background: rgba(255, 255, 255, 0.05);
      }}
      .main {{
        padding: 32px 30px 64px;
      }}
      .hero {{
        display: flex;
        justify-content: space-between;
        align-items: end;
        gap: 16px;
        margin-bottom: 26px;
      }}
      .hero h1 {{
        margin: 0;
        font-size: 2.4rem;
        letter-spacing: -0.045em;
        color: #0d2038;
      }}
      .hero p {{
        margin: 10px 0 0;
        color: var(--muted);
        max-width: 780px;
        line-height: 1.65;
      }}
      .grid {{ display: grid; gap: 18px; }}
      .grid.two {{ grid-template-columns: 1fr 1fr; }}
      .grid.three {{ grid-template-columns: repeat(3, 1fr); }}
      .panel {{
        background: rgba(255, 255, 255, 0.96);
        border: 1px solid var(--line);
        border-radius: 20px;
        padding: 22px;
        box-shadow: 0 18px 38px var(--shadow);
      }}
      .platform-card {{
        display: grid;
        gap: 14px;
      }}
      .platform-card h3 {{
        margin: 0;
      }}
      .panel h2 {{
        margin: 0 0 14px;
        font-size: 1.08rem;
        font-weight: 700;
        color: #153556;
      }}
      .panel h3 {{
        margin: 0 0 10px;
        font-size: 1rem;
        font-weight: 700;
        color: #153556;
      }}
      table {{
        width: 100%;
        border-collapse: collapse;
        font-size: 0.94rem;
        table-layout: fixed;
      }}
      thead th {{
        position: sticky;
        top: 0;
        z-index: 2;
        background: rgba(255, 255, 255, 0.98);
        backdrop-filter: blur(6px);
      }}
      th, td {{
        padding: 12px 8px;
        border-bottom: 1px solid #e7eef7;
        text-align: left;
        vertical-align: top;
        overflow-wrap: anywhere;
      }}
      th {{
        font-size: 0.8rem;
        color: #59708c;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        font-weight: 700;
      }}
      .badge {{
        display: inline-block;
        padding: 5px 11px;
        border-radius: 999px;
        border: 1px solid var(--line);
        background: #f8fbff;
        font-size: 0.8rem;
        font-weight: 600;
      }}
      .badge.ok {{ color: #0f6a3c; border-color: #a6debf; background: #edf9f2; }}
      .badge.warn {{ color: #8b5e1f; border-color: #e4c081; background: #fff7e8; }}
      .badge.fail {{ color: #9a2d3f; border-color: #e2adbb; background: #fff1f4; }}
      .badge.repeat {{ color: #97263a; border-color: #e2adbb; background: #fff1f4; }}
      .badge.corrected {{ color: #0f6a3c; border-color: #a6debf; background: #edf9f2; }}
      .badge.severity-critical {{ color: #9a2d3f; border-color: #e2adbb; background: #fff1f4; }}
      .badge.severity-major {{ color: #8b5e1f; border-color: #e4c081; background: #fff7e8; }}
      .badge.severity-minor {{ color: #255f9d; border-color: #b9d1ef; background: #eef5ff; }}
      .button.disabled {{
        cursor: default;
        opacity: 0.45;
        text-decoration: none;
      }}
      .muted {{ color: var(--muted); }}
      .meta-text {{
        display: inline-block;
        margin-top: 4px;
        color: #74879b;
        font-size: 0.86rem;
        font-weight: 500;
        letter-spacing: 0.01em;
      }}
      .stat {{
        padding: 18px;
        border-radius: 18px;
        background: linear-gradient(180deg, var(--surface) 0%, var(--surface-2) 100%);
        border: 1px solid var(--line);
      }}
      .stat .value {{
        display: block;
        font-size: 1.9rem;
        font-weight: 700;
        margin-bottom: 6px;
        color: #123c74;
      }}
      .actions {{
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        align-items: center;
      }}
      button, .button {{
        border: 0;
        border-radius: 999px;
        background: linear-gradient(135deg, var(--accent) 0%, #009fe3 100%);
        color: white;
        padding: 11px 17px;
        font: inherit;
        font-weight: 600;
        cursor: pointer;
        text-decoration: none;
        box-shadow: 0 10px 22px rgba(0, 110, 253, 0.18);
      }}
      button.secondary, .button.secondary {{
        background: linear-gradient(135deg, #51657d 0%, #6f849b 100%);
        box-shadow: none;
      }}
      pre {{
        white-space: pre-wrap;
        word-break: break-word;
        background: #f6faff;
        border: 1px solid #dce9f6;
        border-radius: 14px;
        padding: 14px;
        font-size: 0.88rem;
      }}
      .stack > * + * {{ margin-top: 12px; }}
      form.inline {{
        display: inline-flex;
        gap: 8px;
        align-items: center;
        flex-wrap: wrap;
      }}
      .run-form {{
        display: inline-flex;
        gap: 8px;
        align-items: center;
        justify-content: flex-end;
        flex-wrap: nowrap;
        width: 100%;
      }}
      .run-form select {{
        min-width: 170px;
        max-width: 190px;
      }}
      .run-form button {{
        padding: 9px 14px;
        min-width: 64px;
        white-space: nowrap;
      }}
      .action-cell {{
        white-space: nowrap;
      }}
      .toolbar {{
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 14px;
        gap: 10px;
        flex-wrap: wrap;
      }}
      .toolbar-form {{
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
        align-items: center;
        width: 100%;
      }}
      .toolbar-form .control-grow {{
        flex: 1 1 280px;
        min-width: 240px;
      }}
      .toolbar-form .control-compact {{
        width: auto;
        min-width: 138px;
      }}
      .filter-toggle {{
        display: inline-flex;
        align-items: center;
        gap: 8px;
        min-height: 42px;
        padding: 0 12px;
        border: 1px solid var(--line);
        border-radius: 12px;
        background: #fff;
        color: var(--muted);
        font-size: 0.92rem;
        font-weight: 600;
        white-space: nowrap;
      }}
      .filter-toggle input {{
        width: auto;
        margin: 0;
        padding: 0;
        box-shadow: none;
      }}
      input, select, textarea {{
        width: 100%;
        border: 1px solid var(--line);
        border-radius: 12px;
        background: #fff;
        color: var(--ink);
        padding: 9px 12px;
        font: inherit;
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.6);
      }}
      input:focus, select:focus, textarea:focus {{
        outline: none;
        border-color: #8fc0ff;
        box-shadow: 0 0 0 4px rgba(13, 110, 253, 0.12);
      }}
      input[type="search"] {{
        min-width: 260px;
        flex: 1 1 280px;
      }}
      textarea {{ min-height: 96px; resize: vertical; }}
      .pager {{
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 10px;
        margin: 10px 0;
        flex-wrap: wrap;
      }}
      .pager .actions {{
        display: inline-flex;
        align-items: center;
        gap: 8px;
        flex-wrap: wrap;
      }}
      .pager .button,
      .toolbar-form button,
      .toolbar-form .button {{
        padding: 9px 14px;
      }}
      .chip-row {{
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
      }}
      .chip {{
        display: inline-flex;
        padding: 6px 10px;
        border-radius: 999px;
        border: 1px solid var(--line);
        background: #fff;
        color: var(--muted);
        font-size: 0.84rem;
      }}
      .sorted-hint {{
        margin: 0 0 10px;
        font-size: 0.9rem;
      }}
      .latest-row td {{
        background: rgba(231, 241, 255, 0.72);
      }}
      .compact-link, .compact-text {{
        display: inline-block;
        max-width: 100%;
        white-space: normal;
        overflow-wrap: anywhere;
        word-break: break-word;
      }}
      .mono {{
        font-family: "Cascadia Code", Consolas, monospace;
        font-size: 0.88rem;
      }}
      .table-tight th:nth-child(1) {{ width: 13%; }}
      .table-tight th:nth-child(2) {{ width: 10%; }}
      .table-tight th:nth-child(3) {{ width: 10%; }}
      .table-tight th:nth-child(4) {{ width: 15%; }}
      .table-tight th:nth-child(5) {{ width: 8%; }}
      .table-tight th:nth-child(6) {{ width: 8%; }}
      .table-tight th:nth-child(7) {{ width: 10%; }}
      .table-tight th:nth-child(8) {{ width: 8%; }}
      .table-tight th:nth-child(9) {{ width: 8%; }}
      .table-tight th:nth-child(10) {{ width: 18%; }}
      .table-artifacts th:nth-child(1) {{ width: 10%; }}
      .table-artifacts th:nth-child(2) {{ width: 8%; }}
      .table-artifacts th:nth-child(3) {{ width: 36%; }}
      .table-artifacts th:nth-child(4) {{ width: 28%; }}
      .table-artifacts th:nth-child(5) {{ width: 18%; }}
      .table-issues th:nth-child(1) {{ width: 8%; }}
      .table-issues th:nth-child(2) {{ width: 10%; }}
      .table-issues th:nth-child(3) {{ width: 13%; }}
      .table-issues th:nth-child(4) {{ width: 37%; }}
      .table-issues th:nth-child(5) {{ width: 10%; }}
      .table-issues th:nth-child(6) {{ width: 10%; }}
      .table-issues th:nth-child(7) {{ width: 12%; }}
      .cell-disclosure {{
        display: block;
      }}
      .cell-disclosure summary {{
        cursor: pointer;
        list-style: none;
        color: #2a4765;
      }}
      .cell-disclosure summary::-webkit-details-marker {{
        display: none;
      }}
      .cell-disclosure-body {{
        margin-top: 8px;
        color: var(--muted);
        line-height: 1.55;
      }}
      .summary-strip {{
        display: grid;
        grid-template-columns: 1.2fr repeat(4, minmax(120px, 0.7fr));
        gap: 14px;
        margin-bottom: 18px;
      }}
      .summary-card {{
        border: 1px solid var(--line);
        background: linear-gradient(180deg, var(--surface) 0%, var(--surface-2) 100%);
        border-radius: 18px;
        padding: 16px 18px;
      }}
      .summary-card h3 {{
        margin: 0 0 8px;
        font-size: 0.82rem;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: #68809a;
      }}
      .summary-card .big {{
        display: block;
        font-size: 1.5rem;
        font-weight: 700;
        color: #123c74;
      }}
      .summary-card .small {{
        margin-top: 6px;
        color: var(--muted);
        font-size: 0.9rem;
        line-height: 1.5;
      }}
      .restaurant-hero {{
        align-items: start;
      }}
      .hero-kicker {{
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 6px 12px;
        border-radius: 999px;
        background: var(--accent-soft);
        color: #204a7a;
        font-size: 0.8rem;
        font-weight: 700;
        letter-spacing: 0.05em;
        text-transform: uppercase;
      }}
      .hero-meta {{
        display: flex;
        flex-wrap: wrap;
        gap: 10px 18px;
        margin-top: 14px;
        color: var(--muted);
      }}
      .hero-meta span {{
        display: inline-flex;
        align-items: center;
        gap: 8px;
      }}
      .grade-ring {{
        min-width: 108px;
        min-height: 108px;
        padding: 12px;
        border-radius: 999px;
        border: 4px solid #27a17a;
        background: rgba(240, 252, 247, 0.96);
        color: #16674d;
        display: grid;
        place-items: center;
        text-align: center;
      }}
      .grade-ring .letter {{
        font-size: 2rem;
        font-weight: 700;
        line-height: 1;
      }}
      .grade-ring .caption {{
        font-size: 0.72rem;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }}
      .overview-facts {{
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 16px 22px;
      }}
      .fact-label {{
        color: #5a718c;
        font-size: 0.76rem;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        margin-bottom: 4px;
      }}
      .fact-value {{
        color: #10243d;
        line-height: 1.45;
      }}
      .severity-legend {{
        display: flex;
        gap: 18px;
        flex-wrap: wrap;
        margin-bottom: 16px;
        color: #4f647b;
      }}
      .severity-legend-item,
      .severity-inline {{
        display: inline-flex;
        align-items: center;
        gap: 8px;
      }}
      .severity-dot {{
        width: 9px;
        height: 9px;
        border-radius: 999px;
        background: #90a4b7;
        display: inline-block;
        flex: 0 0 auto;
      }}
      .severity-dot.critical {{ background: #df4f55; }}
      .severity-dot.major {{ background: #f0a02b; }}
      .severity-dot.minor {{ background: #4d88d1; }}
      .inspection-history {{
        display: grid;
        gap: 16px;
      }}
      .inspection-card {{
        border: 1px solid var(--line);
        border-radius: 18px;
        background: linear-gradient(180deg, rgba(255, 255, 255, 0.98) 0%, rgba(249, 252, 255, 0.98) 100%);
        overflow: hidden;
      }}
      .inspection-card summary {{
        list-style: none;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 14px;
        padding: 18px 22px;
      }}
      .inspection-card summary::-webkit-details-marker {{ display: none; }}
      .inspection-card[open] summary {{
        border-bottom: 1px solid var(--line);
      }}
      .inspection-card-title {{
        font-size: 1.08rem;
        font-weight: 700;
        color: #11263d;
      }}
      .inspection-card-subtitle {{
        margin-top: 4px;
        color: #4f647b;
        font-size: 0.84rem;
        letter-spacing: 0.06em;
        text-transform: uppercase;
      }}
      .inspection-card-right {{
        display: flex;
        align-items: center;
        gap: 12px;
        flex-wrap: wrap;
        justify-content: flex-end;
        text-align: right;
      }}
      .inspection-card-body {{
        padding: 18px 22px 22px;
        display: grid;
        gap: 14px;
      }}
      .inspection-meta {{
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
      }}
      .info-chip {{
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 6px 10px;
        border-radius: 999px;
        background: #f4f8fc;
        border: 1px solid var(--line);
        color: #526779;
        font-size: 0.82rem;
        font-weight: 600;
      }}
      .finding-list {{
        display: grid;
        gap: 14px;
      }}
      .finding-item + .finding-item {{
        border-top: 1px solid #e6eef7;
        padding-top: 14px;
      }}
      .finding-header {{
        display: flex;
        align-items: center;
        gap: 10px;
        flex-wrap: wrap;
        margin-bottom: 8px;
      }}
      .finding-code {{
        color: #4f647b;
        font-size: 0.82rem;
        letter-spacing: 0.06em;
        text-transform: uppercase;
      }}
      .finding-title {{
        font-size: 1rem;
        font-weight: 600;
        color: #132944;
        margin-bottom: 8px;
      }}
      .finding-block {{
        color: #21364c;
        line-height: 1.6;
      }}
      .finding-block + .finding-block {{
        margin-top: 10px;
      }}
      .finding-block-label {{
        display: block;
        margin-bottom: 3px;
        color: #5a718c;
        font-size: 0.74rem;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }}
      .finding-flags {{
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
        margin-top: 10px;
      }}
      .source-grid {{
        display: grid;
        gap: 18px;
      }}
      .run-tabs {{
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        margin: 0 0 18px;
      }}
      .subtab {{
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 10px 16px;
        border-radius: 999px;
        border: 1px solid var(--line);
        background: rgba(255, 255, 255, 0.92);
        color: #36526e;
        font-weight: 600;
        text-decoration: none;
      }}
      .subtab.active {{
        color: #ffffff;
        border-color: rgba(9, 91, 201, 0.25);
        background: linear-gradient(135deg, var(--accent) 0%, #009fe3 100%);
        box-shadow: 0 10px 22px rgba(0, 110, 253, 0.18);
      }}
      .subtab:hover {{
        text-decoration: none;
      }}
      .inspection-stack {{
        display: grid;
        gap: 14px;
      }}
      .inspection-expander {{
        border: 1px solid var(--line);
        border-radius: 16px;
        background: #fbfdff;
        overflow: hidden;
      }}
      .inspection-expander summary {{
        cursor: pointer;
        list-style: none;
        padding: 16px 18px;
        font-weight: 700;
        color: #153556;
      }}
      .inspection-expander summary::-webkit-details-marker {{
        display: none;
      }}
      .inspection-expander[open] summary {{
        border-bottom: 1px solid var(--line);
        background: var(--surface-2);
      }}
      .inspection-expander-body {{
        padding: 16px 18px 18px;
      }}
      .issue-summary-grid {{
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 12px;
        margin-bottom: 16px;
      }}
      .issue-summary-card {{
        border: 1px solid var(--line);
        border-radius: 16px;
        padding: 14px 16px;
        background: #fbfdff;
      }}
      .issue-summary-card .label {{
        display: block;
        color: #68809a;
        font-size: 0.82rem;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        margin-bottom: 6px;
      }}
      .issue-summary-card .count {{
        font-size: 1.25rem;
        font-weight: 700;
        color: #123c74;
      }}
      .context-accordion {{
        display: grid;
        gap: 12px;
      }}
      details.disclosure {{
        border: 1px solid var(--line);
        border-radius: 16px;
        background: rgba(255, 255, 255, 0.98);
        overflow: hidden;
      }}
      details.disclosure summary {{
        cursor: pointer;
        list-style: none;
        padding: 16px 18px;
        font-weight: 700;
        color: #153556;
      }}
      details.disclosure summary::-webkit-details-marker {{
        display: none;
      }}
      details.disclosure[open] summary {{
        border-bottom: 1px solid var(--line);
        background: var(--surface-2);
      }}
      details.disclosure .disclosure-body {{
        padding: 16px 18px 18px;
      }}
      @media (max-width: 1020px) {{
        .layout {{ grid-template-columns: 1fr; }}
        .sidebar {{
          position: static;
          height: auto;
          border-right: 0;
          border-bottom: 1px solid var(--line);
        }}
        .grid.two, .grid.three {{ grid-template-columns: 1fr; }}
        .summary-strip {{ grid-template-columns: 1fr; }}
        .overview-facts {{ grid-template-columns: 1fr; }}
        .inspection-card summary {{
          align-items: start;
          flex-direction: column;
        }}
        .inspection-card-right {{
          justify-content: flex-start;
          text-align: left;
        }}
      }}
    </style>
  </head>
  <body>
    <div class="layout">
      <aside class="sidebar">
        <div class="brand">
          <h1>{escape(brand_title)}</h1>
          <p>{escape(brand_copy)}</p>
        </div>
        <nav class="nav">
          {_nav_html(active_path, workspace=workspace)}
        </nav>
      </aside>
      <main class="main">
        {body_html}
      </main>
    </div>
  </body>
</html>"""


def _overview_page() -> str:
    health = get_health_summary()
    master_summary = get_master_data_quality_summary()
    platforms = list_platforms()
    sources = list_sources(limit=12)
    runs = list_runs(limit=12)
    body = f"""
    <section class="hero">
      <div>
        <h1>Overview</h1>
        <p>Shared landing page for operations and administration. Jump into the Ops workspace to manage ingestion, or into Admin to browse restaurants across the database.</p>
      </div>
      <div class="actions">
        <a class="button secondary" href="/ops/control-panel/platforms">Open Ops</a>
        <a class="button secondary" href="/ops/control-panel/admin/restaurants">Open Admin</a>
        <a class="button secondary" href="/ops/control-panel">Refresh</a>
      </div>
    </section>
    <section class="grid three">
      <div class="stat"><span class="value">{health.total_platforms}</span><span class="muted">Registered platforms</span></div>
      <div class="stat"><span class="value">{health.total_sources}</span><span class="muted">Registered sources</span></div>
      <div class="stat"><span class="value">{health.open_alert_count}</span><span class="muted">Open alerts</span></div>
      <div class="stat"><span class="value">{master_summary.total_restaurants}</span><span class="muted">Master restaurants</span></div>
      <div class="stat"><span class="value">{master_summary.total_inspections}</span><span class="muted">Normalized inspections</span></div>
      <div class="stat"><span class="value">{master_summary.duplicate_risk_restaurants}</span><span class="muted">Duplicate-risk restaurants</span></div>
    </section>
    <section class="grid two" style="margin-top:18px;">
      <section class="panel">
        <h2>Ops Snapshot</h2>
        {_table(
            ["Platform", "Sources", "Healthy", "Warnings", "Stale", "Latest success"],
            [
                f"<tr><td><a href='/ops/control-panel/sources?platform_slug={escape(p.platform_slug)}'>{escape(p.platform_name)}</a></td><td>{p.source_count}</td><td>{p.healthy_source_count}</td><td>{p.warning_source_count}</td><td>{p.stale_source_count}</td><td>{_display(p.latest_success_at)}</td></tr>"
                for p in platforms[:8]
            ],
            empty_message="No platforms registered yet."
        )}
      </section>
      <section class="panel">
        <h2>Admin Snapshot</h2>
        {_table(
            ["Metric", "Value"],
            [
                f"<tr><td>Total restaurants</td><td>{master_summary.total_restaurants}</td></tr>",
                f"<tr><td>Restaurants without identifiers</td><td>{master_summary.restaurants_without_identifiers}</td></tr>",
                f"<tr><td>Restaurants without source links</td><td>{master_summary.restaurants_without_source_links}</td></tr>",
                f"<tr><td>Inspections missing reports</td><td>{master_summary.inspections_missing_reports}</td></tr>",
            ],
            empty_message="No admin metrics available."
        )}
        <div class="actions" style="margin-top:14px;">
          <a class="button secondary" href="/ops/control-panel/admin/restaurants">Browse restaurants</a>
          <a class="button secondary" href="/ops/control-panel/master-data">Open master data diagnostics</a>
        </div>
      </section>
    </section>
    <section class="panel" style="margin-top:18px;">
      <h2>Recent runs</h2>
      {_sorted_hint()}
      {_table(
          ["Run", "Mode", "Status", "Artifacts", "Parsed", "Normalized"],
          [
                f"<tr class='{'latest-row' if i == 0 else ''}'><td><a href='/ops/control-panel/runs/{r.scrape_run_id}'>{escape(r.scrape_run_id[:8])}</a>{_latest_badge(i)}<br>{_meta_text(r.source_slug)}</td><td>{escape(r.run_mode)}</td><td><span class='{_badge_class(r.run_status)}'>{escape(r.run_status)}</span></td><td>{r.artifact_count}</td><td>{r.parsed_record_count}</td><td>{r.normalized_record_count}</td></tr>"
              for i, r in enumerate(runs)
          ],
          empty_message="No runs recorded yet."
      )}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Console Overview", active_path="/ops/control-panel", workspace="overview")


def _platforms_page() -> str:
    platforms = list_platforms()
    cards = []
    for platform in platforms:
        cards.append(
            f"""
            <section class="panel platform-card">
              <div>
                <h3>{escape(platform.platform_name)}</h3>
                <div class="muted">{escape(platform.platform_slug)}</div>
              </div>
              <div class="chip-row">
                <span class="chip">{platform.source_count} sources</span>
                <span class="chip">{platform.healthy_source_count} healthy</span>
                <span class="chip">{platform.warning_source_count} warning</span>
                <span class="chip">{platform.stale_source_count} stale</span>
              </div>
              <div class="muted">Base domain: {escape(platform.base_domain or 'n/a')}</div>
              <div class="muted">Latest success: {_display(platform.latest_success_at)}</div>
              <div class="actions"><a class="button secondary" href="/ops/control-panel/sources?platform_slug={escape(platform.platform_slug)}">View sources</a></div>
            </section>
            """
        )
    body = f"""
    <section class="hero">
      <div><h1>Platforms</h1><p>Platform registry groups related source ingestions so the console stays manageable as more websites come online.</p></div>
    </section>
    <section class="grid two">
      {''.join(cards) if cards else "<section class='panel'><div class='muted'>No platforms registered yet.</div></section>"}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Platforms", active_path="/ops/control-panel/platforms")


def _sources_page(
    *,
    q: str | None,
    page: int,
    page_size: int,
    platform_slug: str | None,
    never_run_only: bool,
) -> str:
    sources, total_count = list_sources_page(
        page=page,
        page_size=page_size,
        query=q,
        platform_slug=platform_slug,
        never_run_only=never_run_only,
    )
    grouped: dict[tuple[str | None, str], list[OpsSourceSummary]] = defaultdict(list)
    for source in sources:
        grouped[(source.platform_slug, source.platform_name)].append(source)

    group_sections = []
    for (group_slug, group_name), group_sources in grouped.items():
        rows = []
        for source in group_sources:
            run_form = (
                f"<form class='run-form' method='post' action='/ops/control-panel/sources/{escape(source.source_slug)}/run'>"
                "<select name='run_mode'>"
                "<option value='incremental'>incremental</option>"
                "<option value='reconciliation'>reconciliation</option>"
                "<option value='backfill'>backfill</option>"
                "</select>"
                "<button type='submit'>Run</button>"
                "</form>"
            )
            rows.append(
                f"<tr><td><strong>{_source_runs_link(source.source_slug, source.source_name)}</strong><br>{_meta_text(source.source_slug)}</td>"
                f"<td>{escape(source.jurisdiction_name)}</td>"
                f"<td><span class='{_badge_class(source.status)}'>{escape(source.status)}</span></td>"
                f"<td><span class='{_badge_class(source.last_run_status)}'>{escape(source.last_run_status or 'never run')}</span></td>"
                f"<td>{_display(source.latest_success_at)}</td>"
                f"<td>{_display(source.freshness_age_days)}</td>"
                f"<td class='action-cell'>{run_form}</td></tr>"
            )
        section = f"""
        <section class="panel">
          <div class="toolbar">
            <div>
              <h2>{escape(group_name)}</h2>
              <div class="muted">{escape(group_slug or 'unregistered-platform')}</div>
            </div>
            <div class="chip-row"><span class="chip">{len(group_sources)} sources on this page</span></div>
          </div>
          {_table(["Source", "Jurisdiction", "Config status", "Last run", "Last success", "Freshness (days)", "Action"], rows, empty_message="No sources found for this platform.")}
        </section>
        """
        group_sections.append(section)

    toolbar = _search_form(
        "/ops/control-panel/sources",
        q=q,
        page_size=page_size,
        placeholder="Search source slug, source name, platform, or jurisdiction",
        extra_fields="".join(
            [
                _platform_filter_select(platform_slug),
                _checkbox_field(name="never_run_only", label="Never run only", checked=never_run_only),
            ]
        ),
    )
    pager = _pagination_controls(
        "/ops/control-panel/sources",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        platform_slug=platform_slug,
        never_run_only="true" if never_run_only else None,
    )
    body = f"""
    <section class="hero">
      <div><h1>Sources</h1><p>All configured source ingestions across current and future platforms.</p></div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
    </section>
    <section class="grid">
      {''.join(group_sections) if group_sections else "<section class='panel'><div class='muted'>No sources found.</div></section>"}
    </section>
    <section class="panel">{pager}</section>
    """
    return _control_panel_shell(body, title="FiScore Ops Sources", active_path="/ops/control-panel/sources")


def _runs_page(*, q: str | None, page: int, page_size: int, source_slug: str | None) -> str:
    runs, total_count = list_runs_page(page=page, page_size=page_size, query=q, source_slug=source_slug)
    rows = [
        f"<tr class='{'latest-row' if i == 0 else ''}'><td><a href='/ops/control-panel/runs/{escape(r.scrape_run_id)}'>{escape(r.scrape_run_id[:8])}</a>{_latest_badge(i)}<br>{_meta_text(r.source_slug)}</td>"
        f"<td>{escape(r.run_mode)}</td>"
        f"<td><span class='badge'>{escape(r.trigger_type)}</span></td>"
        f"<td><span class='{_badge_class(r.run_status)}'>{escape(r.run_status)}</span></td>"
        f"<td>{r.artifact_count}</td><td>{r.parsed_record_count}</td><td>{r.normalized_record_count}</td><td>{r.warning_count}</td><td>{r.error_count}</td><td>{_display(r.started_at)}</td></tr>"
        for i, r in enumerate(runs)
    ]
    source_options = ["<option value=''>All sources</option>"]
    for source in list_sources(limit=250):
        selected = "selected" if source.source_slug == source_slug else ""
        source_options.append(
            f"<option value='{escape(source.source_slug)}' {selected}>{escape(source.source_name)}</option>"
        )
    toolbar = _search_form(
        "/ops/control-panel/runs",
        q=q,
        page_size=page_size,
        placeholder="Search source, run mode, status, or trigger",
        extra_fields=f"<select name='source_slug'>{''.join(source_options)}</select>",
    )
    pager = _pagination_controls(
        "/ops/control-panel/runs",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        source_slug=source_slug,
    )
    body = f"""
    <section class="hero">
      <div><h1>Runs</h1><p>Recent source execution history across all ingestion modes.</p></div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_sorted_hint()}
      <div class="table-tight">
      {_table(["Run", "Mode", "Trigger", "Status", "Artifacts", "Parsed", "Normalized", "Warnings", "Errors", "Started"], rows, empty_message="No runs recorded yet.")}
      </div>
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Runs", active_path="/ops/control-panel/runs")


def _run_detail_page(scrape_run_id: str, *, tab: str | None = None) -> str:
    detail = get_run_detail(scrape_run_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Run {scrape_run_id} was not found.")
    active_tab = tab if tab in {"overview", "issues", "data"} else (
        "issues" if detail.run.warning_count > 0 or detail.run.error_count > 0 else "overview"
    )
    artifact_rows = [
        f"<tr><td>{escape(a.artifact_type)}</td><td><a href='/ops/control-panel/artifacts/{escape(a.raw_artifact_id)}'>{escape(a.raw_artifact_id[:8])}</a></td><td class='mono'>{_compact_link(a.source_url)}</td><td class='mono'>{_compact_text(a.storage_path)}</td><td>{_display(a.fetched_at)}</td></tr>"
        for a in detail.artifacts
    ]
    parse_rows = [
        f"<tr><td>{escape(p.record_type)}</td><td><a href='/ops/control-panel/parse-results/{escape(p.parse_result_id)}'>{escape(p.parse_result_id[:8])}</a></td><td>{escape(p.parse_status)}</td><td>{escape(p.source_record_key or '&mdash;')}</td><td>{p.warning_count}</td></tr>"
        for p in detail.parse_results[:100]
    ]
    warning_rows = [
        f"<tr><td>{escape(w.warning_code)}</td><td>{escape(w.warning_message)}</td><td>{_display(w.created_at)}</td></tr>"
        for w in detail.warnings
    ]
    issue_rows = [
        (
            f"<tr><td>{escape(i.severity)}</td><td>{escape(i.category)}</td><td>{escape(i.issue_code)}</td>"
            f"<td>{_compact_message(i.issue_message)}</td><td>{escape(i.component or '&mdash;')}</td>"
            f"<td>{escape(i.stage or '&mdash;')}</td><td>{_display(i.created_at)}</td></tr>"
        )
        for i in detail.issues
    ]
    issue_counts: dict[str, int] = defaultdict(int)
    issue_patterns: dict[tuple[str, str, str, str | None, str | None], dict[str, object]] = {}
    for issue in detail.issues:
        issue_counts[f"{issue.severity}:{issue.category}"] += 1
        pattern_key = (
            issue.severity,
            issue.category,
            issue.issue_code,
            issue.component,
            issue.stage,
        )
        current = issue_patterns.get(pattern_key)
        if current is None:
            issue_patterns[pattern_key] = {
                "severity": issue.severity,
                "category": issue.category,
                "issue_code": issue.issue_code,
                "component": issue.component,
                "stage": issue.stage,
                "count": 1,
                "latest_created_at": issue.created_at,
            }
        else:
            current["count"] = int(current["count"]) + 1
            if issue.created_at > current["latest_created_at"]:
                current["latest_created_at"] = issue.created_at
    top_issue_cards = [
        (
            f"<div class='issue-summary-card'><span class='label'>{escape(key.replace(':', ' / '))}</span>"
            f"<span class='count'>{count}</span></div>"
        )
        for key, count in sorted(issue_counts.items(), key=lambda item: (-item[1], item[0]))[:6]
    ]
    issue_pattern_rows = [
        (
            f"<tr><td>{escape(str(pattern['severity']))}</td>"
            f"<td>{escape(str(pattern['category']))}</td>"
            f"<td>{escape(str(pattern['issue_code']))}</td>"
            f"<td>{pattern['count']}</td>"
            f"<td>{escape(str(pattern['component'] or '&mdash;'))}</td>"
            f"<td>{escape(str(pattern['stage'] or '&mdash;'))}</td>"
            f"<td>{_display(pattern['latest_created_at'])}</td></tr>"
        )
        for pattern in sorted(
            issue_patterns.values(),
            key=lambda item: (-int(item["count"]), str(item["issue_code"])),
        )[:8]
    ]
    artifact_preview_rows = artifact_rows[:8]
    parse_preview_rows = parse_rows[:10]
    top_issue_codes = ", ".join(sorted({i.issue_code for i in detail.issues})[:3]) or "No issues recorded"
    context_block = f"""
    <div class="context-accordion">
      <details class="disclosure">
        <summary>Request Context</summary>
        <div class="disclosure-body"><pre>{_pretty(detail.request_context)}</pre></div>
      </details>
      <details class="disclosure">
        <summary>Source Snapshot</summary>
        <div class="disclosure-body"><pre>{_pretty(detail.source_snapshot)}</pre></div>
      </details>
    </div>
    """
    tabs = "".join(
        [
            _run_tab_link(scrape_run_id, "overview", "Overview", active_tab=active_tab),
            _run_tab_link(scrape_run_id, "issues", "Issues", active_tab=active_tab),
            _run_tab_link(scrape_run_id, "data", "Data", active_tab=active_tab),
        ]
    )
    if active_tab == "overview":
        tab_body = f"""
        <section class="grid two">
          <section class="panel stack">
            <h2>Issue Summary</h2>
            <div class="issue-summary-grid">
              {''.join(top_issue_cards) if top_issue_cards else "<div class='issue-summary-card'><span class='label'>Run</span><span class='count'>Clean</span></div>"}
            </div>
            <div class="muted">Top issue codes: {escape(top_issue_codes)}</div>
          </section>
          <section class="panel stack">
            <h2>Context</h2>
            {context_block}
          </section>
          <section class="panel">
            <h2>Issue Patterns</h2>
            {_table(["Severity", "Category", "Code", "Count", "Component", "Stage", "Latest"], issue_pattern_rows, empty_message="No run issues recorded.")}
          </section>
          <section class="panel">
            <h2>Artifact Preview</h2>
            <div class="table-artifacts">
            {_table(["Type", "Artifact", "Source URL", "Storage", "Fetched"], artifact_preview_rows, empty_message="No artifacts recorded.")}
            </div>
          </section>
        </section>
        """
    elif active_tab == "issues":
        tab_body = f"""
        <section class="grid">
          <section class="panel stack">
            <h2>Issue Summary</h2>
            <div class="issue-summary-grid">
              {''.join(top_issue_cards) if top_issue_cards else "<div class='issue-summary-card'><span class='label'>Run</span><span class='count'>Clean</span></div>"}
            </div>
          </section>
          <section class="panel">
            <h2>Run Issues</h2>
            <div class="table-issues">
            {_table(["Severity", "Category", "Code", "Message", "Component", "Stage", "Created"], issue_rows, empty_message="No run issues recorded.")}
            </div>
          </section>
          <section class="panel">
            <h2>Parser Warnings</h2>
            {_table(["Code", "Message", "Created"], warning_rows, empty_message="No parser warnings recorded.")}
          </section>
        </section>
        """
    else:
        tab_body = f"""
        <section class="grid two">
          <section class="panel">
            <h2>Artifacts</h2>
            <div class="table-artifacts">
            {_table(["Type", "Artifact", "Source URL", "Storage", "Fetched"], artifact_rows, empty_message="No artifacts recorded.")}
            </div>
          </section>
          <section class="panel">
            <h2>Parse Results</h2>
            {_table(["Type", "Parse Result", "Status", "Source key", "Warnings"], parse_preview_rows, empty_message="No parse results recorded.")}
          </section>
          <section class="panel stack">
            <h2>Context</h2>
            {context_block}
          </section>
        </section>
        """
    body = f"""
    <section class="hero">
      <div>
        <h1>Run {escape(detail.run.scrape_run_id[:8])}</h1>
        <p>{escape(detail.run.source_name)} - {escape(detail.run.source_slug)} - {escape(detail.run.run_mode)}</p>
      </div>
      <div class="actions">
        <a class="button secondary" href="{_build_url('/ops/control-panel/master-data/inspections', scrape_run_id=detail.run.scrape_run_id)}">Resulting master records</a>
        <a class="button secondary" href="/ops/control-panel/runs">Back to runs</a>
      </div>
    </section>
    <section class="summary-strip">
      <section class="summary-card">
        <h3>Status</h3>
        <div class="actions">
          <span class="{_badge_class(detail.run.run_status)}">{escape(detail.run.run_status)}</span>
        </div>
        <div class="small">Started {_display(detail.run.started_at)}<br>Completed {_display(detail.run.completed_at)}</div>
      </section>
      <section class="summary-card">
        <h3>Artifacts</h3>
        <span class="big">{detail.run.artifact_count}</span>
        <div class="small">Fetched and stored during this run</div>
      </section>
      <section class="summary-card">
        <h3>Parsed</h3>
        <span class="big">{detail.run.parsed_record_count}</span>
        <div class="small">Inspection and finding parse results</div>
      </section>
      <section class="summary-card">
        <h3>Normalized</h3>
        <span class="big">{detail.run.normalized_record_count}</span>
        <div class="small">Writes into master tables and reports</div>
      </section>
      <section class="summary-card">
        <h3>Issues</h3>
        <span class="big">{detail.run.warning_count + detail.run.error_count}</span>
        <div class="small">Warnings {detail.run.warning_count} | Errors {detail.run.error_count}</div>
      </section>
    </section>
    <section class="panel" style="margin-bottom:18px;">
      <div class="actions" style="justify-content:space-between; align-items:flex-start;">
        <div class="stack">
          <h2 style="margin-bottom:0;">Run Summary</h2>
          <div class="muted">Trigger: {escape(detail.run.trigger_type)} | Error summary: {escape(detail.run.error_summary or '-')}</div>
        </div>
        <div class="run-tabs">{tabs}</div>
      </div>
    </section>
    {tab_body}
    """
    return _control_panel_shell(body, title=f"Run {detail.run.scrape_run_id}", active_path="/ops/control-panel/runs")


def _master_data_tab_link(tab: str, label: str, *, active_tab: str, **params: object) -> str:
    active = "active" if tab == active_tab else ""
    path = "/ops/control-panel/master-data" if not tab else f"/ops/control-panel/master-data/{tab}"
    href = _build_url(path, **params)
    return f"<a class='subtab {active}' href='{href}'>{escape(label)}</a>"


def _master_data_tabs(*, active_tab: str, scrape_run_id: str | None = None) -> str:
    params = {"scrape_run_id": scrape_run_id}
    return "".join(
        [
            _master_data_tab_link("", "Overview", active_tab=active_tab, **params),
            _master_data_tab_link("restaurants", "Restaurants", active_tab=active_tab, **params),
            _master_data_tab_link("inspections", "Inspections", active_tab=active_tab, **params),
            _master_data_tab_link("reports", "Reports", active_tab=active_tab, **params),
            _master_data_tab_link("findings", "Findings", active_tab=active_tab, **params),
        ]
    )


def _master_data_overview_page(*, scrape_run_id: str | None = None) -> str:
    summary = get_master_data_quality_summary()
    inspections, inspection_total = list_master_inspections_page(
        page=1,
        page_size=8,
        scrape_run_id=scrape_run_id,
    )
    restaurants, restaurant_total = list_master_restaurants_page(page=1, page_size=8, quality_filter="duplicates")
    tabs = _master_data_tabs(active_tab="", scrape_run_id=scrape_run_id)
    inspection_rows = [
        (
            f"<tr><td><a href='/ops/control-panel/master-data/inspections/{escape(item.master_inspection_id)}'>{escape(item.master_inspection_id[:8])}</a></td>"
            f"<td><a href='/ops/control-panel/master-data/restaurants/{escape(item.master_restaurant_id)}'>{escape(item.display_name)}</a><br>{_meta_text(f'{item.city}, {item.state_code}')}</td>"
            f"<td>{escape(item.source_slug)}</td><td>{_display(item.inspection_date)}</td>"
            f"<td><span class='{_badge_class(item.report_availability_status or 'missing')}'>{escape(item.report_availability_status or 'missing')}</span></td>"
            f"<td>{item.finding_count}</td></tr>"
        )
        for item in inspections
    ]
    restaurant_rows = [
        (
            f"<tr><td><a href='/ops/control-panel/master-data/restaurants/{escape(item.master_restaurant_id)}'>{escape(item.display_name)}</a></td>"
            f"<td>{escape(item.address_line1)}<br>{_meta_text(f'{item.city}, {item.state_code} {item.zip_code or ''}'.strip())}</td>"
            f"<td>{item.duplicate_group_size}</td><td>{item.source_link_count}</td><td>{item.report_gap_count}</td></tr>"
        )
        for item in restaurants
    ]
    run_banner = (
        f"<div class='badge warn'>Scoped to run {escape(scrape_run_id[:8])}</div>"
        if scrape_run_id
        else "<div class='badge'>All master data</div>"
    )
    body = f"""
    <section class="hero">
      <div>
        <h1>Master Data Explorer</h1>
        <p>Inspect canonical restaurants, inspections, reports, and findings with the source trace you need to debug parsing, linkage, duplicates, and report coverage.</p>
      </div>
      <div class="actions">{run_banner}</div>
    </section>
    <section class="summary-strip">
      <section class="summary-card"><h3>Restaurants</h3><span class="big">{summary.total_restaurants}</span><div class="small">Canonical restaurant records</div></section>
      <section class="summary-card"><h3>Inspections</h3><span class="big">{summary.total_inspections}</span><div class="small">Normalized inspections</div></section>
      <section class="summary-card"><h3>Reports</h3><span class="big">{summary.inspections_missing_reports}</span><div class="small">Inspections missing a usable report</div></section>
      <section class="summary-card"><h3>Duplicates</h3><span class="big">{summary.duplicate_risk_restaurants}</span><div class="small">Restaurants in duplicate-risk groups</div></section>
      <section class="summary-card"><h3>Weak Linkage</h3><span class="big">{summary.restaurants_without_source_links + summary.restaurants_without_identifiers}</span><div class="small">Restaurants lacking core source linkage</div></section>
    </section>
    <section class="panel" style="margin-bottom:18px;">
      <div class="actions" style="justify-content:space-between; align-items:flex-start;">
        <div class="stack">
          <h2 style="margin-bottom:0;">Quality Lenses</h2>
          <div class="muted">Use these shortcuts to jump directly into the records most likely to need operational review.</div>
        </div>
        <div class="run-tabs">{tabs}</div>
      </div>
      <div class="actions" style="margin-top:14px; flex-wrap:wrap;">
        <a class="button secondary" href="/ops/control-panel/master-data/restaurants?quality_filter=duplicates">Duplicate-risk restaurants</a>
        <a class="button secondary" href="/ops/control-panel/master-data/restaurants?quality_filter=weak_linkage">Weak source linkage</a>
        <a class="button secondary" href="/ops/control-panel/master-data/inspections?report_status=missing">Missing reports</a>
        <a class="button secondary" href="/ops/control-panel/master-data/reports?missing_storage_only=true">Reports missing storage</a>
        <a class="button secondary" href="/ops/control-panel/master-data/findings?missing_detail_only=true">Thin finding detail</a>
      </div>
    </section>
    <section class="grid two">
      <section class="panel">
        <h2>Recent Inspections {f"<span class='badge'>Run scope: {escape(scrape_run_id[:8])}</span>" if scrape_run_id else ""}</h2>
        <div class="muted">{inspection_total} matching inspections</div>
        {_table(["Inspection", "Restaurant", "Source", "Date", "Report", "Findings"], inspection_rows, empty_message="No master inspections found.")}
      </section>
      <section class="panel">
        <h2>Duplicate-Risk Restaurants</h2>
        <div class="muted">{restaurant_total} restaurants in duplicate-risk groups</div>
        {_table(["Restaurant", "Address", "Group", "Source Links", "Report Gaps"], restaurant_rows, empty_message="No duplicate-risk restaurants found.")}
      </section>
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Master Data", active_path="/ops/control-panel/master-data")


def _master_restaurants_page(
    *,
    q: str | None,
    page: int,
    page_size: int,
    source_slug: str | None,
    quality_filter: str | None,
    scrape_run_id: str | None = None,
) -> str:
    restaurants, total_count = list_master_restaurants_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        quality_filter=quality_filter,
    )
    rows = [
        (
            f"<tr><td><a href='/ops/control-panel/master-data/restaurants/{escape(item.master_restaurant_id)}'>{escape(item.display_name)}</a><br>{_meta_text(item.master_restaurant_id[:8])}</td>"
            f"<td>{escape(item.address_line1)}<br>{_meta_text(f'{item.city}, {item.state_code} {item.zip_code or ''}'.strip())}</td>"
            f"<td><span class='{_badge_class(item.status)}'>{escape(item.status)}</span></td>"
            f"<td>{item.source_link_count}</td><td>{item.identifier_count}</td><td>{item.inspection_count}</td><td>{item.report_gap_count}</td>"
            f"<td>{item.duplicate_group_size}</td><td>{_display(item.latest_inspection_date)}</td></tr>"
        )
        for item in restaurants
    ]
    quality_options = ["<option value=''>All quality states</option>"]
    for option, label in (
        ("duplicates", "Duplicate risk"),
        ("missing_reports", "Missing reports"),
        ("weak_linkage", "Weak linkage"),
    ):
        selected = "selected" if option == quality_filter else ""
        quality_options.append(f"<option value='{option}' {selected}>{label}</option>")
    toolbar = _search_form(
        "/ops/control-panel/master-data/restaurants",
        q=q,
        page_size=page_size,
        placeholder="Search restaurant, address, identifier, source slug, or source key",
        extra_fields=f"{_source_filter_select(source_slug)}<select name='quality_filter'>{''.join(quality_options)}</select>",
    )
    pager = _pagination_controls(
        "/ops/control-panel/master-data/restaurants",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        source_slug=source_slug,
        quality_filter=quality_filter,
    )
    body = f"""
    <section class="hero">
      <div><h1>Master Restaurants</h1><p>Browse canonical restaurant identities, source linkage coverage, duplicate-risk groups, and report gaps.</p></div>
      <div class="actions"><a class="button secondary" href="/ops/control-panel/master-data">Overview</a></div>
    </section>
    <section class="panel" style="margin-bottom:18px;">
      <div class="actions" style="justify-content:space-between; align-items:flex-start;">
        <div class="stack">
          <h2 style="margin-bottom:0;">Explorer</h2>
          <div class="muted">Best starting point for duplicate restaurant review and weak linkage detection.</div>
        </div>
        <div class="run-tabs">{_master_data_tabs(active_tab='restaurants', scrape_run_id=scrape_run_id)}</div>
      </div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_sorted_hint("Newest inspection first, then recently touched master records.")}
      {_table(["Restaurant", "Address", "Status", "Source Links", "Identifiers", "Inspections", "Report Gaps", "Dup Group", "Latest Inspection"], rows, empty_message="No master restaurants found.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Master Restaurants", active_path="/ops/control-panel/master-data")


def _master_restaurant_detail_page(master_restaurant_id: str) -> str:
    detail = get_master_restaurant_detail(master_restaurant_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Master restaurant {master_restaurant_id} was not found.")
    restaurant = detail.restaurant
    identifier_rows = [
        f"<tr><td>{escape(item.identifier_type)}</td><td class='mono'>{escape(item.identifier_value)}</td><td>{escape(item.source_slug or '&mdash;')}</td><td>{'yes' if item.is_primary else 'no'}</td><td>{_display(item.confidence)}</td></tr>"
        for item in detail.identifiers
    ]
    source_link_rows = [
        (
            f"<tr><td>{escape(item.source_name)}<br>{_meta_text(item.source_slug)}</td><td class='mono'>{escape(item.source_restaurant_key)}</td>"
            f"<td>{escape(item.match_method)}</td><td><span class='{_badge_class(item.match_status)}'>{escape(item.match_status)}</span></td>"
            f"<td>{_display(item.match_confidence)}</td><td>{item.inspection_count}</td><td>{_display(item.latest_inspection_date)}</td></tr>"
        )
        for item in detail.source_links
    ]
    inspection_rows = [
        (
            f"<tr><td><a href='/ops/control-panel/master-data/inspections/{escape(item.master_inspection_id)}'>{escape(item.master_inspection_id[:8])}</a></td>"
            f"<td>{escape(item.source_slug)}</td><td class='mono'>{escape(item.source_inspection_key)}</td><td>{_display(item.inspection_date)}</td>"
            f"<td>{escape(item.inspection_type or '&mdash;')}</td><td>{_display(item.score)}</td><td>{escape(item.grade or '&mdash;')}</td>"
            f"<td><span class='{_badge_class(item.report_availability_status or 'missing')}'>{escape(item.report_availability_status or 'missing')}</span></td><td>{item.finding_count}</td></tr>"
        )
        for item in detail.inspections
    ]
    body = f"""
    <section class="hero">
      <div>
        <h1>{escape(restaurant.display_name)}</h1>
        <p>{escape(restaurant.address_line1)} &bull; {escape(restaurant.city)}, {escape(restaurant.state_code)} {escape(restaurant.zip_code or '')}</p>
      </div>
      <div class="actions">
        <a class="button secondary" href="{_build_url('/ops/control-panel/lineage', q=restaurant.display_name)}">View lineage</a>
        <a class="button secondary" href="/ops/control-panel/master-data/restaurants">Back to restaurants</a>
      </div>
    </section>
    <section class="summary-strip">
      <section class="summary-card"><h3>Source Links</h3><span class="big">{restaurant.source_link_count}</span><div class="small">Source restaurant mappings</div></section>
      <section class="summary-card"><h3>Identifiers</h3><span class="big">{restaurant.identifier_count}</span><div class="small">External identifiers</div></section>
      <section class="summary-card"><h3>Inspections</h3><span class="big">{restaurant.inspection_count}</span><div class="small">Normalized inspections</div></section>
      <section class="summary-card"><h3>Report Gaps</h3><span class="big">{restaurant.report_gap_count}</span><div class="small">Inspections without usable reports</div></section>
      <section class="summary-card"><h3>Dup Group</h3><span class="big">{restaurant.duplicate_group_size}</span><div class="small">Shared location fingerprint group size</div></section>
    </section>
    <section class="grid two">
      <section class="panel stack">
        <h2>Identity</h2>
        <div class="muted">Master restaurant ID: <span class="mono">{escape(restaurant.master_restaurant_id)}</span></div>
        <div class="muted">Location fingerprint: <span class="mono">{escape(restaurant.location_fingerprint)}</span></div>
        <div class="muted">Normalized name: {escape(restaurant.normalized_name or '&mdash;')}</div>
        <div class="muted">Status: <span class="{_badge_class(restaurant.status)}">{escape(restaurant.status)}</span></div>
        <div class="muted">Latest inspection: {_display(restaurant.latest_inspection_date)}</div>
      </section>
      <section class="panel">
        <h2>Identifiers</h2>
        {_table(["Type", "Value", "Source", "Primary", "Confidence"], identifier_rows, empty_message="No identifiers recorded.")}
      </section>
      <section class="panel">
        <h2>Source Links</h2>
        {_table(["Source", "Source Key", "Method", "Status", "Confidence", "Inspections", "Latest"], source_link_rows, empty_message="No source links recorded.")}
      </section>
      <section class="panel">
        <h2>Inspections</h2>
        {_table(["Inspection", "Source", "Source Key", "Date", "Type", "Score", "Grade", "Report", "Findings"], inspection_rows, empty_message="No inspections recorded.")}
      </section>
    </section>
    """
    return _control_panel_shell(body, title=restaurant.display_name, active_path="/ops/control-panel/master-data")


def _master_inspections_page(
    *,
    q: str | None,
    page: int,
    page_size: int,
    source_slug: str | None,
    report_status: str | None,
    scrape_run_id: str | None = None,
) -> str:
    inspections, total_count = list_master_inspections_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        report_status=report_status,
        scrape_run_id=scrape_run_id,
    )
    rows = [
        (
            f"<tr><td><a href='/ops/control-panel/master-data/inspections/{escape(item.master_inspection_id)}'>{escape(item.master_inspection_id[:8])}</a></td>"
            f"<td><a href='/ops/control-panel/master-data/restaurants/{escape(item.master_restaurant_id)}'>{escape(item.display_name)}</a><br>{_meta_text(f'{item.city}, {item.state_code}')}</td>"
            f"<td>{escape(item.source_slug)}</td><td class='mono'>{escape(item.source_inspection_key)}</td><td>{_display(item.inspection_date)}</td>"
            f"<td>{escape(item.inspection_type or '&mdash;')}</td><td>{_display(item.score)}</td><td>{escape(item.grade or '&mdash;')}</td>"
            f"<td><span class='{_badge_class(item.report_availability_status or 'missing')}'>{escape(item.report_availability_status or 'missing')}</span></td><td>{item.finding_count}</td></tr>"
        )
        for item in inspections
    ]
    report_options = ["<option value=''>All report states</option>"]
    for option in ("available", "not_provided_by_source", "missing"):
        selected = "selected" if option == report_status else ""
        report_options.append(f"<option value='{option}' {selected}>{option}</option>")
    run_scope_field = (
        f"<input type='hidden' name='scrape_run_id' value='{escape(scrape_run_id)}' />"
        if scrape_run_id
        else ""
    )
    toolbar = _search_form(
        "/ops/control-panel/master-data/inspections",
        q=q,
        page_size=page_size,
        placeholder="Search restaurant, source, inspection key, type, grade, or status",
        extra_fields=(
            f"{_source_filter_select(source_slug)}"
            f"<select name='report_status'>{''.join(report_options)}</select>"
            f"{run_scope_field}"
        ),
    )
    pager = _pagination_controls(
        "/ops/control-panel/master-data/inspections",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        source_slug=source_slug,
        report_status=report_status,
        scrape_run_id=scrape_run_id,
    )
    body = f"""
    <section class="hero">
      <div><h1>Master Inspections</h1><p>Trace normalized inspections back to source keys and quickly spot missing reports, weak parsing, and suspicious counts.</p></div>
      <div class="actions">
        {f"<span class='badge warn'>Run {escape(scrape_run_id[:8])}</span>" if scrape_run_id else ""}
        <a class="button secondary" href="/ops/control-panel/master-data">Overview</a>
      </div>
    </section>
    <section class="panel" style="margin-bottom:18px;">
      <div class="actions" style="justify-content:space-between; align-items:flex-start;">
        <div class="stack">
          <h2 style="margin-bottom:0;">Explorer</h2>
          <div class="muted">This is the fastest path from a run or lineage entry into the master inspection records it produced.</div>
        </div>
        <div class="run-tabs">{_master_data_tabs(active_tab='inspections', scrape_run_id=scrape_run_id)}</div>
      </div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_sorted_hint("Newest inspection first. Use run scope to inspect the records created from a specific source run.")}
      {_table(["Inspection", "Restaurant", "Source", "Source Key", "Date", "Type", "Score", "Grade", "Report", "Findings"], rows, empty_message="No master inspections found.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Master Inspections", active_path="/ops/control-panel/master-data")


def _master_inspection_detail_page(master_inspection_id: str) -> str:
    detail = get_master_inspection_detail(master_inspection_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Master inspection {master_inspection_id} was not found.")
    inspection = detail.inspection
    report_rows = [
        (
            f"<tr><td>{escape(item.report_role)}</td><td>{escape(item.report_format or '&mdash;')}</td>"
            f"<td><span class='{_badge_class(item.availability_status)}'>{escape(item.availability_status)}</span></td>"
            f"<td class='mono'>{_compact_text(item.storage_path or '&mdash;')}</td>"
            f"<td class='mono'>{_compact_link(item.source_file_url) if item.source_file_url else '&mdash;'}</td>"
            f"<td>{_display(item.updated_at)}</td></tr>"
        )
        for item in detail.reports
    ]
    finding_rows = [
        (
            f"<tr><td>{escape(item.official_code or '&mdash;')}</td><td>{escape(item.normalized_category or '&mdash;')}</td>"
            f"<td>{escape(item.severity or '&mdash;')}</td><td>{_compact_message(item.official_text, max_length=120)}</td>"
            f"<td>{'yes' if item.corrected_during_inspection else 'no' if item.corrected_during_inspection is not None else '&mdash;'}</td>"
            f"<td>{'yes' if item.is_repeat_violation else 'no' if item.is_repeat_violation is not None else '&mdash;'}</td></tr>"
        )
        for item in detail.findings
    ]
    run_rows = [
        (
            f"<tr><td><a href='/ops/control-panel/runs/{escape(item.scrape_run_id)}'>{escape(item.scrape_run_id[:8])}</a></td>"
            f"<td>{escape(item.run_status)}</td><td>{escape(item.run_mode)}</td><td>{escape(item.parser_version)}</td>"
            f"<td>{item.parsed_record_count}</td><td>{item.normalized_record_count}</td><td>{_display(item.started_at)}</td></tr>"
        )
        for item in detail.related_runs
    ]
    body = f"""
    <section class="hero">
      <div>
        <h1>Inspection {escape(inspection.master_inspection_id[:8])}</h1>
        <p><a href='/ops/control-panel/master-data/restaurants/{escape(inspection.master_restaurant_id)}'>{escape(inspection.display_name)}</a> &bull; {escape(inspection.source_name)} &bull; {escape(inspection.source_inspection_key)}</p>
      </div>
      <div class="actions">
        <a class="button secondary" href="{_build_url('/ops/control-panel/lineage', q=inspection.source_inspection_key)}">View lineage</a>
        <a class="button secondary" href="/ops/control-panel/master-data/inspections">Back to inspections</a>
      </div>
    </section>
    <section class="summary-strip">
      <section class="summary-card"><h3>Date</h3><span class="big">{escape(str(inspection.inspection_date))}</span><div class="small">Inspection date</div></section>
      <section class="summary-card"><h3>Score</h3><span class="big">{escape(str(inspection.score)) if inspection.score is not None else '&mdash;'}</span><div class="small">Normalized score</div></section>
      <section class="summary-card"><h3>Grade</h3><span class="big">{escape(inspection.grade or '&mdash;')}</span><div class="small">Grade from source</div></section>
      <section class="summary-card"><h3>Report</h3><span class="big">{escape(inspection.report_availability_status or 'missing')}</span><div class="small">Current report availability</div></section>
      <section class="summary-card"><h3>Findings</h3><span class="big">{inspection.finding_count}</span><div class="small">Current findings linked</div></section>
    </section>
    <section class="grid two">
      <section class="panel stack">
        <h2>Inspection Summary</h2>
        <div class="muted">Source: {escape(inspection.source_name)} ({escape(inspection.source_slug)})</div>
        <div class="muted">Restaurant: <a href='/ops/control-panel/master-data/restaurants/{escape(inspection.master_restaurant_id)}'>{escape(inspection.display_name)}</a></div>
        <div class="muted">Type: {escape(inspection.inspection_type or '&mdash;')}</div>
        <div class="muted">Official status: {escape(inspection.official_status or '&mdash;')}</div>
        <div class="muted">Report URL: {escape(inspection.report_url or '&mdash;')}</div>
        <div class="muted">Stored report: <span class="mono">{escape(inspection.report_storage_path or '&mdash;')}</span></div>
      </section>
      <section class="panel">
        <h2>Reports</h2>
        {_table(["Role", "Format", "Availability", "Storage", "Source File", "Updated"], report_rows, empty_message="No report records linked.")}
      </section>
      <section class="panel">
        <h2>Findings</h2>
        {_table(["Code", "Category", "Severity", "Official Text", "Corrected", "Repeat"], finding_rows, empty_message="No findings linked.")}
      </section>
      <section class="panel">
        <h2>Related Runs</h2>
        {_table(["Run", "Status", "Mode", "Parser", "Parsed", "Normalized", "Started"], run_rows, empty_message="No source runs resolved for this inspection.")}
      </section>
    </section>
    """
    return _control_panel_shell(body, title=f"Inspection {inspection.master_inspection_id}", active_path="/ops/control-panel/master-data")


def _master_reports_page(
    *,
    q: str | None,
    page: int,
    page_size: int,
    source_slug: str | None,
    availability_status: str | None,
    missing_storage_only: bool,
    scrape_run_id: str | None = None,
) -> str:
    reports, total_count = list_master_reports_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        availability_status=availability_status,
        missing_storage_only=missing_storage_only,
    )
    rows = [
        (
            f"<tr><td><a href='/ops/control-panel/master-data/inspections/{escape(item.master_inspection_id)}'>{escape(item.display_name)}</a></td>"
            f"<td>{escape(item.source_slug)}</td><td>{_display(item.inspection_date)}</td><td>{escape(item.report_role)}</td>"
            f"<td>{escape(item.report_format or '&mdash;')}</td><td><span class='{_badge_class(item.availability_status)}'>{escape(item.availability_status)}</span></td>"
            f"<td class='mono'>{_compact_text(item.storage_path or '&mdash;')}</td><td>{'yes' if item.is_current else 'no'}</td></tr>"
        )
        for item in reports
    ]
    availability_options = ["<option value=''>All availability</option>"]
    for option in ("available", "not_provided_by_source"):
        selected = "selected" if option == availability_status else ""
        availability_options.append(f"<option value='{option}' {selected}>{option}</option>")
    toolbar = _search_form(
        "/ops/control-panel/master-data/reports",
        q=q,
        page_size=page_size,
        placeholder="Search restaurant, source, report role, URLs, or storage path",
        extra_fields=(
            f"{_source_filter_select(source_slug)}"
            f"<select name='availability_status'>{''.join(availability_options)}</select>"
            f"{_checkbox_field(name='missing_storage_only', label='Available but not stored', checked=missing_storage_only)}"
        ),
    )
    pager = _pagination_controls(
        "/ops/control-panel/master-data/reports",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        source_slug=source_slug,
        availability_status=availability_status,
        missing_storage_only=missing_storage_only,
    )
    body = f"""
    <section class="hero">
      <div><h1>Master Reports</h1><p>Inspect report availability and storage linkage to catch missing PDFs, broken attachments, and weak report metadata.</p></div>
      <div class="actions"><a class="button secondary" href="/ops/control-panel/master-data">Overview</a></div>
    </section>
    <section class="panel" style="margin-bottom:18px;">
      <div class="actions" style="justify-content:space-between; align-items:flex-start;">
        <div class="stack">
          <h2 style="margin-bottom:0;">Explorer</h2>
          <div class="muted">Use this page when an inspection exists but the report trail looks incomplete or inconsistent.</div>
        </div>
        <div class="run-tabs">{_master_data_tabs(active_tab='reports', scrape_run_id=scrape_run_id)}</div>
      </div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_table(["Inspection", "Source", "Date", "Role", "Format", "Availability", "Storage", "Current"], rows, empty_message="No report records found.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Master Reports", active_path="/ops/control-panel/master-data")


def _master_findings_page(
    *,
    q: str | None,
    page: int,
    page_size: int,
    source_slug: str | None,
    missing_detail_only: bool,
    scrape_run_id: str | None = None,
) -> str:
    findings, total_count = list_master_findings_page(
        page=page,
        page_size=page_size,
        query=q,
        source_slug=source_slug,
        missing_detail_only=missing_detail_only,
    )
    rows = [
        (
            f"<tr><td><a href='/ops/control-panel/master-data/inspections/{escape(item.master_inspection_id)}'>{escape(item.display_name)}</a></td>"
            f"<td>{escape(item.source_slug)}</td><td>{_display(item.inspection_date)}</td><td>{escape(item.official_code or '&mdash;')}</td>"
            f"<td>{escape(item.normalized_category or '&mdash;')}</td><td>{escape(item.severity or '&mdash;')}</td>"
            f"<td>{_compact_message(item.official_text, max_length=120)}</td><td>{_compact_message(item.official_detail_text or '&mdash;', max_length=100)}</td></tr>"
        )
        for item in findings
    ]
    toolbar = _search_form(
        "/ops/control-panel/master-data/findings",
        q=q,
        page_size=page_size,
        placeholder="Search restaurant, source, violation code, clause, text, or category",
        extra_fields=f"{_source_filter_select(source_slug)}{_checkbox_field(name='missing_detail_only', label='Missing detail text', checked=missing_detail_only)}",
    )
    pager = _pagination_controls(
        "/ops/control-panel/master-data/findings",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        source_slug=source_slug,
        missing_detail_only=missing_detail_only,
    )
    body = f"""
    <section class="hero">
      <div><h1>Master Findings</h1><p>Review normalized findings and spot weak parsing where codes, detail text, or categories did not come through cleanly.</p></div>
      <div class="actions"><a class="button secondary" href="/ops/control-panel/master-data">Overview</a></div>
    </section>
    <section class="panel" style="margin-bottom:18px;">
      <div class="actions" style="justify-content:space-between; align-items:flex-start;">
        <div class="stack">
          <h2 style="margin-bottom:0;">Explorer</h2>
          <div class="muted">This page is optimized for parser QA, especially when finding text feels too thin or duplicated.</div>
        </div>
        <div class="run-tabs">{_master_data_tabs(active_tab='findings', scrape_run_id=scrape_run_id)}</div>
      </div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_table(["Inspection", "Source", "Date", "Code", "Category", "Severity", "Official Text", "Detail"], rows, empty_message="No findings found.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Master Findings", active_path="/ops/control-panel/master-data")


def _admin_restaurant_tab_link(master_restaurant_id: str, tab: str, label: str, *, active_tab: str) -> str:
    active = "active" if tab == active_tab else ""
    href = _build_url(f"/ops/control-panel/admin/restaurants/{master_restaurant_id}", tab=tab)
    return f"<a class='subtab {active}' href='{href}'>{escape(label)}</a>"


def _admin_restaurants_page(
    *,
    q: str | None,
    page: int,
    page_size: int,
    state_code: str | None,
    city: str | None,
    status: str | None,
    source_slug: str | None,
    has_inspections: bool | None,
) -> str:
    restaurants, total_count = list_admin_restaurants_page(
        page=page,
        page_size=page_size,
        query=q,
        state_code=state_code,
        city=city,
        status=status,
        source_slug=source_slug,
        has_inspections=has_inspections,
    )
    rows = [
        (
            f"<tr><td><a href='/ops/control-panel/admin/restaurants/{escape(item.master_restaurant_id)}'>{escape(item.display_name)}</a></td>"
            f"<td>{escape(item.address_line1)}<br>{_meta_text(f'{item.city}, {item.state_code} {item.zip_code or ''}'.strip())}</td>"
            f"<td>{item.source_link_count}</td><td>{item.inspection_count}</td><td>{_display(item.latest_inspection_date)}</td>"
            f"<td><span class='{_badge_class(item.status)}'>{escape(item.status)}</span></td></tr>"
        )
        for item in restaurants
    ]
    status_options = ["<option value=''>All statuses</option>"]
    for option in ("active", "inactive"):
        selected = "selected" if option == status else ""
        status_options.append(f"<option value='{option}' {selected}>{option}</option>")
    inspection_options = ["<option value=''>All restaurants</option>"]
    for option, label in (("true", "Has inspections"), ("false", "No inspections")):
        selected = "selected" if ((option == "true" and has_inspections is True) or (option == "false" and has_inspections is False)) else ""
        inspection_options.append(f"<option value='{option}' {selected}>{label}</option>")
    toolbar = _search_form(
        "/ops/control-panel/admin/restaurants",
        q=q,
        page_size=page_size,
        placeholder="Search restaurant name, address, city, zip, or identifier",
        extra_fields=(
            f"<input class='control-compact' type='text' name='city' value='{escape(city or '')}' placeholder='City' />"
            f"<input class='control-compact' type='text' name='state_code' value='{escape(state_code or '')}' placeholder='State' />"
            f"{_source_filter_select(source_slug)}"
            f"<select name='status'>{''.join(status_options)}</select>"
            f"<select name='has_inspections'>{''.join(inspection_options)}</select>"
        ),
    )
    pager = _pagination_controls(
        "/ops/control-panel/admin/restaurants",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        state_code=state_code,
        city=city,
        status=status,
        source_slug=source_slug,
        has_inspections=("true" if has_inspections is True else "false" if has_inspections is False else None),
    )
    body = f"""
    <section class="hero">
      <div>
        <h1>Restaurants</h1>
        <p>Search the full restaurant directory and drill from the canonical restaurant record into its inspections and findings.</p>
      </div>
      <div class="actions">
        <a class="button secondary" href="/ops/control-panel">Overview</a>
      </div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_sorted_hint("Most recently inspected restaurants first.")}
      {_table(["Restaurant", "Address", "Sources", "Inspections", "Latest Inspection", "Status"], rows, empty_message="No restaurants found.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Admin Restaurants", active_path="/ops/control-panel/admin/restaurants", workspace="admin")

def _admin_restaurant_detail_page(master_restaurant_id: str, *, tab: str | None = None) -> str:
    detail = get_admin_restaurant_detail(master_restaurant_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Admin restaurant {master_restaurant_id} was not found.")
    active_tab = tab if tab in {"overview", "sources"} else "overview"
    restaurant = detail.restaurant
    tabs = "".join(
        [
            _admin_restaurant_tab_link(master_restaurant_id, "overview", "Overview", active_tab=active_tab),
            _admin_restaurant_tab_link(master_restaurant_id, "sources", "Source Data", active_tab=active_tab),
        ]
    )
    identifier_rows = [
        f"<tr><td>{escape(item.identifier_type)}</td><td class='mono'>{escape(item.identifier_value)}</td><td>{escape(item.source_slug or '-')}</td><td>{'yes' if item.is_primary else 'no'}</td></tr>"
        for item in detail.identifiers
    ]
    source_link_rows = [
        (
            f"<tr><td>{escape(item.source_name)}<br>{_meta_text(item.source_slug)}</td>"
            f"<td class='mono'>{escape(item.source_restaurant_key)}</td><td>{escape(item.match_method)}</td>"
            f"<td><span class='{_badge_class(item.match_status)}'>{escape(item.match_status)}</span></td>"
            f"<td>{_display(item.latest_inspection_date)}</td></tr>"
        )
        for item in detail.source_links
    ]
    all_findings = [finding for entry in detail.inspections for finding in entry.findings]
    total_findings = sum(inspection.inspection.finding_count for inspection in detail.inspections)
    critical_count = sum(1 for finding in all_findings if (finding.severity or "").strip().lower() == "critical")
    latest_inspection = detail.inspections[0].inspection if detail.inspections else None
    latest_grade = latest_inspection.grade if latest_inspection and latest_inspection.grade else None
    latest_score = (
        str(int(latest_inspection.score))
        if latest_inspection and latest_inspection.score is not None and float(latest_inspection.score).is_integer()
        else str(latest_inspection.score)
        if latest_inspection and latest_inspection.score is not None
        else None
    )
    latest_grade_ring_value = latest_grade or latest_score or "N/A"
    latest_grade_ring_caption = "Grade" if latest_grade else "Score" if latest_score else ""
    inspection_blocks: list[str] = []
    for entry in detail.inspections:
        inspection = entry.inspection
        inspection_summary_bits = [inspection.inspection_type or "Inspection"]
        if inspection.inspector_name:
            inspection_summary_bits.append(f"Inspector {inspection.inspector_name}")
        score_text = (
            str(int(inspection.score))
            if inspection.score is not None and float(inspection.score).is_integer()
            else str(inspection.score)
            if inspection.score is not None
            else None
        )
        sorted_findings = sorted(
            entry.findings,
            key=lambda finding: (_severity_sort_key(finding.severity), finding.finding_order or 999999),
        )
        finding_blocks: list[str] = []
        for finding in sorted_findings:
            severity_slug = (finding.severity or "").strip().lower()
            severity_label = _title_case_slug(finding.severity)
            category_or_title = finding.normalized_category or finding.normalized_title or "Finding"
            severity_badge = (
                f"<span class='badge severity-{escape(severity_slug)}'>{escape(severity_label)}</span>"
                if severity_slug
                else ""
            )
            repeat_badge = "<span class='badge repeat'>Repeat finding</span>" if finding.is_repeat_violation else ""
            corrected_value = (
                "Corrected during inspection"
                if finding.corrected_during_inspection
                else None
            )
            flag_badges = "".join(
                badge
                for badge in (
                    severity_badge,
                    repeat_badge,
                    f"<span class='badge corrected'>{escape(corrected_value)}</span>" if corrected_value else "",
                )
                if badge
            )
            finding_blocks.append(
                f"""
                <article class="finding-item">
                  <div class="finding-header">
                    <span class="finding-code">{escape(finding.official_code or 'No code')}</span>
                    {flag_badges}
                  </div>
                  <div class="finding-title">{escape(category_or_title)}</div>
                  <div class="finding-block">
                    <span class="finding-block-label">Official finding</span>
                    {escape(finding.official_text)}
                  </div>
                  {f"<div class='finding-block'><span class='finding-block-label'>Finding details</span>{escape(finding.official_detail_text)}</div>" if finding.official_detail_text else ""}
                  {f"<div class='finding-block'><span class='finding-block-label'>Auditor comments</span>{escape(finding.auditor_comments)}</div>" if finding.auditor_comments else ""}
                </article>
                """
            )
        inspection_blocks.append(
            f"""
            <details class="inspection-card">
              <summary>
                <div>
                  <div class="inspection-card-title">{escape(_display_date_compact(inspection.inspection_date))}</div>
                  <div class="inspection-card-subtitle">{escape(" - ".join(inspection_summary_bits))}</div>
                </div>
                <div class="inspection-card-right">
                  {f"<span class='info-chip'>Score {escape(score_text)}</span>" if score_text else ""}
                  {f"<span class='info-chip'>Grade {escape(inspection.grade)}</span>" if inspection.grade else ""}
                  <span class="info-chip">{inspection.finding_count} {('finding' if inspection.finding_count == 1 else 'findings')}</span>
                </div>
              </summary>
              <div class="inspection-card-body">
                <div class="inspection-meta">
                  <span class="info-chip">Source {escape(inspection.source_name)}</span>
                  {f"<span class='info-chip'>Score {escape(score_text)}</span>" if score_text else ""}
                  {f"<span class='info-chip'>Grade {escape(inspection.grade)}</span>" if inspection.grade else ""}
                  {f"<span class='info-chip'>Status {escape(inspection.official_status)}</span>" if inspection.official_status else ""}
                  <span class="info-chip">Report {escape(inspection.report_availability_status or 'missing')}</span>
                </div>
                <div class="finding-list">
                  {''.join(finding_blocks) if finding_blocks else "<div class='muted'>No findings linked to this inspection.</div>"}
                </div>
              </div>
            </details>
            """
        )
    if active_tab == "overview":
        tab_body = f"""
        <section class="panel">
          <h2>Inspection History</h2>
          <div class="inspection-history">
            {''.join(inspection_blocks) if inspection_blocks else "<div class='muted'>No inspections recorded for this restaurant.</div>"}
          </div>
        </section>
        """
    else:
        tab_body = f"""
        <section class="source-grid">
          <section class="panel">
            <h2>Master Record</h2>
            <div class="overview-facts">
              <div><div class="fact-label">Master restaurant ID</div><div class="fact-value mono">{escape(restaurant.master_restaurant_id)}</div></div>
              <div><div class="fact-label">Record status</div><div class="fact-value">{escape(restaurant.status)}</div></div>
              <div><div class="fact-label">Normalized name</div><div class="fact-value">{escape(restaurant.normalized_name or '-')}</div></div>
              <div><div class="fact-label">Location fingerprint</div><div class="fact-value mono">{escape(restaurant.location_fingerprint)}</div></div>
            </div>
          </section>
          <section class="panel">
            <h2>Identifiers</h2>
            {_table(["Type", "Value", "Source", "Primary"], identifier_rows, empty_message="No identifiers recorded.")}
          </section>
          <section class="panel">
            <h2>Linked Sources</h2>
            {_table(["Source", "Source Key", "Method", "Status", "Latest Inspection"], source_link_rows, empty_message="No source links recorded.")}
          </section>
          <section class="panel stack">
            <h2>Diagnostics</h2>
            <div class="muted">Use these tools when you need lineage, reconciliation, or other master-data diagnostics.</div>
            <div class="actions">
              <a class="button secondary" href="/ops/control-panel/master-data/restaurants/{escape(restaurant.master_restaurant_id)}">View master data diagnostics</a>
              <a class="button secondary" href="{_build_url('/ops/control-panel/lineage', q=restaurant.display_name)}">View lineage</a>
            </div>
          </section>
        </section>
        """
    body = f"""
    <section class="hero restaurant-hero">
      <div>
        <div class="hero-kicker">{escape(restaurant.status)} - restaurant record</div>
        <h1>{escape(restaurant.display_name)}</h1>
        <p>{escape(restaurant.address_line1)}</p>
        <div class="hero-meta">
          <span>{escape(f'{restaurant.city}, {restaurant.state_code} {restaurant.zip_code or ""}'.strip())}</span>
        </div>
      </div>
      <div class="actions">
        <div class="grade-ring">
          <span class="letter">{escape(latest_grade_ring_value)}</span>
          {f"<span class='caption'>{escape(latest_grade_ring_caption)}</span>" if latest_grade_ring_caption else ""}
        </div>
        <a class="button secondary" href="/ops/control-panel/admin/restaurants">Back to restaurants</a>
      </div>
    </section>
    <section class="summary-strip">
      <section class="summary-card"><h3>Inspections</h3><span class="big">{restaurant.inspection_count}</span><div class="small">Inspection history</div></section>
      <section class="summary-card"><h3>Total Findings</h3><span class="big">{total_findings}</span><div class="small">Across all linked inspections</div></section>
      <section class="summary-card"><h3>Critical Findings</h3><span class="big">{critical_count}</span><div class="small">Findings marked with critical severity</div></section>
      <section class="summary-card"><h3>Last Inspected</h3><span class="big">{escape(_display_date_compact(restaurant.latest_inspection_date))}</span><div class="small">Most recent inspection date</div></section>
      <section class="summary-card"><h3>Sources</h3><span class="big">{restaurant.source_link_count}</span><div class="small">Linked source records</div></section>
    </section>
    <section class="panel" style="margin-bottom:18px;">
      <div class="run-tabs">{tabs}</div>
    </section>
    {tab_body}
    """
    return _control_panel_shell(body, title=restaurant.display_name, active_path="/ops/control-panel/admin/restaurants", workspace="admin")

def _artifacts_page(*, q: str | None, page: int, page_size: int) -> str:
    artifacts, total_count = list_artifacts_page(page=page, page_size=page_size, query=q)
    rows = [
        f"<tr class='{'latest-row' if i == 0 else ''}'><td><a href='/ops/control-panel/artifacts/{escape(a.raw_artifact_id)}'>{escape(a.raw_artifact_id[:8])}</a>{_latest_badge(i)}</td><td>{escape(a.artifact_type)}</td><td class='mono'>{_compact_link(a.source_url)}</td><td class='mono'>{_compact_text(a.storage_path)}</td><td>{_display(a.fetched_at)}</td></tr>"
        for i, a in enumerate(artifacts)
    ]
    toolbar = _search_form(
        "/ops/control-panel/artifacts",
        q=q,
        page_size=page_size,
        placeholder="Search artifact type, source URL, storage path, or source slug",
    )
    pager = _pagination_controls("/ops/control-panel/artifacts", page=page, page_size=page_size, total_count=total_count, q=q)
    body = f"""
    <section class="hero">
      <div><h1>Artifacts</h1><p>Raw HTML, JSON, and future PDFs fetched during source ingestion.</p></div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_sorted_hint()}
      <div class="table-artifacts">
      {_table(["Artifact", "Type", "Source URL", "Storage Path", "Fetched"], rows, empty_message="No artifacts recorded yet.")}
      </div>
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Artifacts", active_path="/ops/control-panel/artifacts")


def _artifact_detail_page(raw_artifact_id: str) -> str:
    detail = get_artifact_detail(raw_artifact_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Artifact {raw_artifact_id} was not found.")
    body = f"""
    <section class="hero">
      <div><h1>Artifact {escape(detail.raw_artifact_id[:8])}</h1><p>Raw artifact detail and storage reference.</p></div>
      <div class="actions"><a class="button secondary" href="/ops/control-panel/artifacts">Back to artifacts</a></div>
    </section>
    <section class="grid two">
      <section class="panel stack">
        <h2>Artifact Summary</h2>
        <div class="muted">Type: {escape(detail.artifact_type)}</div>
        <div class="muted">Fetched: {_display(detail.fetched_at)}</div>
        <div class="muted">Source URL: <a class="mono" href="{escape(detail.source_url)}">{escape(detail.source_url)}</a></div>
        <div class="muted">Storage path: <span class="mono">{escape(detail.storage_path)}</span></div>
        <div class="muted">Content hash: {escape(detail.content_hash)}</div>
      </section>
      <section class="panel">
        <h2>Trace</h2>
        <pre>{_pretty({"source_id": detail.source_id, "scrape_run_id": detail.scrape_run_id})}</pre>
      </section>
    </section>
    """
    return _control_panel_shell(body, title=f"Artifact {detail.raw_artifact_id}", active_path="/ops/control-panel/artifacts")


def _parse_results_page(*, q: str | None, page: int, page_size: int, record_type: str | None) -> str:
    parse_results, total_count = list_parse_results_page(page=page, page_size=page_size, query=q, record_type=record_type)
    rows = [
        f"<tr class='{'latest-row' if i == 0 else ''}'><td><a href='/ops/control-panel/parse-results/{escape(p.parse_result_id)}'>{escape(p.parse_result_id[:8])}</a>{_latest_badge(i)}</td><td>{escape(p.record_type)}</td><td>{escape(p.parse_status)}</td><td>{escape(p.source_record_key or '-')}</td><td>{p.warning_count}</td><td>{_display(p.created_at)}</td></tr>"
        for i, p in enumerate(parse_results)
    ]
    record_options = ["<option value=''>All types</option>"]
    for option in ("inspection", "finding"):
        selected = "selected" if option == record_type else ""
        record_options.append(f"<option value='{option}' {selected}>{option}</option>")
    toolbar = _search_form(
        "/ops/control-panel/parse-results",
        q=q,
        page_size=page_size,
        placeholder="Search record type, source key, parse status, or payload",
        extra_fields=f"<select name='record_type'>{''.join(record_options)}</select>",
    )
    pager = _pagination_controls(
        "/ops/control-panel/parse-results",
        page=page,
        page_size=page_size,
        total_count=total_count,
        q=q,
        record_type=record_type,
    )
    body = f"""
    <section class="hero">
      <div><h1>Parsed Records</h1><p>Inspection, finding, and future source-shaped outputs created by parsers.</p></div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_sorted_hint()}
      {_table(["Parse Result", "Type", "Status", "Source Key", "Warnings", "Created"], rows, empty_message="No parse results recorded yet.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Parsed Records", active_path="/ops/control-panel/parse-results")


def _parse_result_detail_page(parse_result_id: str) -> str:
    detail = get_parse_result_detail(parse_result_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Parse result {parse_result_id} was not found.")
    body = f"""
    <section class="hero">
      <div><h1>Parse Result {escape(detail.parse_result_id[:8])}</h1><p>{escape(detail.record_type)} - {escape(detail.parse_status)}</p></div>
      <div class="actions"><a class="button secondary" href="/ops/control-panel/parse-results">Back to parsed records</a></div>
    </section>
    <section class="grid two">
      <section class="panel stack">
        <h2>Summary</h2>
        <div class="muted">Type: {escape(detail.record_type)}</div>
        <div class="muted">Status: {escape(detail.parse_status)}</div>
        <div class="muted">Source key: {escape(detail.source_record_key or '&mdash;')}</div>
        <div class="muted">Warnings: {detail.warning_count} | Errors: {detail.error_count}</div>
        <div class="muted">Created: {_display(detail.created_at)}</div>
      </section>
      <section class="panel">
        <h2>Payload</h2>
        <pre>{_pretty(detail.payload)}</pre>
      </section>
    </section>
    """
    return _control_panel_shell(body, title=f"Parse Result {detail.parse_result_id}", active_path="/ops/control-panel/parse-results")


def _health_page() -> str:
    health = get_health_summary()
    sources = list_sources(limit=250)
    rows = [
        f"<tr><td><strong>{_source_runs_link(s.source_slug, s.source_name)}</strong><br>{_meta_text(s.source_slug)}</td><td>{_display(s.latest_success_at)}</td><td>{_display(s.freshness_age_days)}</td><td><span class='{_badge_class(s.last_run_status or ('stale' if s.freshness_age_days is None else 'healthy'))}'>{escape(s.last_run_status or 'never run')}</span></td></tr>"
        for s in sources
    ]
    body = f"""
    <section class="hero">
      <div><h1>Health</h1><p>Freshness, success cadence, and operational status across all sources.</p></div>
    </section>
    <section class="grid three">
      <div class="stat"><span class="value">{health.total_platforms}</span><span class="muted">Platforms</span></div>
      <div class="stat"><span class="value">{health.healthy_sources}</span><span class="muted">Healthy sources</span></div>
      <div class="stat"><span class="value">{health.stale_sources}</span><span class="muted">Stale sources</span></div>
    </section>
    <section class="panel" style="margin-top:18px;">
      <h2>Freshness by source</h2>
      {_table(["Source", "Latest success", "Freshness days", "Last run status"], rows, empty_message="No source health data yet.")}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Health", active_path="/ops/control-panel/health")


def _alerts_page(*, q: str | None, page: int, page_size: int) -> str:
    alerts, total_count = list_alerts_page(page=page, page_size=page_size, query=q)
    rows = [
        f"<tr><td><span class='{_badge_class(a.severity)}'>{escape(a.severity)}</span></td><td>{escape(a.title)}</td><td>{escape(a.source_slug or '&mdash;')}</td><td>{escape(a.status)}</td><td>{escape(a.message)}</td><td>{_display(a.created_at)}</td></tr>"
        for a in alerts
    ]
    toolbar = _search_form(
        "/ops/control-panel/alerts",
        q=q,
        page_size=page_size,
        placeholder="Search alert type, title, source, or message",
    )
    pager = _pagination_controls("/ops/control-panel/alerts", page=page, page_size=page_size, total_count=total_count, q=q)
    body = f"""
    <section class="hero">
      <div><h1>Alerts</h1><p>Operational alerts tied to sources and runs.</p></div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_table(["Severity", "Title", "Source", "Status", "Message", "Created"], rows, empty_message="No operational alerts recorded.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Alerts", active_path="/ops/control-panel/alerts")


def _reruns_page(*, q: str | None, page: int, page_size: int) -> str:
    reruns, total_count = list_reruns_page(page=page, page_size=page_size, query=q)
    source_options = "".join(
        f"<option value='{escape(s.source_slug)}'>{escape(s.source_name)} ({escape(s.source_slug)})</option>"
        for s in list_sources(limit=250)
    )
    rows = [
        f"<tr><td>{escape(r.source_name)}</td><td>{escape(r.requested_scope)}</td><td>{escape(r.requested_by or '&mdash;')}</td><td><span class='{_badge_class(r.status)}'>{escape(r.status)}</span></td><td>{_display(r.created_at)}</td></tr>"
        for r in reruns
    ]
    toolbar = _search_form(
        "/ops/control-panel/reruns",
        q=q,
        page_size=page_size,
        placeholder="Search source, scope, requester, or status",
    )
    pager = _pagination_controls("/ops/control-panel/reruns", page=page, page_size=page_size, total_count=total_count, q=q)
    body = f"""
    <section class="hero">
      <div><h1>Reruns</h1><p>Queue and inspect rerun requests without jumping into SQL.</p></div>
    </section>
    <section class="grid two">
      <section class="panel">
        <h2>Create rerun request</h2>
        <form method="post" action="/ops/control-panel/reruns/create" class="stack">
          <label>Source<select name="source_slug">{source_options}</select></label>
          <label>Requested scope<select name="requested_scope"><option value="incremental">incremental</option><option value="reconciliation">reconciliation</option><option value="backfill">backfill</option><option value="targeted">targeted</option></select></label>
          <label>Requested by<input type="text" name="requested_by" value="control-panel" /></label>
          <label>Request payload (JSON)<textarea name="request_payload">{{}}</textarea></label>
          <div class="actions"><button type="submit">Create rerun request</button></div>
        </form>
      </section>
      <section class="panel">
        <h2>Recent rerun requests</h2>
        <div class="toolbar">{toolbar}</div>
        {pager}
        {_table(["Source", "Scope", "Requested by", "Status", "Created"], rows, empty_message="No rerun requests recorded.")}
        {pager}
      </section>
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Reruns", active_path="/ops/control-panel/reruns")


def _lineage_page(*, q: str | None, page: int, page_size: int) -> str:
    lineage, total_count = list_lineage_page(page=page, page_size=page_size, query=q)
    rows = [
        f"<tr><td><strong>{escape(item.display_name)}</strong><br><span class='muted'>{escape(item.city)}, {escape(item.state_code)}</span></td><td>{escape(item.source_slug)}</td><td>{escape(item.source_inspection_key)}</td><td>{_display(item.inspection_date)}</td><td>{escape(item.inspection_type or '&mdash;')}</td><td><span class='{_badge_class(item.report_availability_status)}'>{escape(item.report_availability_status or '&mdash;')}</span></td><td>{item.finding_count}</td></tr>"
        for item in lineage
    ]
    toolbar = _search_form(
        "/ops/control-panel/lineage",
        q=q,
        page_size=page_size,
        placeholder="Search restaurant, city, source slug, source inspection key, or type",
    )
    pager = _pagination_controls("/ops/control-panel/lineage", page=page, page_size=page_size, total_count=total_count, q=q)
    body = f"""
    <section class="hero">
      <div><h1>Master Lineage</h1><p>How normalized inspections connect back to sources, reports, and finding counts.</p></div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_table(["Restaurant", "Source", "Source Inspection Key", "Inspection Date", "Type", "Report Status", "Findings"], rows, empty_message="No normalized lineage available yet.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Lineage", active_path="/ops/control-panel/lineage")


def _versions_page(*, q: str | None, page: int, page_size: int) -> str:
    versions, total_count = list_source_versions_page(page=page, page_size=page_size, query=q)
    rows = [
        f"<tr><td>{escape(v.source_slug)}</td><td>{escape(v.entity_type)}</td><td>{escape(v.source_entity_key or '&mdash;')}</td><td>{v.version_number}</td><td><span class='{_badge_class('current' if v.is_current else 'historical')}'>{'current' if v.is_current else 'historical'}</span></td><td>{escape(v.change_type)}</td><td>{_display(v.effective_at)}</td></tr>"
        for v in versions
    ]
    toolbar = _search_form(
        "/ops/control-panel/versions",
        q=q,
        page_size=page_size,
        placeholder="Search source slug, entity type, source key, or change type",
    )
    pager = _pagination_controls("/ops/control-panel/versions", page=page, page_size=page_size, total_count=total_count, q=q)
    body = f"""
    <section class="hero">
      <div><h1>Versions</h1><p>Version history and diff inspection hooks for source entities.</p></div>
    </section>
    <section class="panel">
      <div class="toolbar">{toolbar}</div>
      {pager}
      {_table(["Source", "Entity", "Source Key", "Version", "Current", "Change Type", "Effective"], rows, empty_message="No source versions recorded yet.")}
      {pager}
    </section>
    """
    return _control_panel_shell(body, title="FiScore Ops Versions", active_path="/ops/control-panel/versions")


@router.get("/control-panel", response_class=HTMLResponse, include_in_schema=False)
def control_panel_root() -> str:
    return _overview_page()


@router.get("/control-panel/overview", response_class=HTMLResponse, include_in_schema=False)
def control_panel_overview() -> str:
    return _overview_page()


@router.get("/control-panel/platforms", response_class=HTMLResponse, include_in_schema=False)
def control_panel_platforms() -> str:
    return _platforms_page()


@router.get("/control-panel/sources", response_class=HTMLResponse, include_in_schema=False)
def control_panel_sources(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    platform_slug: str | None = None,
    never_run_only: bool = False,
) -> str:
    return _sources_page(
        q=q,
        page=page,
        page_size=page_size,
        platform_slug=platform_slug,
        never_run_only=never_run_only,
    )


@router.post("/control-panel/sources/{source_slug}/run", include_in_schema=False)
def control_panel_trigger_run(
    source_slug: str,
    run_mode: str = Form("incremental"),
) -> RedirectResponse:
    dispatch_run(
        WorkerRunRequest(
            source_slug=source_slug,
            run_mode=run_mode,  # type: ignore[arg-type]
            trigger_type="manual",
        )
    )
    return RedirectResponse(url="/ops/control-panel/runs", status_code=303)


@router.get("/control-panel/runs", response_class=HTMLResponse, include_in_schema=False)
def control_panel_runs(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    source_slug: str | None = None,
) -> str:
    return _runs_page(q=q, page=page, page_size=page_size, source_slug=source_slug)


@router.get("/control-panel/runs/{scrape_run_id}", response_class=HTMLResponse, include_in_schema=False)
def control_panel_run_detail(scrape_run_id: str, tab: str | None = None) -> str:
    return _run_detail_page(scrape_run_id, tab=tab)


@router.get("/control-panel/master-data", response_class=HTMLResponse, include_in_schema=False)
def control_panel_master_data(scrape_run_id: str | None = None) -> str:
    return _master_data_overview_page(scrape_run_id=scrape_run_id)


@router.get("/control-panel/master-data/restaurants", response_class=HTMLResponse, include_in_schema=False)
def control_panel_master_restaurants(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    source_slug: str | None = None,
    quality_filter: str | None = None,
    scrape_run_id: str | None = None,
) -> str:
    return _master_restaurants_page(
        q=q,
        page=page,
        page_size=page_size,
        source_slug=source_slug,
        quality_filter=quality_filter,
        scrape_run_id=scrape_run_id,
    )


@router.get("/control-panel/master-data/restaurants/{master_restaurant_id}", response_class=HTMLResponse, include_in_schema=False)
def control_panel_master_restaurant_detail(master_restaurant_id: str) -> str:
    return _master_restaurant_detail_page(master_restaurant_id)


@router.get("/control-panel/master-data/inspections", response_class=HTMLResponse, include_in_schema=False)
def control_panel_master_inspections(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    source_slug: str | None = None,
    report_status: str | None = None,
    scrape_run_id: str | None = None,
) -> str:
    return _master_inspections_page(
        q=q,
        page=page,
        page_size=page_size,
        source_slug=source_slug,
        report_status=report_status,
        scrape_run_id=scrape_run_id,
    )


@router.get("/control-panel/master-data/inspections/{master_inspection_id}", response_class=HTMLResponse, include_in_schema=False)
def control_panel_master_inspection_detail(master_inspection_id: str) -> str:
    return _master_inspection_detail_page(master_inspection_id)


@router.get("/control-panel/master-data/reports", response_class=HTMLResponse, include_in_schema=False)
def control_panel_master_reports(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    source_slug: str | None = None,
    availability_status: str | None = None,
    missing_storage_only: bool = False,
    scrape_run_id: str | None = None,
) -> str:
    return _master_reports_page(
        q=q,
        page=page,
        page_size=page_size,
        source_slug=source_slug,
        availability_status=availability_status,
        missing_storage_only=missing_storage_only,
        scrape_run_id=scrape_run_id,
    )


@router.get("/control-panel/master-data/findings", response_class=HTMLResponse, include_in_schema=False)
def control_panel_master_findings(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    source_slug: str | None = None,
    missing_detail_only: bool = False,
    scrape_run_id: str | None = None,
) -> str:
    return _master_findings_page(
        q=q,
        page=page,
        page_size=page_size,
        source_slug=source_slug,
        missing_detail_only=missing_detail_only,
        scrape_run_id=scrape_run_id,
    )


@router.get("/control-panel/admin/restaurants", response_class=HTMLResponse, include_in_schema=False)
def control_panel_admin_restaurants(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    state_code: str | None = None,
    city: str | None = None,
    status: str | None = None,
    source_slug: str | None = None,
    has_inspections: str | None = None,
) -> str:
    has_inspections_value = True if has_inspections == "true" else False if has_inspections == "false" else None
    return _admin_restaurants_page(
        q=q,
        page=page,
        page_size=page_size,
        state_code=state_code,
        city=city,
        status=status,
        source_slug=source_slug,
        has_inspections=has_inspections_value,
    )


@router.get("/control-panel/admin/restaurants/{master_restaurant_id}", response_class=HTMLResponse, include_in_schema=False)
def control_panel_admin_restaurant_detail(master_restaurant_id: str, tab: str | None = None) -> str:
    return _admin_restaurant_detail_page(master_restaurant_id, tab=tab)


@router.get("/control-panel/artifacts", response_class=HTMLResponse, include_in_schema=False)
def control_panel_artifacts(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
) -> str:
    return _artifacts_page(q=q, page=page, page_size=page_size)


@router.get("/control-panel/artifacts/{raw_artifact_id}", response_class=HTMLResponse, include_in_schema=False)
def control_panel_artifact_detail(raw_artifact_id: str) -> str:
    return _artifact_detail_page(raw_artifact_id)


@router.get("/control-panel/parse-results", response_class=HTMLResponse, include_in_schema=False)
def control_panel_parse_results(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
    record_type: str | None = None,
) -> str:
    return _parse_results_page(q=q, page=page, page_size=page_size, record_type=record_type)


@router.get("/control-panel/parse-results/{parse_result_id}", response_class=HTMLResponse, include_in_schema=False)
def control_panel_parse_result_detail(parse_result_id: str) -> str:
    return _parse_result_detail_page(parse_result_id)


@router.get("/control-panel/health", response_class=HTMLResponse, include_in_schema=False)
def control_panel_health() -> str:
    return _health_page()


@router.get("/control-panel/alerts", response_class=HTMLResponse, include_in_schema=False)
def control_panel_alerts(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
) -> str:
    return _alerts_page(q=q, page=page, page_size=page_size)


@router.get("/control-panel/reruns", response_class=HTMLResponse, include_in_schema=False)
def control_panel_reruns(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
) -> str:
    return _reruns_page(q=q, page=page, page_size=page_size)


@router.post("/control-panel/reruns/create", include_in_schema=False)
def control_panel_create_rerun(
    source_slug: str,
    requested_scope: str,
    requested_by: str = "control-panel",
    request_payload: str = "{}",
) -> RedirectResponse:
    parsed_payload: dict = {}
    try:
        decoded = json.loads(request_payload)
        if isinstance(decoded, dict):
            parsed_payload = decoded
    except json.JSONDecodeError:
        parsed_payload = {"raw_input": request_payload}
    create_rerun_request(
        CreateRerunRequest(
            source_slug=source_slug,
            requested_scope=requested_scope,
            requested_by=requested_by,
            request_payload=parsed_payload,
        )
    )
    return RedirectResponse(url="/ops/control-panel/reruns", status_code=303)


@router.get("/control-panel/lineage", response_class=HTMLResponse, include_in_schema=False)
def control_panel_lineage(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
) -> str:
    return _lineage_page(q=q, page=page, page_size=page_size)


@router.get("/control-panel/versions", response_class=HTMLResponse, include_in_schema=False)
def control_panel_versions(
    q: str | None = None,
    page: int = 1,
    page_size: int = 50,
) -> str:
    return _versions_page(q=q, page=page, page_size=page_size)
