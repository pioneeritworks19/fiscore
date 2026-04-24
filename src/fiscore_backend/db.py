from collections.abc import Iterator
from contextlib import contextmanager

import psycopg

from fiscore_backend.config import get_settings


def connect() -> psycopg.Connection:
    settings = get_settings()
    return psycopg.connect(settings.database_dsn)


@contextmanager
def get_connection() -> Iterator[psycopg.Connection]:
    conn = connect()
    try:
        yield conn
    finally:
        conn.close()


def check_connection() -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("select 1")
            cur.fetchone()
    return True

