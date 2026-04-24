from fiscore_backend.db import get_connection


def mark_scrape_run_running(scrape_run_id: str) -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                update ops.scrape_run
                set run_status = 'running'
                where scrape_run_id = %s::uuid
                """,
                (scrape_run_id,),
            )
        conn.commit()


def mark_scrape_run_completed(
    scrape_run_id: str,
    *,
    artifact_count: int,
    parsed_record_count: int,
    normalized_record_count: int,
    warning_count: int,
    error_count: int,
) -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                update ops.scrape_run
                set
                    run_status = case
                        when %s > 0 then 'completed_with_warnings'
                        else 'completed'
                    end,
                    artifact_count = %s,
                    parsed_record_count = %s,
                    normalized_record_count = %s,
                    warning_count = %s,
                    error_count = %s,
                    completed_at = now()
                where scrape_run_id = %s::uuid
                """,
                (
                    warning_count,
                    artifact_count,
                    parsed_record_count,
                    normalized_record_count,
                    warning_count,
                    error_count,
                    scrape_run_id,
                ),
            )
        conn.commit()


def mark_scrape_run_failed(scrape_run_id: str, error_summary: str) -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                update ops.scrape_run
                set
                    run_status = 'failed',
                    completed_at = now(),
                    error_count = error_count + 1,
                    error_summary = %s
                where scrape_run_id = %s::uuid
                """,
                (error_summary, scrape_run_id),
            )
        conn.commit()
