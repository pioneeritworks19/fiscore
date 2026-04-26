from datetime import UTC, date, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field


RunMode = Literal["backfill", "incremental", "reconciliation"]
TriggerType = Literal["manual", "scheduler", "api"]


class HealthResponse(BaseModel):
    status: str
    service: str
    environment: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(UTC))


class WorkerRunRequest(BaseModel):
    source_slug: str = Field(..., description="Source slug such as sword_mi_wayne")
    run_mode: RunMode = "incremental"
    trigger_type: TriggerType = "api"


class WorkerRunResponse(BaseModel):
    accepted: bool
    source_slug: str
    run_mode: RunMode
    parser_version: str
    message: str
    scrape_run_id: str | None = None
    date_from: date | None = None
    date_to: date | None = None
    artifact_count: int = 0
    parse_result_count: int = 0
    normalized_record_count: int = 0
    request_context: dict[str, Any] = Field(default_factory=dict)
    warnings: list[str] = Field(default_factory=list)


class TriggerRunRequest(BaseModel):
    run_mode: RunMode = "incremental"


class OpsPlatformSummary(BaseModel):
    platform_id: str
    platform_slug: str
    platform_name: str
    base_domain: str | None = None
    status: str
    source_count: int = 0
    healthy_source_count: int = 0
    warning_source_count: int = 0
    stale_source_count: int = 0
    latest_success_at: datetime | None = None


class OpsSourceSummary(BaseModel):
    source_id: str
    platform_id: str | None = None
    platform_slug: str | None = None
    source_slug: str
    source_name: str
    platform_name: str
    jurisdiction_name: str
    source_type: str
    cadence_type: str
    target_freshness_days: int
    parser_version: str
    status: str
    last_run_id: str | None = None
    last_run_status: str | None = None
    last_started_at: datetime | None = None
    last_completed_at: datetime | None = None
    latest_success_at: datetime | None = None
    freshness_age_days: int | None = None


class OpsRunSummary(BaseModel):
    scrape_run_id: str
    source_id: str
    source_slug: str
    source_name: str
    run_mode: str
    trigger_type: str
    run_status: str
    parser_version: str
    started_at: datetime
    completed_at: datetime | None = None
    artifact_count: int
    parsed_record_count: int
    normalized_record_count: int
    warning_count: int
    error_count: int
    error_summary: str | None = None


class OpsArtifactSummary(BaseModel):
    raw_artifact_id: str
    artifact_type: str
    source_url: str
    storage_path: str
    fetched_at: datetime


class OpsParseResultSummary(BaseModel):
    parse_result_id: str
    record_type: str
    source_record_key: str | None = None
    parse_status: str
    warning_count: int
    error_count: int
    created_at: datetime
    payload: dict[str, Any]


class OpsWarningSummary(BaseModel):
    parser_warning_id: str
    parse_result_id: str
    warning_code: str
    warning_message: str
    created_at: datetime


class OpsRunIssueSummary(BaseModel):
    scrape_run_issue_id: str
    severity: str
    category: str
    issue_code: str
    issue_message: str
    component: str | None = None
    stage: str | None = None
    parse_result_id: str | None = None
    raw_artifact_id: str | None = None
    source_record_key: str | None = None
    source_url: str | None = None
    issue_metadata: dict[str, Any] = Field(default_factory=dict)
    created_at: datetime


class OpsRunDetail(BaseModel):
    run: OpsRunSummary
    request_context: dict[str, Any] = Field(default_factory=dict)
    source_snapshot: dict[str, Any] = Field(default_factory=dict)
    artifacts: list[OpsArtifactSummary] = Field(default_factory=list)
    parse_results: list[OpsParseResultSummary] = Field(default_factory=list)
    issues: list[OpsRunIssueSummary] = Field(default_factory=list)
    warnings: list[OpsWarningSummary] = Field(default_factory=list)


class OpsArtifactDetail(OpsArtifactSummary):
    content_hash: str
    source_id: str
    scrape_run_id: str


class OpsAlertSummary(BaseModel):
    operational_alert_id: str
    source_id: str | None = None
    scrape_run_id: str | None = None
    source_slug: str | None = None
    source_name: str | None = None
    alert_type: str
    severity: str
    status: str
    title: str
    message: str
    created_at: datetime
    updated_at: datetime


class OpsHealthSummary(BaseModel):
    total_platforms: int
    total_sources: int
    healthy_sources: int
    warning_sources: int
    stale_sources: int
    latest_run_started_at: datetime | None = None
    latest_success_completed_at: datetime | None = None
    open_alert_count: int = 0


class OpsRerunSummary(BaseModel):
    rerun_request_id: str
    source_id: str
    source_slug: str
    source_name: str
    requested_scope: str
    requested_by: str | None = None
    request_payload: dict[str, Any] = Field(default_factory=dict)
    status: str
    created_at: datetime
    updated_at: datetime


class CreateRerunRequest(BaseModel):
    source_slug: str
    requested_scope: str = "incremental"
    requested_by: str | None = "control-panel"
    request_payload: dict[str, Any] = Field(default_factory=dict)


