from __future__ import annotations

import json
from typing import Any

from psycopg.rows import dict_row

from fiscore_backend.db import get_connection
from fiscore_backend.models import (
    AdminRestaurantDetail,
    AdminRestaurantInspectionDetail,
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
    OpsMasterRestaurantIdentifierSummary,
    OpsMasterRestaurantSourceLinkSummary,
    OpsMasterRestaurantSummary,
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


def get_master_data_quality_summary() -> OpsMasterDataQualitySummary:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                with duplicate_groups as (
                    select location_fingerprint, count(*)::int as group_size
                    from master.master_restaurant
                    group by location_fingerprint
                    having count(*) > 1
                ),
                current_reports as (
                    select
                        master_inspection_id,
                        max(case when is_current then 1 else 0 end)::int as has_current_report,
                        max(
                            case
                                when is_current and coalesce(availability_status, '') = 'available' then 1
                                else 0
                            end
                        )::int as has_available_report,
                        max(
                            case
                                when is_current and coalesce(storage_path, '') <> '' then 1
                                else 0
                            end
                        )::int as has_storage_path
                    from master.master_inspection_report
                    group by master_inspection_id
                )
                select
                    (select count(*) from master.master_restaurant)::int as total_restaurants,
                    (select count(*) from master.master_inspection)::int as total_inspections,
                    (select count(*) from master.master_inspection_report)::int as total_reports,
                    (select count(*) from master.master_inspection_finding)::int as total_findings,
                    (
                        select count(*)::int
                        from master.master_restaurant mr
                        where not exists (
                            select 1
                            from master.master_restaurant_source_link mrl
                            where mrl.master_restaurant_id = mr.master_restaurant_id
                        )
                    ) as restaurants_without_source_links,
                    (
                        select count(*)::int
                        from master.master_restaurant mr
                        where not exists (
                            select 1
                            from master.master_restaurant_identifier mri
                            where mri.master_restaurant_id = mr.master_restaurant_id
                        )
                    ) as restaurants_without_identifiers,
                    (
                        select coalesce(sum(group_size), 0)::int
                        from duplicate_groups
                    ) as duplicate_risk_restaurants,
                    (
                        select count(*)::int
                        from master.master_inspection mi
                        left join current_reports cr on cr.master_inspection_id = mi.master_inspection_id
                        where coalesce(cr.has_current_report, 0) = 0 or coalesce(cr.has_available_report, 0) = 0
                    ) as inspections_missing_reports,
                    (
                        select count(*)::int
                        from master.master_inspection_report mir
                        where mir.is_current = true
                          and coalesce(mir.availability_status, '') = 'available'
                          and coalesce(mir.storage_path, '') = ''
                    ) as reports_missing_storage,
                    (
                        select count(*)::int
                        from master.master_inspection_finding mif
                        where coalesce(mif.official_detail_text, '') = ''
                          and (
                              mif.official_detail_json is null
                              or mif.official_detail_json = '{}'::jsonb
                              or mif.official_detail_json = 'null'::jsonb
                          )
                    ) as findings_missing_detail
                """
            )
            row = cur.fetchone()
    return OpsMasterDataQualitySummary(**row)


def list_master_restaurants_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    source_slug: str | None = None,
    quality_filter: str | None = None,
) -> tuple[list[OpsMasterRestaurantSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                mr.display_name ilike %s
                or coalesce(mr.normalized_name, '') ilike %s
                or mr.address_line1 ilike %s
                or mr.city ilike %s
                or coalesce(mr.zip_code, '') ilike %s
                or mr.location_fingerprint ilike %s
                or exists (
                    select 1
                    from master.master_restaurant_identifier mri
                    where mri.master_restaurant_id = mr.master_restaurant_id
                      and (
                          mri.identifier_type ilike %s
                          or mri.identifier_value ilike %s
                      )
                )
                or exists (
                    select 1
                    from master.master_restaurant_source_link mrl
                    join ops.source_registry sr on sr.source_id = mrl.source_id
                    where mrl.master_restaurant_id = mr.master_restaurant_id
                      and (
                          sr.source_slug ilike %s
                          or sr.source_name ilike %s
                          or mrl.source_restaurant_key ilike %s
                      )
                )
            )
            """
        )
        params.extend([search] * 11)
    if source_slug:
        where_parts.append(
            """
            exists (
                select 1
                from master.master_restaurant_source_link mrl
                join ops.source_registry sr on sr.source_id = mrl.source_id
                where mrl.master_restaurant_id = mr.master_restaurant_id
                  and sr.source_slug = %s
            )
            """
        )
        params.append(source_slug)
    if quality_filter == "duplicates":
        where_parts.append(
            """
            exists (
                select 1
                from master.master_restaurant other_mr
                where other_mr.location_fingerprint = mr.location_fingerprint
                  and other_mr.master_restaurant_id <> mr.master_restaurant_id
            )
            """
        )
    elif quality_filter == "missing_reports":
        where_parts.append(
            """
            exists (
                select 1
                from master.master_inspection mi
                left join master.master_inspection_report mir
                    on mir.master_inspection_id = mi.master_inspection_id
                    and mir.is_current = true
                where mi.master_restaurant_id = mr.master_restaurant_id
                group by mi.master_inspection_id
                having count(mir.master_inspection_report_id) = 0
                   or bool_or(coalesce(mir.availability_status, '') = 'available') = false
            )
            """
        )
    elif quality_filter == "weak_linkage":
        where_parts.append(
            """
            (
                not exists (
                    select 1
                    from master.master_restaurant_identifier mri
                    where mri.master_restaurant_id = mr.master_restaurant_id
                )
                or not exists (
                    select 1
                    from master.master_restaurant_source_link mrl
                    where mrl.master_restaurant_id = mr.master_restaurant_id
                )
                or exists (
                    select 1
                    from master.master_restaurant_source_link mrl
                    where mrl.master_restaurant_id = mr.master_restaurant_id
                      and (
                          mrl.match_status <> 'matched'
                          or coalesce(mrl.match_confidence, 0) < 0.95
                      )
                )
            )
            """
        )
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from master.master_restaurant mr
        {where_sql}
    """
    data_sql = f"""
        with inspection_stats as (
            select
                mi.master_restaurant_id,
                count(*)::int as inspection_count,
                max(mi.inspection_date) as latest_inspection_date,
                count(*) filter (
                    where not exists (
                        select 1
                        from master.master_inspection_report mir
                        where mir.master_inspection_id = mi.master_inspection_id
                          and mir.is_current = true
                          and mir.availability_status = 'available'
                    )
                )::int as report_gap_count
            from master.master_inspection mi
            group by mi.master_restaurant_id
        ),
        link_stats as (
            select
                mrl.master_restaurant_id,
                count(*)::int as source_link_count
            from master.master_restaurant_source_link mrl
            group by mrl.master_restaurant_id
        ),
        identifier_stats as (
            select
                mri.master_restaurant_id,
                count(*)::int as identifier_count
            from master.master_restaurant_identifier mri
            group by mri.master_restaurant_id
        ),
        duplicate_stats as (
            select
                location_fingerprint,
                count(*)::int as duplicate_group_size
            from master.master_restaurant
            group by location_fingerprint
        )
        select
            mr.master_restaurant_id::text as master_restaurant_id,
            mr.display_name,
            mr.normalized_name,
            mr.address_line1,
            mr.city,
            mr.state_code,
            mr.zip_code,
            mr.status,
            mr.location_fingerprint,
            coalesce(ins.inspection_count, 0) as inspection_count,
            coalesce(ls.source_link_count, 0) as source_link_count,
            coalesce(ids.identifier_count, 0) as identifier_count,
            ins.latest_inspection_date,
            coalesce(ins.report_gap_count, 0) as report_gap_count,
            coalesce(ds.duplicate_group_size, 1) as duplicate_group_size,
            mr.created_at,
            mr.updated_at
        from master.master_restaurant mr
        left join inspection_stats ins on ins.master_restaurant_id = mr.master_restaurant_id
        left join link_stats ls on ls.master_restaurant_id = mr.master_restaurant_id
        left join identifier_stats ids on ids.master_restaurant_id = mr.master_restaurant_id
        left join duplicate_stats ds on ds.location_fingerprint = mr.location_fingerprint
        {where_sql}
        order by
            coalesce(ins.latest_inspection_date, date '1900-01-01') desc,
            mr.updated_at desc,
            mr.display_name
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsMasterRestaurantSummary(**row) for row in rows], total_count


