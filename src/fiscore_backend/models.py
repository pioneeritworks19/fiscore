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