class MasterInspectionLineageSummary(BaseModel):
    master_restaurant_id: str
    display_name: str
    city: str
    state_code: str
    source_slug: str
    source_inspection_key: str
    master_inspection_id: str
    inspection_date: date
    inspection_type: str | None = None
    report_availability_status: str | None = None
    finding_count: int = 0


class OpsMasterDataQualitySummary(BaseModel):
    total_restaurants: int
    total_inspections: int
    total_reports: int
    total_findings: int
    restaurants_without_source_links: int = 0
    restaurants_without_identifiers: int = 0
    duplicate_risk_restaurants: int = 0
    inspections_missing_reports: int = 0
    reports_missing_storage: int = 0
    findings_missing_detail: int = 0


class OpsMasterRestaurantSummary(BaseModel):
    master_restaurant_id: str
    display_name: str
    normalized_name: str | None = None
    address_line1: str
    city: str
    state_code: str
    zip_code: str | None = None
    status: str
    location_fingerprint: str
    inspection_count: int = 0
    source_link_count: int = 0
    identifier_count: int = 0
    latest_inspection_date: date | None = None
    report_gap_count: int = 0
    duplicate_group_size: int = 1
    created_at: datetime
    updated_at: datetime


class OpsMasterRestaurantIdentifierSummary(BaseModel):
    master_restaurant_identifier_id: str
    source_slug: str | None = None
    identifier_type: str
    identifier_value: str
    is_primary: bool = False
    confidence: float | None = None
    updated_at: datetime


class OpsMasterRestaurantSourceLinkSummary(BaseModel):
    master_restaurant_source_link_id: str
    source_id: str
    source_slug: str
    source_name: str
    source_restaurant_key: str
    match_method: str
    match_confidence: float | None = None
    match_status: str
    matched_at: datetime
    inspection_count: int = 0
    latest_inspection_date: date | None = None


class OpsMasterRestaurantDetail(BaseModel):
    restaurant: OpsMasterRestaurantSummary
    identifiers: list[OpsMasterRestaurantIdentifierSummary] = Field(default_factory=list)
    source_links: list[OpsMasterRestaurantSourceLinkSummary] = Field(default_factory=list)
    inspections: list["OpsMasterInspectionSummary"] = Field(default_factory=list)


class OpsMasterInspectionSummary(BaseModel):
    master_inspection_id: str
    master_restaurant_id: str
    display_name: str
    city: str
    state_code: str
    source_id: str
    source_slug: str
    source_name: str
    source_inspection_key: str
    inspection_date: date
    inspection_type: str | None = None
    score: float | None = None
    grade: str | None = None
    official_status: str | None = None
    report_url: str | None = None
    report_availability_status: str | None = None
    report_format: str | None = None
    report_storage_path: str | None = None
    finding_count: int = 0
    created_at: datetime
    updated_at: datetime


class OpsMasterInspectionReportSummary(BaseModel):
    master_inspection_report_id: str
    master_inspection_id: str
    source_id: str
    source_slug: str
    source_name: str
    display_name: str
    inspection_date: date
    report_role: str
    report_format: str | None = None
    availability_status: str
    source_page_url: str | None = None
    source_file_url: str | None = None
    storage_path: str | None = None
    is_current: bool = True
    created_at: datetime
    updated_at: datetime


class OpsMasterFindingSummary(BaseModel):
    master_inspection_finding_id: str
    master_inspection_id: str
    master_restaurant_id: str
    display_name: str
    source_id: str
    source_slug: str
    source_name: str
    inspection_date: date
    source_finding_key: str | None = None
    finding_order: int | None = None
    official_code: str | None = None
    official_clause_reference: str | None = None
    official_text: str
    official_detail_text: str | None = None
    normalized_title: str | None = None
    normalized_category: str | None = None
    severity: str | None = None
    corrected_during_inspection: bool | None = None
    is_repeat_violation: bool | None = None
    created_at: datetime
    updated_at: datetime


class OpsMasterInspectionDetail(BaseModel):
    inspection: OpsMasterInspectionSummary
    reports: list[OpsMasterInspectionReportSummary] = Field(default_factory=list)
    findings: list[OpsMasterFindingSummary] = Field(default_factory=list)
    related_runs: list[OpsRunSummary] = Field(default_factory=list)


class AdminRestaurantInspectionDetail(BaseModel):
    inspection: OpsMasterInspectionSummary
    reports: list[OpsMasterInspectionReportSummary] = Field(default_factory=list)
    findings: list[OpsMasterFindingSummary] = Field(default_factory=list)


class AdminRestaurantDetail(BaseModel):
    restaurant: OpsMasterRestaurantSummary
    identifiers: list[OpsMasterRestaurantIdentifierSummary] = Field(default_factory=list)
    source_links: list[OpsMasterRestaurantSourceLinkSummary] = Field(default_factory=list)
    inspections: list[AdminRestaurantInspectionDetail] = Field(default_factory=list)


class SourceVersionSummary(BaseModel):
    source_version_id: str
    source_slug: str
    entity_type: str
    source_entity_key: str | None = None
    version_number: int
    is_current: bool
    change_type: str
    effective_at: datetime