def get_master_restaurant_detail(master_restaurant_id: str) -> OpsMasterRestaurantDetail | None:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                with inspection_stats as (
                    select
                        mi.master_restaurant_id,
                        count(*)::int as inspection_count,
                        max(mi.inspection_date) as latest_inspection_date,
                        count(*) filter (
                            where not exists (
                                select 1
                                from master.master_inspection_report mir
                                where mir.master_inspection_id = mi.master_inspection_id
                                  and mir.is_current = true
                                  and mir.availability_status = 'available'
                            )
                        )::int as report_gap_count
                    from master.master_inspection mi
                    group by mi.master_restaurant_id
                ),
                link_stats as (
                    select
                        mrl.master_restaurant_id,
                        count(*)::int as source_link_count
                    from master.master_restaurant_source_link mrl
                    group by mrl.master_restaurant_id
                ),
                identifier_stats as (
                    select
                        mri.master_restaurant_id,
                        count(*)::int as identifier_count
                    from master.master_restaurant_identifier mri
                    group by mri.master_restaurant_id
                ),
                duplicate_stats as (
                    select
                        location_fingerprint,
                        count(*)::int as duplicate_group_size
                    from master.master_restaurant
                    group by location_fingerprint
                )
                select
                    mr.master_restaurant_id::text as master_restaurant_id,
                    mr.display_name,
                    mr.normalized_name,
                    mr.address_line1,
                    mr.city,
                    mr.state_code,
                    mr.zip_code,
                    mr.status,
                    mr.location_fingerprint,
                    coalesce(ins.inspection_count, 0) as inspection_count,
                    coalesce(ls.source_link_count, 0) as source_link_count,
                    coalesce(ids.identifier_count, 0) as identifier_count,
                    ins.latest_inspection_date,
                    coalesce(ins.report_gap_count, 0) as report_gap_count,
                    coalesce(ds.duplicate_group_size, 1) as duplicate_group_size,
                    mr.created_at,
                    mr.updated_at
                from master.master_restaurant mr
                left join inspection_stats ins on ins.master_restaurant_id = mr.master_restaurant_id
                left join link_stats ls on ls.master_restaurant_id = mr.master_restaurant_id
                left join identifier_stats ids on ids.master_restaurant_id = mr.master_restaurant_id
                left join duplicate_stats ds on ds.location_fingerprint = mr.location_fingerprint
                where mr.master_restaurant_id = %s::uuid
                limit 1
                """,
                (master_restaurant_id,),
            )
            row = cur.fetchone()
            if row is None:
                return None
            restaurant = OpsMasterRestaurantSummary(**row)

            cur.execute(
                """
                select
                    mri.master_restaurant_identifier_id::text as master_restaurant_identifier_id,
                    sr.source_slug,
                    mri.identifier_type,
                    mri.identifier_value,
                    mri.is_primary,
                    mri.confidence::float8 as confidence,
                    mri.updated_at
                from master.master_restaurant_identifier mri
                left join ops.source_registry sr on sr.source_id = mri.source_id
                where mri.master_restaurant_id = %s::uuid
                order by mri.is_primary desc, mri.updated_at desc, mri.identifier_type, mri.identifier_value
                """,
                (master_restaurant_id,),
            )
            identifiers = [OpsMasterRestaurantIdentifierSummary(**item) for item in cur.fetchall()]

            cur.execute(
                """
                select
                    mrl.master_restaurant_source_link_id::text as master_restaurant_source_link_id,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mrl.source_restaurant_key,
                    mrl.match_method,
                    mrl.match_confidence::float8 as match_confidence,
                    mrl.match_status,
                    mrl.matched_at,
                    count(mi.master_inspection_id)::int as inspection_count,
                    max(mi.inspection_date) as latest_inspection_date
                from master.master_restaurant_source_link mrl
                join ops.source_registry sr on sr.source_id = mrl.source_id
                left join master.master_inspection mi
                    on mi.master_restaurant_id = mrl.master_restaurant_id
                    and mi.source_id = mrl.source_id
                where mrl.master_restaurant_id = %s::uuid
                group by
                    mrl.master_restaurant_source_link_id,
                    sr.source_id,
                    sr.source_slug,
                    sr.source_name,
                    mrl.source_restaurant_key,
                    mrl.match_method,
                    mrl.match_confidence,
                    mrl.match_status,
                    mrl.matched_at
                order by latest_inspection_date desc nulls last, sr.source_name, mrl.source_restaurant_key
                """,
                (master_restaurant_id,),
            )
            source_links = [OpsMasterRestaurantSourceLinkSummary(**item) for item in cur.fetchall()]

            cur.execute(
                """
                select
                    mi.master_inspection_id::text as master_inspection_id,
                    mi.master_restaurant_id::text as master_restaurant_id,
                    mr.display_name,
                    mr.city,
                    mr.state_code,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mi.source_inspection_key,
                    mi.inspection_date,
                    mi.inspection_type,
                    mi.inspector_name,
                    mi.score::float8 as score,
                    mi.grade,
                    mi.official_status,
                    mi.report_url,
                    mir.availability_status as report_availability_status,
                    mir.report_format,
                    mir.storage_path as report_storage_path,
                    count(mif.master_inspection_finding_id)::int as finding_count,
                    mi.created_at,
                    mi.updated_at
                from master.master_inspection mi
                join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
                join ops.source_registry sr on sr.source_id = mi.source_id
                left join master.master_inspection_report mir
                    on mir.master_inspection_id = mi.master_inspection_id
                    and mir.is_current = true
                    and mir.report_role in ('official_source_report', 'official_audit_report')
                left join master.master_inspection_finding mif
                    on mif.master_inspection_id = mi.master_inspection_id
                    and mif.is_current = true
                where mi.master_restaurant_id = %s::uuid
                group by
                    mi.master_inspection_id,
                    mr.display_name,
                    mr.city,
                    mr.state_code,
                    sr.source_id,
                    sr.source_slug,
                    sr.source_name,
                    mir.availability_status,
                    mir.report_format,
                    mir.storage_path
                order by mi.inspection_date desc, mi.created_at desc
                limit 100
                """,
                (master_restaurant_id,),
            )
            inspections = [OpsMasterInspectionSummary(**item) for item in cur.fetchall()]

    return OpsMasterRestaurantDetail(
        restaurant=restaurant,
        identifiers=identifiers,
        source_links=source_links,
        inspections=inspections,
    )


def list_master_inspections_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    source_slug: str | None = None,
    report_status: str | None = None,
    scrape_run_id: str | None = None,
) -> tuple[list[OpsMasterInspectionSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                mr.display_name ilike %s
                or sr.source_slug ilike %s
                or sr.source_name ilike %s
                or mi.source_inspection_key ilike %s
                or coalesce(mi.inspection_type, '') ilike %s
                or coalesce(mi.grade, '') ilike %s
                or coalesce(mi.official_status, '') ilike %s
            )
            """
        )
        params.extend([search] * 7)
    if source_slug:
        where_parts.append("sr.source_slug = %s")
        params.append(source_slug)
    if report_status:
        if report_status == "missing":
            where_parts.append("coalesce(mir.availability_status, 'missing') = 'missing'")
        else:
            where_parts.append("coalesce(mir.availability_status, 'missing') = %s")
            params.append(report_status)
    if scrape_run_id:
        where_parts.append(
            """
            exists (
                select 1
                from ingestion.parse_result pr
                where pr.scrape_run_id = %s::uuid
                  and pr.source_id = mi.source_id
                  and pr.record_type = 'inspection'
                  and (
                      pr.source_record_key = mi.source_inspection_key
                      or ('sword-header:' || coalesce(pr.payload ->> 'header_id', '')) = mi.source_inspection_key
                      or ('ga-report:' || coalesce(pr.payload ->> 'report_url', '')) = mi.source_inspection_key
                      or ('ga-detail:' || coalesce(pr.payload ->> 'detail_url', '')) = mi.source_inspection_key
                  )
            )
            """
        )
        params.append(scrape_run_id)
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from master.master_inspection mi
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mi.source_id
        left join lateral (
            select mir.availability_status
            from master.master_inspection_report mir
            where mir.master_inspection_id = mi.master_inspection_id
              and mir.is_current = true
              and mir.report_role in ('official_source_report', 'official_audit_report')
            order by mir.updated_at desc
            limit 1
        ) mir on true
        {where_sql}
    """
    data_sql = f"""
        select
            mi.master_inspection_id::text as master_inspection_id,
            mi.master_restaurant_id::text as master_restaurant_id,
            mr.display_name,
            mr.city,
            mr.state_code,
            sr.source_id::text as source_id,
            sr.source_slug,
            sr.source_name,
            mi.source_inspection_key,
            mi.inspection_date,
            mi.inspection_type,
            mi.score::float8 as score,
            mi.grade,
            mi.official_status,
            mi.report_url,
            mir.availability_status as report_availability_status,
            mir.report_format,
            mir.storage_path as report_storage_path,
            count(mif.master_inspection_finding_id)::int as finding_count,
            mi.created_at,
            mi.updated_at
        from master.master_inspection mi
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mi.source_id
        left join lateral (
            select
                mir.availability_status,
                mir.report_format,
                mir.storage_path
            from master.master_inspection_report mir
            where mir.master_inspection_id = mi.master_inspection_id
              and mir.is_current = true
              and mir.report_role in ('official_source_report', 'official_audit_report')
            order by mir.updated_at desc
            limit 1
        ) mir on true
        left join master.master_inspection_finding mif
            on mif.master_inspection_id = mi.master_inspection_id
            and mif.is_current = true
        {where_sql}
        group by
            mi.master_inspection_id,
            mr.display_name,
            mr.city,
            mr.state_code,
            sr.source_id,
            sr.source_slug,
            sr.source_name,
            mir.availability_status,
            mir.report_format,
            mir.storage_path
        order by mi.inspection_date desc, mi.created_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsMasterInspectionSummary(**row) for row in rows], total_count


