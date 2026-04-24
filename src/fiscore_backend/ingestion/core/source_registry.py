from dataclasses import dataclass

from psycopg.rows import dict_row

from fiscore_backend.db import get_connection
from fiscore_backend.models import WorkerRunRequest


@dataclass(frozen=True)
class SourceRegistryRecord:
    source_id: str
    source_slug: str
    source_name: str
    platform_name: str
    jurisdiction_name: str
    base_url: str
    parser_version: str


def get_source_by_slug(source_slug: str) -> SourceRegistryRecord | None:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    source_id::text as source_id,
                    source_slug,
                    source_name,
                    platform_name,
                    jurisdiction_name,
                    base_url,
                    parser_version
                from ops.source_registry
                where source_slug = %s
                """,
                (source_slug,),
            )
            row = cur.fetchone()

    if row is None:
        return None

    return SourceRegistryRecord(**row)


def create_scrape_run(source_id: str, request: WorkerRunRequest, parser_version: str) -> str:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into ops.scrape_run (
                    source_id,
                    run_mode,
                    trigger_type,
                    run_status,
                    parser_version
                )
                values (%s, %s, %s, %s, %s)
                returning scrape_run_id::text as scrape_run_id
                """,
                (
                    source_id,
                    request.run_mode,
                    request.trigger_type,
                    "queued",
                    parser_version,
                ),
            )
            scrape_run_id = cur.fetchone()[0]
        conn.commit()

    return scrape_run_id
