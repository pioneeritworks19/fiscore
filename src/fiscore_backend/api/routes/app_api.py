from pydantic import BaseModel, Field
from fastapi import APIRouter, HTTPException

from fiscore_backend.ops.repository import get_admin_restaurant_detail, list_admin_restaurants_page


router = APIRouter(prefix="/app", tags=["app"])


class AppMasterRestaurantSummary(BaseModel):
    master_restaurant_id: str
    display_name: str
    address_line1: str
    city: str
    state_code: str
    zip_code: str | None = None
    status: str
    inspection_count: int = 0
    latest_inspection_date: str | None = None
    source_link_count: int = 0


class AppMasterInspectionFinding(BaseModel):
    master_finding_id: str
    source_finding_key: str | None = None
    finding_order: int | None = None
    official_code: str | None = None
    official_clause_reference: str | None = None
    official_text: str
    official_detail_text: str | None = None
    auditor_comments: str | None = None
    normalized_title: str | None = None
    normalized_category: str | None = None
    severity: str | None = None
    corrected_during_inspection: bool | None = None
    is_repeat_violation: bool | None = None


class AppMasterInspection(BaseModel):
    master_inspection_id: str
    source_id: str
    source_slug: str
    source_name: str
    source_inspection_key: str
    inspection_date: str
    inspection_type: str | None = None
    score: float | None = None
    grade: str | None = None
    official_status: str | None = None
    report_url: str | None = None
    report_availability_status: str | None = None
    report_format: str | None = None
    report_storage_path: str | None = None
    findings: list[AppMasterInspectionFinding] = Field(default_factory=list)


class AppMasterRestaurantDetail(BaseModel):
    restaurant: AppMasterRestaurantSummary
    inspections: list[AppMasterInspection] = Field(default_factory=list)


def _restaurant_summary(item) -> AppMasterRestaurantSummary:
    return AppMasterRestaurantSummary(
        master_restaurant_id=item.master_restaurant_id,
        display_name=item.display_name,
        address_line1=item.address_line1,
        city=item.city,
        state_code=item.state_code,
        zip_code=item.zip_code,
        status=item.status,
        inspection_count=item.inspection_count,
        latest_inspection_date=(
            item.latest_inspection_date.isoformat()
            if item.latest_inspection_date is not None
            else None
        ),
        source_link_count=item.source_link_count,
    )


def _inspection_payload(item) -> AppMasterInspection:
    inspection = item.inspection
    return AppMasterInspection(
        master_inspection_id=inspection.master_inspection_id,
        source_id=inspection.source_id,
        source_slug=inspection.source_slug,
        source_name=inspection.source_name,
        source_inspection_key=inspection.source_inspection_key,
        inspection_date=inspection.inspection_date.isoformat(),
        inspection_type=inspection.inspection_type,
        score=inspection.score,
        grade=inspection.grade,
        official_status=inspection.official_status,
        report_url=inspection.report_url,
        report_availability_status=inspection.report_availability_status,
        report_format=inspection.report_format,
        report_storage_path=inspection.report_storage_path,
        findings=[
            AppMasterInspectionFinding(
                master_finding_id=finding.master_inspection_finding_id,
                source_finding_key=finding.source_finding_key,
                finding_order=finding.finding_order,
                official_code=finding.official_code,
                official_clause_reference=finding.official_clause_reference,
                official_text=finding.official_text,
                official_detail_text=finding.official_detail_text,
                auditor_comments=finding.auditor_comments,
                normalized_title=finding.normalized_title,
                normalized_category=finding.normalized_category,
                severity=finding.severity,
                corrected_during_inspection=finding.corrected_during_inspection,
                is_repeat_violation=finding.is_repeat_violation,
            )
            for finding in item.findings
        ],
    )


@router.get("/master-restaurants", response_model=list[AppMasterRestaurantSummary])
def search_master_restaurants(q: str, page_size: int = 10) -> list[AppMasterRestaurantSummary]:
    query = q.strip()
    if len(query) < 2:
        raise HTTPException(status_code=400, detail="Search text must be at least 2 characters.")

    safe_page_size = min(max(page_size, 1), 10)
    restaurants, _ = list_admin_restaurants_page(
        page=1,
        page_size=safe_page_size,
        query=query,
        has_inspections=True,
    )
    return [_restaurant_summary(item) for item in restaurants]


@router.get("/master-restaurants/{master_restaurant_id}", response_model=AppMasterRestaurantDetail)
def get_master_restaurant(master_restaurant_id: str) -> AppMasterRestaurantDetail:
    detail = get_admin_restaurant_detail(master_restaurant_id)
    if detail is None:
        raise HTTPException(status_code=404, detail="Master restaurant was not found.")
    return AppMasterRestaurantDetail(
        restaurant=_restaurant_summary(detail.restaurant),
        inspections=[_inspection_payload(item) for item in detail.inspections],
    )
