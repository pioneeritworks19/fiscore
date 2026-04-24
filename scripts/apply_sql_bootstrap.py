from __future__ import annotations

from pathlib import Path

import psycopg

from fiscore_backend.config import get_settings


BOOTSTRAP_FILES = [
    Path("sql/bootstrap/001_init_schemas.sql"),
    Path("sql/bootstrap/002_init_tables.sql"),
    Path("sql/seeds/001_seed_sword_sources.sql"),
]


def main() -> None:
    settings = get_settings()
    print(f"Connecting to {settings.db_host}:{settings.db_port}/{settings.db_name}...")

    with psycopg.connect(settings.database_dsn) as conn:
        for sql_file in BOOTSTRAP_FILES:
            sql_text = sql_file.read_text(encoding="utf-8")
            print(f"Applying {sql_file}...")
            with conn.cursor() as cur:
                cur.execute(sql_text)
            conn.commit()

    print("Bootstrap applied successfully.")


if __name__ == "__main__":
    main()