def get_master_inspection_detail(master_inspection_id: str) -> OpsMasterInspectionDetail | None:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    mi.master_inspection_id::text as master_inspection_id,
                    mi.master_restaurant_id::text as master_restaurant_id,
                    mr.display_name,
                    mr.city,
                    mr.state_code,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mi.source_inspection_key,
                    mi.inspection_date,
                    mi.inspection_type,
                    mi.inspector_name,
                    mi.score::float8 as score,
                    mi.grade,
                    mi.official_status,
                    mi.report_url,
                    mir.availability_status as report_availability_status,
                    mir.report_format,
                    mir.storage_path as report_storage_path,
                    count(mif.master_inspection_finding_id)::int as finding_count,
                    mi.created_at,
                    mi.updated_at
                from master.master_inspection mi
                join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
                join ops.source_registry sr on sr.source_id = mi.source_id
                left join lateral (
                    select
                        mir.availability_status,
                        mir.report_format,
                        mir.storage_path
                    from master.master_inspection_report mir
                    where mir.master_inspection_id = mi.master_inspection_id
                      and mir.is_current = true
                      and mir.report_role in ('official_source_report', 'official_audit_report')
                    order by mir.updated_at desc
                    limit 1
                ) mir on true
                left join master.master_inspection_finding mif
                    on mif.master_inspection_id = mi.master_inspection_id
                    and mif.is_current = true
                where mi.master_inspection_id = %s::uuid
                group by
                    mi.master_inspection_id,
                    mr.display_name,
                    mr.city,
                    mr.state_code,
                    sr.source_id,
                    sr.source_slug,
                    sr.source_name,
                    mir.availability_status,
                    mir.report_format,
                    mir.storage_path
                limit 1
                """,
                (master_inspection_id,),
            )
            row = cur.fetchone()
            if row is None:
                return None
            inspection = OpsMasterInspectionSummary(**row)

            cur.execute(
                """
                select
                    mir.master_inspection_report_id::text as master_inspection_report_id,
                    mir.master_inspection_id::text as master_inspection_id,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mr.display_name,
                    mi.inspection_date,
                    mir.report_role,
                    mir.report_format,
                    mir.availability_status,
                    mir.source_page_url,
                    mir.source_file_url,
                    mir.storage_path,
                    mir.is_current,
                    mir.created_at,
                    mir.updated_at
                from master.master_inspection_report mir
                join master.master_inspection mi on mi.master_inspection_id = mir.master_inspection_id
                join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
                join ops.source_registry sr on sr.source_id = mir.source_id
                where mir.master_inspection_id = %s::uuid
                order by mir.is_current desc, mir.updated_at desc
                """,
                (master_inspection_id,),
            )
            reports = [OpsMasterInspectionReportSummary(**item) for item in cur.fetchall()]

            cur.execute(
                """
                select
                    mif.master_inspection_finding_id::text as master_inspection_finding_id,
                    mif.master_inspection_id::text as master_inspection_id,
                    mi.master_restaurant_id::text as master_restaurant_id,
                    mr.display_name,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mi.inspection_date,
                    mif.source_finding_key,
                    mif.finding_order,
                    mif.official_code,
                    mif.official_clause_reference,
                    mif.official_text,
                    mif.official_detail_text,
                    mif.auditor_comments,
                    mif.normalized_title,
                    mif.normalized_category,
                    mif.severity,
                    mif.corrected_during_inspection,
                    mif.is_repeat_violation,
                    mif.created_at,
                    mif.updated_at
                from master.master_inspection_finding mif
                join master.master_inspection mi on mi.master_inspection_id = mif.master_inspection_id
                join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
                join ops.source_registry sr on sr.source_id = mif.source_id
                where mif.master_inspection_id = %s::uuid
                order by coalesce(mif.finding_order, 999999), mif.created_at
                """,
                (master_inspection_id,),
            )
            findings = [OpsMasterFindingSummary(**item) for item in cur.fetchall()]

            cur.execute(
                """
                select distinct
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
                join ingestion.parse_result pr
                    on pr.scrape_run_id = r.scrape_run_id
                   and pr.source_id = r.source_id
                   and pr.record_type = 'inspection'
                join master.master_inspection mi
                    on mi.master_inspection_id = %s::uuid
                   and mi.source_id = pr.source_id
                   and (
                       pr.source_record_key = mi.source_inspection_key
                       or ('sword-header:' || coalesce(pr.payload ->> 'header_id', '')) = mi.source_inspection_key
                       or ('ga-report:' || coalesce(pr.payload ->> 'report_url', '')) = mi.source_inspection_key
                       or ('ga-detail:' || coalesce(pr.payload ->> 'detail_url', '')) = mi.source_inspection_key
                   )
                order by r.started_at desc
                limit 20
                """,
                (master_inspection_id,),
            )
            related_runs = [OpsRunSummary(**item) for item in cur.fetchall()]

    return OpsMasterInspectionDetail(
        inspection=inspection,
        reports=reports,
        findings=findings,
        related_runs=related_runs,
    )


def list_admin_restaurants_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    state_code: str | None = None,
    city: str | None = None,
    status: str | None = None,
    source_slug: str | None = None,
    has_inspections: bool | None = None,
) -> tuple[list[OpsMasterRestaurantSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                mr.display_name ilike %s
                or coalesce(mr.normalized_name, '') ilike %s
                or mr.address_line1 ilike %s
                or mr.city ilike %s
                or coalesce(mr.zip_code, '') ilike %s
                or exists (
                    select 1
                    from master.master_restaurant_identifier mri
                    where mri.master_restaurant_id = mr.master_restaurant_id
                      and mri.identifier_value ilike %s
                )
            )
            """
        )
        params.extend([search] * 6)
    if state_code:
        where_parts.append("mr.state_code = %s")
        params.append(state_code)
    if city:
        where_parts.append("mr.city ilike %s")
        params.append(_like_pattern(city))
    if status:
        where_parts.append("mr.status = %s")
        params.append(status)
    if source_slug:
        where_parts.append(
            """
            exists (
                select 1
                from master.master_restaurant_source_link mrl
                join ops.source_registry sr on sr.source_id = mrl.source_id
                where mrl.master_restaurant_id = mr.master_restaurant_id
                  and sr.source_slug = %s
            )
            """
        )
        params.append(source_slug)
    if has_inspections is True:
        where_parts.append(
            """
            exists (
                select 1 from master.master_inspection mi
                where mi.master_restaurant_id = mr.master_restaurant_id
            )
            """
        )
    elif has_inspections is False:
        where_parts.append(
            """
            not exists (
                select 1 from master.master_inspection mi
                where mi.master_restaurant_id = mr.master_restaurant_id
            )
            """
        )
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from master.master_restaurant mr
        {where_sql}
    """
    data_sql = f"""
        with inspection_stats as (
            select
                mi.master_restaurant_id,
                count(*)::int as inspection_count,
                max(mi.inspection_date) as latest_inspection_date,
                count(*) filter (
                    where not exists (
                        select 1
                        from master.master_inspection_report mir
                        where mir.master_inspection_id = mi.master_inspection_id
                          and mir.is_current = true
                          and mir.availability_status = 'available'
                    )
                )::int as report_gap_count
            from master.master_inspection mi
            group by mi.master_restaurant_id
        ),
        link_stats as (
            select mrl.master_restaurant_id, count(*)::int as source_link_count
            from master.master_restaurant_source_link mrl
            group by mrl.master_restaurant_id
        ),
        identifier_stats as (
            select mri.master_restaurant_id, count(*)::int as identifier_count
            from master.master_restaurant_identifier mri
            group by mri.master_restaurant_id
        ),
        duplicate_stats as (
            select location_fingerprint, count(*)::int as duplicate_group_size
            from master.master_restaurant
            group by location_fingerprint
        )
        select
            mr.master_restaurant_id::text as master_restaurant_id,
            mr.display_name,
            mr.normalized_name,
            mr.address_line1,
            mr.city,
            mr.state_code,
            mr.zip_code,
            mr.status,
            mr.location_fingerprint,
            coalesce(ins.inspection_count, 0) as inspection_count,
            coalesce(ls.source_link_count, 0) as source_link_count,
            coalesce(ids.identifier_count, 0) as identifier_count,
            ins.latest_inspection_date,
            coalesce(ins.report_gap_count, 0) as report_gap_count,
            coalesce(ds.duplicate_group_size, 1) as duplicate_group_size,
            mr.created_at,
            mr.updated_at
        from master.master_restaurant mr
        left join inspection_stats ins on ins.master_restaurant_id = mr.master_restaurant_id
        left join link_stats ls on ls.master_restaurant_id = mr.master_restaurant_id
        left join identifier_stats ids on ids.master_restaurant_id = mr.master_restaurant_id
        left join duplicate_stats ds on ds.location_fingerprint = mr.location_fingerprint
        {where_sql}
        order by
            coalesce(ins.latest_inspection_date, date '1900-01-01') desc,
            mr.display_name
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsMasterRestaurantSummary(**row) for row in rows], total_count


