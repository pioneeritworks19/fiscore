from dataclasses import dataclass
import json
from typing import Any

from psycopg.rows import dict_row

from fiscore_backend.db import get_connection
from fiscore_backend.models import WorkerRunRequest


@dataclass(frozen=True)
class SourceRegistryRecord:
    source_id: str
    platform_id: str | None
    platform_slug: str | None
    source_slug: str
    source_name: str
    platform_name: str
    jurisdiction_name: str
    base_url: str
    source_config: dict[str, Any]
    parser_id: str
    parser_version: str


def get_source_by_slug(source_slug: str) -> SourceRegistryRecord | None:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    source_id::text as source_id,
                    sr.platform_id::text as platform_id,
                    pr.platform_slug,
                    source_slug,
                    source_name,
                    sr.platform_name,
                    jurisdiction_name,
                    base_url,
                    source_config,
                    parser_id,
                    parser_version
                from ops.source_registry sr
                left join ops.platform_registry pr on pr.platform_id = sr.platform_id
                where source_slug = %s
                """,
                (source_slug,),
            )
            row = cur.fetchone()

    if row is None:
        return None

    row["source_config"] = row.get("source_config") or {}
    return SourceRegistryRecord(**row)


def create_scrape_run(
    source_id: str,
    request: WorkerRunRequest,
    parser_version: str,
    *,
    request_context: dict | None = None,
    source_snapshot: dict | None = None,
) -> str:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into ops.scrape_run (
                    source_id,
                    run_mode,
                    trigger_type,
                    run_status,
                    parser_version,
                    request_context,
                    source_snapshot
                )
                values (%s, %s, %s, %s, %s, %s::jsonb, %s::jsonb)
                returning scrape_run_id::text as scrape_run_id
                """,
                (
                    source_id,
                    request.run_mode,
                    request.trigger_type,
                    "queued",
                    parser_version,
                    json.dumps(request_context or {}),
                    json.dumps(source_snapshot or {}),
                ),
            )
            scrape_run_id = cur.fetchone()[0]
        conn.commit()

    return scrape_run_id
