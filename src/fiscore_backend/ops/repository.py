from __future__ import annotations

import json
from typing import Any

from psycopg.rows import dict_row

from fiscore_backend.db import get_connection
from fiscore_backend.models import (
    CreateRerunRequest,
    MasterInspectionLineageSummary,
    OpsAlertSummary,
    OpsArtifactDetail,
    OpsArtifactSummary,
    OpsHealthSummary,
    OpsParseResultSummary,
    OpsPlatformSummary,
    OpsRunIssueSummary,
    OpsRerunSummary,
    OpsRunDetail,
    OpsRunSummary,
    OpsSourceSummary,
    OpsWarningSummary,
    SourceVersionSummary,
)


def _decode_jsonish(value: Any) -> dict[str, Any]:
    if value is None:
        return {}
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            decoded = json.loads(value)
        except json.JSONDecodeError:
            return {}
        return decoded if isinstance(decoded, dict) else {}
    return {}


def _like_pattern(query: str | None) -> str | None:
    if not query:
        return None
    cleaned = query.strip()
    return f"%{cleaned}%" if cleaned else None


def _normalize_page(page: int, page_size: int, *, default_size: int = 50, max_size: int = 250) -> tuple[int, int]:
    safe_page = max(page, 1)
    safe_size = min(max(page_size, 1), max_size) if page_size else default_size
    return safe_page, safe_size


def list_platforms() -> list[OpsPlatformSummary]:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                with latest_success as (
                    select
                        r.source_id,
                        max(r.completed_at) as latest_success_at
                    from ops.scrape_run r
                    where r.run_status in ('completed', 'completed_with_warnings')
                    group by r.source_id
                ),
                source_status as (
                    select
                        sr.source_id,
                        sr.platform_id,
                        case
                            when ls.latest_success_at is null then 'stale'
                            when floor(extract(epoch from (now() - ls.latest_success_at)) / 86400)::int > sr.target_freshness_days then 'stale'
                            when lr.run_status in ('completed_with_warnings', 'running', 'queued') then 'warning'
                            else 'healthy'
                        end as effective_status,
                        ls.latest_success_at
                    from ops.source_registry sr
                    left join latest_success ls on ls.source_id = sr.source_id
                    left join lateral (
                        select run_status
                        from ops.scrape_run r
                        where r.source_id = sr.source_id
                        order by r.started_at desc
                        limit 1
                    ) lr on true
                )
                select
                    pr.platform_id::text as platform_id,
                    pr.platform_slug,
                    pr.platform_name,
                    pr.base_domain,
                    pr.status,
                    count(sr.source_id)::int as source_count,
                    count(*) filter (where ss.effective_status = 'healthy')::int as healthy_source_count,
                    count(*) filter (where ss.effective_status = 'warning')::int as warning_source_count,
                    count(*) filter (where ss.effective_status = 'stale')::int as stale_source_count,
                    max(ss.latest_success_at) as latest_success_at
                from ops.platform_registry pr
                left join ops.source_registry sr on sr.platform_id = pr.platform_id
                left join source_status ss on ss.source_id = sr.source_id
                group by
                    pr.platform_id,
                    pr.platform_slug,
                    pr.platform_name,
                    pr.base_domain,
                    pr.status
                order by pr.platform_name
                """
            )
            rows = cur.fetchall()
    return [OpsPlatformSummary(**row) for row in rows]


def list_sources(*, limit: int = 250) -> list[OpsSourceSummary]:
    return list_sources_page(page=1, page_size=limit)[0]


def list_sources_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    platform_slug: str | None = None,
    never_run_only: bool = False,
) -> tuple[list[OpsSourceSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                sr.source_slug ilike %s
                or sr.source_name ilike %s
                or sr.platform_name ilike %s
                or sr.jurisdiction_name ilike %s
                or coalesce(pr.platform_slug, '') ilike %s
            )
            """
        )
        params.extend([search, search, search, search, search])
    if platform_slug:
        where_parts.append("coalesce(pr.platform_slug, '') = %s")
        params.append(platform_slug)
    if never_run_only:
        where_parts.append(
            """
            not exists (
                select 1
                from ops.scrape_run r
                where r.source_id = sr.source_id
            )
            """
        )
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from ops.source_registry sr
        left join ops.platform_registry pr on pr.platform_id = sr.platform_id
        {where_sql}
    """
    data_sql = f"""
        select
            sr.source_id::text as source_id,
            sr.platform_id::text as platform_id,
            pr.platform_slug,
            sr.source_slug,
            sr.source_name,
            sr.platform_name,
            sr.jurisdiction_name,
            sr.source_type,
            sr.cadence_type,
            sr.target_freshness_days,
            sr.parser_version,
            sr.status,
            last_run.scrape_run_id::text as last_run_id,
            last_run.run_status as last_run_status,
            last_run.started_at as last_started_at,
            last_run.completed_at as last_completed_at,
            latest_success.completed_at as latest_success_at,
            case
                when latest_success.completed_at is null then null
                else floor(extract(epoch from (now() - latest_success.completed_at)) / 86400)::int
            end as freshness_age_days
        from ops.source_registry sr
        left join ops.platform_registry pr on pr.platform_id = sr.platform_id
        left join lateral (
            select *
            from ops.scrape_run r
            where r.source_id = sr.source_id
            order by r.started_at desc
            limit 1
        ) last_run on true
        left join lateral (
            select completed_at
            from ops.scrape_run r
            where
                r.source_id = sr.source_id
                and r.run_status in ('completed', 'completed_with_warnings')
            order by r.completed_at desc nulls last
            limit 1
        ) latest_success on true
        {where_sql}
        order by sr.platform_name, sr.jurisdiction_name, sr.source_name
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsSourceSummary(**row) for row in rows], total_count