def get_admin_restaurant_detail(master_restaurant_id: str) -> AdminRestaurantDetail | None:
    base_detail = get_master_restaurant_detail(master_restaurant_id)
    if base_detail is None:
        return None

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    mi.master_inspection_id::text as master_inspection_id,
                    mi.master_restaurant_id::text as master_restaurant_id,
                    mr.display_name,
                    mr.city,
                    mr.state_code,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mi.source_inspection_key,
                    mi.inspection_date,
                    mi.inspection_type,
                    mi.score::float8 as score,
                    mi.grade,
                    mi.official_status,
                    mi.report_url,
                    mir.availability_status as report_availability_status,
                    mir.report_format,
                    mir.storage_path as report_storage_path,
                    count(mif.master_inspection_finding_id)::int as finding_count,
                    mi.created_at,
                    mi.updated_at
                from master.master_inspection mi
                join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
                join ops.source_registry sr on sr.source_id = mi.source_id
                left join lateral (
                    select
                        mir.availability_status,
                        mir.report_format,
                        mir.storage_path
                    from master.master_inspection_report mir
                    where mir.master_inspection_id = mi.master_inspection_id
                      and mir.is_current = true
                      and mir.report_role in ('official_source_report', 'official_audit_report')
                    order by mir.updated_at desc
                    limit 1
                ) mir on true
                left join master.master_inspection_finding mif
                    on mif.master_inspection_id = mi.master_inspection_id
                    and mif.is_current = true
                where mi.master_restaurant_id = %s::uuid
                group by
                    mi.master_inspection_id,
                    mr.display_name,
                    mr.city,
                    mr.state_code,
                    sr.source_id,
                    sr.source_slug,
                    sr.source_name,
                    mir.availability_status,
                    mir.report_format,
                    mir.storage_path
                order by mi.inspection_date desc, mi.created_at desc
                """,
                (master_restaurant_id,),
            )
            inspection_rows = cur.fetchall()
            inspections = [OpsMasterInspectionSummary(**item) for item in inspection_rows]

            cur.execute(
                """
                select
                    mir.master_inspection_report_id::text as master_inspection_report_id,
                    mir.master_inspection_id::text as master_inspection_id,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mr.display_name,
                    mi.inspection_date,
                    mir.report_role,
                    mir.report_format,
                    mir.availability_status,
                    mir.source_page_url,
                    mir.source_file_url,
                    mir.storage_path,
                    mir.is_current,
                    mir.created_at,
                    mir.updated_at
                from master.master_inspection_report mir
                join master.master_inspection mi on mi.master_inspection_id = mir.master_inspection_id
                join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
                join ops.source_registry sr on sr.source_id = mir.source_id
                where mi.master_restaurant_id = %s::uuid
                order by mi.inspection_date desc, mir.updated_at desc
                """,
                (master_restaurant_id,),
            )
            report_rows = [OpsMasterInspectionReportSummary(**item) for item in cur.fetchall()]

            cur.execute(
                """
                select
                    mif.master_inspection_finding_id::text as master_inspection_finding_id,
                    mif.master_inspection_id::text as master_inspection_id,
                    mi.master_restaurant_id::text as master_restaurant_id,
                    mr.display_name,
                    sr.source_id::text as source_id,
                    sr.source_slug,
                    sr.source_name,
                    mi.inspection_date,
                    mif.source_finding_key,
                    mif.finding_order,
                    mif.official_code,
                    mif.official_clause_reference,
                    mif.official_text,
                    mif.official_detail_text,
                    mif.auditor_comments,
                    mif.normalized_title,
                    mif.normalized_category,
                    mif.severity,
                    mif.corrected_during_inspection,
                    mif.is_repeat_violation,
                    mif.created_at,
                    mif.updated_at
                from master.master_inspection_finding mif
                join master.master_inspection mi on mi.master_inspection_id = mif.master_inspection_id
                join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
                join ops.source_registry sr on sr.source_id = mif.source_id
                where mi.master_restaurant_id = %s::uuid
                order by mi.inspection_date desc, coalesce(mif.finding_order, 999999), mif.created_at
                """,
                (master_restaurant_id,),
            )
            finding_rows = [OpsMasterFindingSummary(**item) for item in cur.fetchall()]

    reports_by_inspection: dict[str, list[OpsMasterInspectionReportSummary]] = {}
    for report in report_rows:
        reports_by_inspection.setdefault(report.master_inspection_id, []).append(report)

    findings_by_inspection: dict[str, list[OpsMasterFindingSummary]] = {}
    for finding in finding_rows:
        findings_by_inspection.setdefault(finding.master_inspection_id, []).append(finding)

    inspection_details = [
        AdminRestaurantInspectionDetail(
            inspection=inspection,
            reports=reports_by_inspection.get(inspection.master_inspection_id, []),
            findings=findings_by_inspection.get(inspection.master_inspection_id, []),
        )
        for inspection in inspections
    ]

    return AdminRestaurantDetail(
        restaurant=base_detail.restaurant,
        identifiers=base_detail.identifiers,
        source_links=base_detail.source_links,
        inspections=inspection_details,
    )


def list_master_reports_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    source_slug: str | None = None,
    availability_status: str | None = None,
    missing_storage_only: bool = False,
) -> tuple[list[OpsMasterInspectionReportSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                mr.display_name ilike %s
                or sr.source_slug ilike %s
                or sr.source_name ilike %s
                or mir.report_role ilike %s
                or coalesce(mir.source_page_url, '') ilike %s
                or coalesce(mir.source_file_url, '') ilike %s
                or coalesce(mir.storage_path, '') ilike %s
            )
            """
        )
        params.extend([search] * 7)
    if source_slug:
        where_parts.append("sr.source_slug = %s")
        params.append(source_slug)
    if availability_status:
        where_parts.append("mir.availability_status = %s")
        params.append(availability_status)
    if missing_storage_only:
        where_parts.append(
            """
            coalesce(mir.storage_path, '') = ''
            and coalesce(mir.availability_status, '') = 'available'
            """
        )
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from master.master_inspection_report mir
        join master.master_inspection mi on mi.master_inspection_id = mir.master_inspection_id
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mir.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            mir.master_inspection_report_id::text as master_inspection_report_id,
            mir.master_inspection_id::text as master_inspection_id,
            sr.source_id::text as source_id,
            sr.source_slug,
            sr.source_name,
            mr.display_name,
            mi.inspection_date,
            mir.report_role,
            mir.report_format,
            mir.availability_status,
            mir.source_page_url,
            mir.source_file_url,
            mir.storage_path,
            mir.is_current,
            mir.created_at,
            mir.updated_at
        from master.master_inspection_report mir
        join master.master_inspection mi on mi.master_inspection_id = mir.master_inspection_id
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mir.source_id
        {where_sql}
        order by mi.inspection_date desc, mir.updated_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsMasterInspectionReportSummary(**row) for row in rows], total_count


