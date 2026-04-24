from fiscore_backend.db import get_connection


def create_parse_result(
    *,
    source_id: str,
    scrape_run_id: str,
    raw_artifact_id: str | None,
    parser_version: str,
    record_type: str,
    source_record_key: str | None,
    parse_status: str,
    payload: str,
    warning_count: int,
    error_count: int = 0,
) -> str:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into ingestion.parse_result (
                    source_id,
                    scrape_run_id,
                    raw_artifact_id,
                    parser_version,
                    record_type,
                    source_record_key,
                    parse_status,
                    payload,
                    warning_count,
                    error_count
                )
                values (
                    %s::uuid,
                    %s::uuid,
                    %s::uuid,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s::jsonb,
                    %s,
                    %s
                )
                returning parse_result_id::text
                """,
                (
                    source_id,
                    scrape_run_id,
                    raw_artifact_id,
                    parser_version,
                    record_type,
                    source_record_key,
                    parse_status,
                    payload,
                    warning_count,
                    error_count,
                ),
            )
            parse_result_id = cur.fetchone()[0]
        conn.commit()

    return parse_result_id


def create_parser_warning(
    *,
    parse_result_id: str,
    warning_code: str,
    warning_message: str,
) -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into ingestion.parser_warning (
                    parse_result_id,
                    warning_code,
                    warning_message
                )
                values (%s::uuid, %s, %s)
                """,
                (parse_result_id, warning_code, warning_message),
            )
        conn.commit()