def list_runs(*, limit: int = 100) -> list[OpsRunSummary]:
    return list_runs_page(page=1, page_size=limit)[0]


def list_runs_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    source_slug: str | None = None,
) -> tuple[list[OpsRunSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                sr.source_slug ilike %s
                or sr.source_name ilike %s
                or r.run_mode ilike %s
                or r.run_status ilike %s
                or r.trigger_type ilike %s
            )
            """
        )
        params.extend([search, search, search, search, search])
    if source_slug:
        where_parts.append("sr.source_slug = %s")
        params.append(source_slug)
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from ops.scrape_run r
        join ops.source_registry sr on sr.source_id = r.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            r.scrape_run_id::text as scrape_run_id,
            r.source_id::text as source_id,
            sr.source_slug,
            sr.source_name,
            r.run_mode,
            r.trigger_type,
            r.run_status,
            r.parser_version,
            r.started_at,
            r.completed_at,
            r.artifact_count,
            r.parsed_record_count,
            r.normalized_record_count,
            r.warning_count,
            r.error_count,
            r.error_summary
        from ops.scrape_run r
        join ops.source_registry sr on sr.source_id = r.source_id
        {where_sql}
        order by r.started_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsRunSummary(**row) for row in rows], total_count


def get_run_detail(scrape_run_id: str) -> OpsRunDetail | None:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    r.scrape_run_id::text as scrape_run_id,
                    r.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    r.run_mode,
                    r.trigger_type,
                    r.run_status,
                    r.parser_version,
                    r.started_at,
                    r.completed_at,
                    r.artifact_count,
                    r.parsed_record_count,
                    r.normalized_record_count,
                    r.warning_count,
                    r.error_count,
                    r.error_summary,
                    r.request_context,
                    r.source_snapshot
                from ops.scrape_run r
                join ops.source_registry sr on sr.source_id = r.source_id
                where r.scrape_run_id = %s::uuid
                limit 1
                """,
                (scrape_run_id,),
            )
            row = cur.fetchone()
            if row is None:
                return None

            run = OpsRunSummary(
                scrape_run_id=row["scrape_run_id"],
                source_id=row["source_id"],
                source_slug=row["source_slug"],
                source_name=row["source_name"],
                run_mode=row["run_mode"],
                trigger_type=row["trigger_type"],
                run_status=row["run_status"],
                parser_version=row["parser_version"],
                started_at=row["started_at"],
                completed_at=row["completed_at"],
                artifact_count=row["artifact_count"],
                parsed_record_count=row["parsed_record_count"],
                normalized_record_count=row["normalized_record_count"],
                warning_count=row["warning_count"],
                error_count=row["error_count"],
                error_summary=row["error_summary"],
            )

            cur.execute(
                """
                select
                    raw_artifact_id::text as raw_artifact_id,
                    artifact_type,
                    source_url,
                    storage_path,
                    fetched_at
                from ingestion.raw_artifact_index
                where scrape_run_id = %s::uuid
                order by fetched_at desc
                limit 100
                """,
                (scrape_run_id,),
            )
            artifacts = [OpsArtifactSummary(**artifact) for artifact in cur.fetchall()]

            cur.execute(
                """
                select
                    parse_result_id::text as parse_result_id,
                    record_type,
                    source_record_key,
                    parse_status,
                    warning_count,
                    error_count,
                    created_at,
                    payload
                from ingestion.parse_result
                where scrape_run_id = %s::uuid
                order by created_at desc
                limit 200
                """,
                (scrape_run_id,),
            )
            parse_results = [
                OpsParseResultSummary(
                    **{
                        **parse_result,
                        "payload": (
                            parse_result["payload"]
                            if isinstance(parse_result["payload"], dict)
                            else _decode_jsonish(parse_result["payload"])
                        ),
                    }
                )
                for parse_result in cur.fetchall()
            ]

            cur.execute(
                """
                select
                    sri.scrape_run_issue_id::text as scrape_run_issue_id,
                    sri.severity,
                    sri.category,
                    sri.issue_code,
                    sri.issue_message,
                    sri.component,
                    sri.stage,
                    sri.parse_result_id::text as parse_result_id,
                    sri.raw_artifact_id::text as raw_artifact_id,
                    sri.source_record_key,
                    sri.source_url,
                    sri.issue_metadata,
                    sri.created_at
                from ops.scrape_run_issue sri
                where sri.scrape_run_id = %s::uuid
                order by
                    case sri.severity
                        when 'error' then 0
                        when 'warning' then 1
                        else 2
                    end,
                    sri.created_at desc
                limit 200
                """,
                (scrape_run_id,),
            )
            issues = [
                OpsRunIssueSummary(
                    **{
                        **issue,
                        "issue_metadata": (
                            issue["issue_metadata"]
                            if isinstance(issue["issue_metadata"], dict)
                            else _decode_jsonish(issue["issue_metadata"])
                        ),
                    }
                )
                for issue in cur.fetchall()
            ]

            cur.execute(
                """
                select
                    pw.parser_warning_id::text as parser_warning_id,
                    pw.parse_result_id::text as parse_result_id,
                    pw.warning_code,
                    pw.warning_message,
                    pw.created_at
                from ingestion.parser_warning pw
                join ingestion.parse_result pr on pr.parse_result_id = pw.parse_result_id
                where pr.scrape_run_id = %s::uuid
                order by pw.created_at desc
                limit 200
                """,
                (scrape_run_id,),
            )
            warnings = [OpsWarningSummary(**warning) for warning in cur.fetchall()]

    return OpsRunDetail(
        run=run,
        request_context=_decode_jsonish(row["request_context"]),
        source_snapshot=_decode_jsonish(row["source_snapshot"]),
        artifacts=artifacts,
        parse_results=parse_results,
        issues=issues,
        warnings=warnings,
    )


