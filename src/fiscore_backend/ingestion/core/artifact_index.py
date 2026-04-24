from fiscore_backend.db import get_connection


def create_raw_artifact_index(
    *,
    source_id: str,
    scrape_run_id: str,
    artifact_type: str,
    source_url: str,
    storage_path: str,
    content_hash: str,
) -> str:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into ingestion.raw_artifact_index (
                    source_id,
                    scrape_run_id,
                    artifact_type,
                    source_url,
                    storage_path,
                    content_hash
                )
                values (%s::uuid, %s::uuid, %s, %s, %s, %s)
                returning raw_artifact_id::text
                """,
                (
                    source_id,
                    scrape_run_id,
                    artifact_type,
                    source_url,
                    storage_path,
                    content_hash,
                ),
            )
            raw_artifact_id = cur.fetchone()[0]
        conn.commit()

    return raw_artifact_id

