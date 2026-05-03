from __future__ import annotations

import json
from typing import Any

from fiscore_backend.db import get_connection


def create_scrape_run_issue(
    *,
    scrape_run_id: str,
    source_id: str,
    severity: str,
    category: str,
    code: str,
    message: str,
    component: str | None = None,
    stage: str | None = None,
    parse_result_id: str | None = None,
    raw_artifact_id: str | None = None,
    source_record_key: str | None = None,
    source_url: str | None = None,
    issue_metadata: dict[str, Any] | None = None,
) -> str:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into ops.scrape_run_issue (
                    scrape_run_id,
                    source_id,
                    severity,
                    category,
                    issue_code,
                    issue_message,
                    component,
                    stage,
                    parse_result_id,
                    raw_artifact_id,
                    source_record_key,
                    source_url,
                    issue_metadata
                )
                values (
                    %s::uuid,
                    %s::uuid,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s::uuid,
                    %s::uuid,
                    %s,
                    %s,
                    %s::jsonb
                )
                returning scrape_run_issue_id::text
                """,
                (
                    scrape_run_id,
                    source_id,
                    severity,
                    category,
                    code,
                    message,
                    component,
                    stage,
                    parse_result_id,
                    raw_artifact_id,
                    source_record_key,
                    source_url,
                    json.dumps(issue_metadata or {}),
                ),
            )
            issue_id = cur.fetchone()[0]
        conn.commit()
    return issue_id


def summarize_scrape_run_issues(scrape_run_id: str) -> tuple[int, int]:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select
                    count(*) filter (where severity = 'warning')::int as warning_count,
                    count(*) filter (where severity = 'error')::int as error_count
                from ops.scrape_run_issue
                where scrape_run_id = %s::uuid
                """,
                (scrape_run_id,),
            )
            row = cur.fetchone()
    if row is None:
        return 0, 0
    return row[0] or 0, row[1] or 0