def list_artifacts(*, limit: int = 200) -> list[OpsArtifactSummary]:
    return list_artifacts_page(page=1, page_size=limit)[0]


def list_artifacts_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
) -> tuple[list[OpsArtifactSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_sql = ""
    params: list[Any] = []
    if search is not None:
        where_sql = """
        where (
            rai.artifact_type ilike %s
            or rai.source_url ilike %s
            or rai.storage_path ilike %s
            or coalesce(sr.source_slug, '') ilike %s
        )
        """
        params.extend([search, search, search, search])

    count_sql = f"""
        select count(*)::int as total_count
        from ingestion.raw_artifact_index rai
        left join ops.source_registry sr on sr.source_id = rai.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            raw_artifact_id::text as raw_artifact_id,
            artifact_type,
            source_url,
            storage_path,
            fetched_at
        from ingestion.raw_artifact_index rai
        left join ops.source_registry sr on sr.source_id = rai.source_id
        {where_sql}
        order by fetched_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsArtifactSummary(**row) for row in rows], total_count


def get_artifact_detail(raw_artifact_id: str) -> OpsArtifactDetail | None:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    raw_artifact_id::text as raw_artifact_id,
                    source_id::text as source_id,
                    scrape_run_id::text as scrape_run_id,
                    artifact_type,
                    source_url,
                    storage_path,
                    content_hash,
                    fetched_at
                from ingestion.raw_artifact_index
                where raw_artifact_id = %s::uuid
                limit 1
                """,
                (raw_artifact_id,),
            )
            row = cur.fetchone()
    return OpsArtifactDetail(**row) if row else None


def list_parse_results(*, limit: int = 200) -> list[OpsParseResultSummary]:
    return list_parse_results_page(page=1, page_size=limit)[0]


def list_parse_results_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    record_type: str | None = None,
) -> tuple[list[OpsParseResultSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                pr.record_type ilike %s
                or coalesce(pr.source_record_key, '') ilike %s
                or pr.parse_status ilike %s
                or cast(pr.payload as text) ilike %s
            )
            """
        )
        params.extend([search, search, search, search])
    if record_type:
        where_parts.append("pr.record_type = %s")
        params.append(record_type)
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from ingestion.parse_result pr
        {where_sql}
    """
    data_sql = f"""
        select
            parse_result_id::text as parse_result_id,
            record_type,
            source_record_key,
            parse_status,
            warning_count,
            error_count,
            created_at,
            payload
        from ingestion.parse_result pr
        {where_sql}
        order by created_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [
        OpsParseResultSummary(
            **{
                **row,
                "payload": row["payload"] if isinstance(row["payload"], dict) else _decode_jsonish(row["payload"]),
            }
        )
        for row in rows
    ], total_count


def get_parse_result_detail(parse_result_id: str) -> OpsParseResultSummary | None:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    parse_result_id::text as parse_result_id,
                    record_type,
                    source_record_key,
                    parse_status,
                    warning_count,
                    error_count,
                    created_at,
                    payload
                from ingestion.parse_result
                where parse_result_id = %s::uuid
                limit 1
                """,
                (parse_result_id,),
            )
            row = cur.fetchone()
    if row is None:
        return None
    return OpsParseResultSummary(
        **{**row, "payload": row["payload"] if isinstance(row["payload"], dict) else _decode_jsonish(row["payload"])}
    )