def list_master_findings_page(
    *,
    page: int = 1,
    page_size: int = 100,
    query: str | None = None,
    source_slug: str | None = None,
    missing_detail_only: bool = False,
) -> tuple[list[OpsMasterFindingSummary], int]:
    safe_page, safe_size = _normalize_page(page, page_size, default_size=50, max_size=250)
    search = _like_pattern(query)
    offset = (safe_page - 1) * safe_size

    where_parts = []
    params: list[Any] = []
    if search is not None:
        where_parts.append(
            """
            (
                mr.display_name ilike %s
                or sr.source_slug ilike %s
                or sr.source_name ilike %s
                or coalesce(mif.official_code, '') ilike %s
                or coalesce(mif.official_clause_reference, '') ilike %s
                or mif.official_text ilike %s
                or coalesce(mif.official_detail_text, '') ilike %s
                or coalesce(mif.normalized_category, '') ilike %s
            )
            """
        )
        params.extend([search] * 8)
    if source_slug:
        where_parts.append("sr.source_slug = %s")
        params.append(source_slug)
    if missing_detail_only:
        where_parts.append(
            """
            coalesce(mif.official_detail_text, '') = ''
            and (
                mif.official_detail_json is null
                or mif.official_detail_json = '{}'::jsonb
                or mif.official_detail_json = 'null'::jsonb
            )
            """
        )
    where_sql = f"where {' and '.join(where_parts)}" if where_parts else ""

    count_sql = f"""
        select count(*)::int as total_count
        from master.master_inspection_finding mif
        join master.master_inspection mi on mi.master_inspection_id = mif.master_inspection_id
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mif.source_id
        {where_sql}
    """
    data_sql = f"""
        select
            mif.master_inspection_finding_id::text as master_inspection_finding_id,
            mif.master_inspection_id::text as master_inspection_id,
            mi.master_restaurant_id::text as master_restaurant_id,
            mr.display_name,
            sr.source_id::text as source_id,
            sr.source_slug,
            sr.source_name,
            mi.inspection_date,
            mif.source_finding_key,
            mif.finding_order,
            mif.official_code,
            mif.official_clause_reference,
            mif.official_text,
            mif.official_detail_text,
            mif.normalized_title,
            mif.normalized_category,
            mif.severity,
            mif.corrected_during_inspection,
            mif.is_repeat_violation,
            mif.created_at,
            mif.updated_at
        from master.master_inspection_finding mif
        join master.master_inspection mi on mi.master_inspection_id = mif.master_inspection_id
        join master.master_restaurant mr on mr.master_restaurant_id = mi.master_restaurant_id
        join ops.source_registry sr on sr.source_id = mif.source_id
        {where_sql}
        order by mi.inspection_date desc, mif.updated_at desc
        limit %s offset %s
    """

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(count_sql, params)
            total_count = cur.fetchone()["total_count"]
            cur.execute(data_sql, [*params, safe_size, offset])
            rows = cur.fetchall()
    return [OpsMasterFindingSummary(**row) for row in rows], total_count


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