def list_alerts(*, limit: int = 100) -> list[OpsAlertSummary]:
    return list_alerts_page(page=1, page_size=limit)[0]


def list_alerts_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
) -> tuple[list[OpsAlertSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_sql = ""
    params: list[Any] = []
    if search is not None:
        where_sql = """
        where (
            oa.alert_type ilike %s
            or oa.severity ilike %s
            or oa.status ilike %s
            or oa.title ilike %s
            or oa.message ilike %s
            or coalesce(sr.source_slug, '') ilike %s
        )
        """
        params.extend([search, search, search, search, search, search])

    count_sql = f"""
        select count(*)::int as total_count
        from ops.operational_alert oa
        left join ops.source_registry sr on sr.source_id = oa.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            oa.operational_alert_id::text as operational_alert_id,
            oa.source_id::text as source_id,
            oa.scrape_run_id::text as scrape_run_id,
            sr.source_slug,
            sr.source_name,
            oa.alert_type,
            oa.severity,
            oa.status,
            oa.title,
            oa.message,
            oa.created_at,
            oa.updated_at
        from ops.operational_alert oa
        left join ops.source_registry sr on sr.source_id = oa.source_id
        {where_sql}
        order by oa.created_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsAlertSummary(**row) for row in rows], total_count


def get_health_summary() -> OpsHealthSummary:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                with source_status as (
                    select
                        sr.source_id,
                        case
                            when latest_success.completed_at is null then 'stale'
                            when floor(extract(epoch from (now() - latest_success.completed_at)) / 86400)::int > sr.target_freshness_days then 'stale'
                            when last_run.run_status in ('completed_with_warnings', 'running', 'queued') then 'warning'
                            else 'healthy'
                        end as effective_status
                    from ops.source_registry sr
                    left join lateral (
                        select *
                        from ops.scrape_run r
                        where r.source_id = sr.source_id
                        order by r.started_at desc
                        limit 1
                    ) last_run on true
                    left join lateral (
                        select completed_at
                        from ops.scrape_run r
                        where
                            r.source_id = sr.source_id
                            and r.run_status in ('completed', 'completed_with_warnings')
                        order by r.completed_at desc nulls last
                        limit 1
                    ) latest_success on true
                )
                select
                    (select count(*) from ops.platform_registry)::int as total_platforms,
                    (select count(*) from ops.source_registry)::int as total_sources,
                    (select count(*) from source_status where effective_status = 'healthy')::int as healthy_sources,
                    (select count(*) from source_status where effective_status = 'warning')::int as warning_sources,
                    (select count(*) from source_status where effective_status = 'stale')::int as stale_sources,
                    (select max(started_at) from ops.scrape_run) as latest_run_started_at,
                    (select max(completed_at) from ops.scrape_run where run_status in ('completed', 'completed_with_warnings')) as latest_success_completed_at,
                    (select count(*) from ops.operational_alert where status = 'open')::int as open_alert_count
                """
            )
            row = cur.fetchone()
    return OpsHealthSummary(**row)


def list_reruns(*, limit: int = 100) -> list[OpsRerunSummary]:
    return list_reruns_page(page=1, page_size=limit)[0]


def list_reruns_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
) -> tuple[list[OpsRerunSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_sql = ""
    params: list[Any] = []
    if search is not None:
        where_sql = """
        where (
            sr.source_slug ilike %s
            or sr.source_name ilike %s
            or rr.requested_scope ilike %s
            or coalesce(rr.requested_by, '') ilike %s
            or rr.status ilike %s
        )
        """
        params.extend([search, search, search, search, search])

    count_sql = f"""
        select count(*)::int as total_count
        from ops.rerun_request rr
        join ops.source_registry sr on sr.source_id = rr.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            rr.rerun_request_id::text as rerun_request_id,
            rr.source_id::text as source_id,
            sr.source_slug,
            sr.source_name,
            rr.requested_scope,
            rr.requested_by,
            rr.request_payload,
            rr.status,
            rr.created_at,
            rr.updated_at
        from ops.rerun_request rr
        join ops.source_registry sr on sr.source_id = rr.source_id
        {where_sql}
        order by rr.created_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [
        OpsRerunSummary(
            **{
                **row,
                "request_payload": (
                    row["request_payload"] if isinstance(row["request_payload"], dict) else _decode_jsonish(row["request_payload"])
                ),
            }
        )
        for row in rows
    ], total_count


def create_rerun_request(request: CreateRerunRequest) -> OpsRerunSummary:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select source_id::text as source_id, source_slug, source_name
                from ops.source_registry
                where source_slug = %s
                limit 1
                """,
                (request.source_slug,),
            )
            source = cur.fetchone()
            if source is None:
                raise ValueError(f"Source {request.source_slug} was not found.")

            cur.execute(
                """
                insert into ops.rerun_request (
                    source_id,
                    requested_scope,
                    requested_by,
                    request_payload,
                    status
                )
                values (%s::uuid, %s, %s, %s::jsonb, 'pending')
                returning
                    rerun_request_id::text as rerun_request_id,
                    source_id::text as source_id,
                    requested_scope,
                    requested_by,
                    request_payload,
                    status,
                    created_at,
                    updated_at
                """,
                (
                    source["source_id"],
                    request.requested_scope,
                    request.requested_by,
                    json.dumps(request.request_payload),
                ),
            )
            row = cur.fetchone()
        conn.commit()
    return OpsRerunSummary(
        source_slug=source["source_slug"],
        source_name=source["source_name"],
        request_payload=row["request_payload"] if isinstance(row["request_payload"], dict) else _decode_jsonish(row["request_payload"]),
        **{k: v for k, v in row.items() if k != "request_payload"},
    )


def list_lineage(*, limit: int = 200) -> list[MasterInspectionLineageSummary]:
    return list_lineage_page(page=1, page_size=limit)[0]


def list_lineage_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
) -> tuple[list[MasterInspectionLineageSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_sql = ""
    params: list[Any] = []
    if search is not None:
        where_sql = """
        where (
            mr.display_name ilike %s
            or mr.city ilike %s
            or sr.source_slug ilike %s
            or mi.source_inspection_key ilike %s
            or coalesce(mi.inspection_type, '') ilike %s
        )
        """
        params.extend([search, search, search, search, search])

    count_sql = f"""
        select count(*)::int as total_count
        from master.master_inspection mi
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mi.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            mr.master_restaurant_id::text as master_restaurant_id,
            mr.display_name,
            mr.city,
            mr.state_code,
            sr.source_slug,
            mi.source_inspection_key,
            mi.master_inspection_id::text as master_inspection_id,
            mi.inspection_date,
            mi.inspection_type,
            mir.availability_status as report_availability_status,
            count(mif.master_inspection_finding_id)::int as finding_count
        from master.master_inspection mi
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mi.source_id
        left join master.master_inspection_report mir
            on mir.master_inspection_id = mi.master_inspection_id
            and mir.report_role = 'official_source_report'
            and mir.is_current = true
        left join master.master_inspection_finding mif
            on mif.master_inspection_id = mi.master_inspection_id
            and mif.is_current = true
        {where_sql}
        group by
            mr.master_restaurant_id,
            mr.display_name,
            mr.city,
            mr.state_code,
            sr.source_slug,
            mi.source_inspection_key,
            mi.master_inspection_id,
            mi.inspection_date,
            mi.inspection_type,
            mir.availability_status
        order by mi.created_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [MasterInspectionLineageSummary(**row) for row in rows], total_count


def list_source_versions(*, limit: int = 200) -> list[SourceVersionSummary]:
    return list_source_versions_page(page=1, page_size=limit)[0]


def list_source_versions_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
) -> tuple[list[SourceVersionSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_sql = ""
    params: list[Any] = []
    if search is not None:
        where_sql = """
        where (
            sr.source_slug ilike %s
            or sv.entity_type ilike %s
            or coalesce(sv.source_entity_key, '') ilike %s
            or sv.change_type ilike %s
        )
        """
        params.extend([search, search, search, search])

    count_sql = f"""
        select count(*)::int as total_count
        from master.source_version sv
        join ops.source_registry sr on sr.source_id = sv.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            sv.source_version_id::text as source_version_id,
            sr.source_slug,
            sv.entity_type,
            sv.source_entity_key,
            sv.version_number,
            sv.is_current,
            sv.change_type,
            sv.effective_at
        from master.source_version sv
        join ops.source_registry sr on sr.source_id = sv.source_id
        {where_sql}
        order by sv.effective_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [SourceVersionSummary(**row) for row in rows], total_count
