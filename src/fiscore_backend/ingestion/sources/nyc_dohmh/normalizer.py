from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from functools import lru_cache
from hashlib import sha256
import json
import re
from typing import Any

from psycopg.rows import dict_row

from fiscore_backend.db import get_connection


@dataclass(frozen=True)
class NormalizedInspectionResult:
    master_restaurant_id: str
    master_inspection_id: str
    source_inspection_key: str
    normalized_count: int


def _clean_text(value: Any) -> str | None:
    if value is None:
        return None
    text = " ".join(str(value).split())
    return text or None


def _normalize_token(value: str | None) -> str | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    return re.sub(r"[^a-z0-9]+", "", cleaned.lower()) or None


def _normalize_name(value: str | None) -> str | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    return re.sub(r"[^a-z0-9]+", " ", cleaned.lower()).strip() or None


def _location_fingerprint(payload: dict[str, Any]) -> str:
    restaurant = payload.get("restaurant", {})
    address = _clean_text(restaurant.get("address_line1_raw"))
    borough = _clean_text(restaurant.get("boro_raw"))
    state = "NY"
    zip_code = _clean_text(restaurant.get("zipcode_raw"))
    joined = "|".join(
        filter(
            None,
            [
                _normalize_token(address),
                _normalize_token(borough),
                _normalize_token(state),
                _normalize_token(zip_code),
            ],
        )
    )
    if joined:
        return sha256(joined.encode("utf-8")).hexdigest()

    fallback = "|".join(
        filter(
            None,
            [
                _normalize_token(restaurant.get("camis_raw")),
                _normalize_token(restaurant.get("dba_raw")),
            ],
        )
    )
    return sha256(fallback.encode("utf-8")).hexdigest()


def _source_restaurant_key(payload: dict[str, Any]) -> str:
    restaurant = payload.get("restaurant", {})
    source_restaurant_key = _clean_text(restaurant.get("source_restaurant_key"))
    if source_restaurant_key:
        return source_restaurant_key
    camis = _clean_text(restaurant.get("camis_raw"))
    if camis:
        return f"nyc-camis:{camis}"
    return _location_fingerprint(payload)


def _source_inspection_key(payload: dict[str, Any]) -> str:
    inspection = payload.get("inspection", {})
    source_inspection_key = _clean_text(inspection.get("source_inspection_key"))
    if source_inspection_key:
        return source_inspection_key

    restaurant = payload.get("restaurant", {})
    joined = "|".join(
        value or ""
        for value in [
            _clean_text(restaurant.get("camis_raw")),
            _clean_text(inspection.get("inspection_date_raw")),
            _clean_text(inspection.get("inspection_type_raw")),
            _clean_text(inspection.get("action_raw")),
            _clean_text(inspection.get("score_raw")),
        ]
    )
    return sha256(joined.encode("utf-8")).hexdigest()


def _source_finding_key(payload: dict[str, Any]) -> str:
    source_finding_key = _clean_text(payload.get("source_finding_key"))
    if source_finding_key:
        return source_finding_key
    joined = "|".join(
        value or ""
        for value in [
            _source_inspection_key({"inspection": payload.get("inspection"), "restaurant": payload.get("restaurant")}),
            _clean_text(payload.get("violation_code_raw")),
            _clean_text(payload.get("violation_description_raw")),
            _clean_text(payload.get("critical_flag_raw")),
            str(payload.get("finding_order") or ""),
        ]
    )
    return sha256(joined.encode("utf-8")).hexdigest()


def _parse_date(value: str | None) -> date | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    return date.fromisoformat(cleaned)


def _parse_score(value: str | None) -> float | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    return float(cleaned)


@lru_cache(maxsize=512)
def _get_source_metadata(source_id: str) -> tuple[str, str]:
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select
                    platform_id::text as platform_id,
                    source_slug
                from ops.source_registry
                where source_id = %s::uuid
                limit 1
                """,
                (source_id,),
            )
            row = cur.fetchone()
            if row is None:
                raise ValueError(f"Source {source_id} was not found in ops.source_registry.")
            return row["platform_id"], row["source_slug"]


def _find_existing_inspection(cur, *, platform_id: str, source_inspection_key: str) -> dict[str, Any] | None:
    cur.execute(
        """
        select
            mi.master_inspection_id::text as master_inspection_id,
            mi.master_restaurant_id::text as master_restaurant_id,
            mi.platform_id::text as platform_id,
            mi.source_id::text as source_id,
            mi.created_at
        from master.master_inspection mi
        where
            mi.platform_id = %s::uuid
            and mi.source_inspection_key = %s
        order by mi.created_at, mi.master_inspection_id
        limit 1
        """,
        (platform_id, source_inspection_key),
    )
    return cur.fetchone()


def _get_or_create_restaurant(cur, payload: dict[str, Any]) -> tuple[str, int]:
    restaurant = payload.get("restaurant", {})
    camis = _clean_text(restaurant.get("camis_raw"))
    location_fingerprint = _location_fingerprint(payload)
    display_name = _clean_text(restaurant.get("dba_raw")) or "Unknown restaurant"
    address_line1 = _clean_text(restaurant.get("address_line1_raw")) or "Unknown address"
    city = _clean_text(restaurant.get("boro_raw")) or "New York City"
    state_code = "NY"
    zip_code = _clean_text(restaurant.get("zipcode_raw"))
    normalized_name = _normalize_name(display_name)
    normalized_address1 = _normalize_name(address_line1)

    row = None
    if camis is not None:
        cur.execute(
            """
            select mri.master_restaurant_id::text as master_restaurant_id
            from master.master_restaurant_identifier mri
            where
                mri.identifier_type = 'camis'
                and mri.identifier_value = %s
            order by mri.created_at
            limit 1
            """,
            (camis,),
        )
        row = cur.fetchone()

    if row is None:
        cur.execute(
            """
            select master_restaurant_id::text as master_restaurant_id
            from master.master_restaurant
            where location_fingerprint = %s
            order by created_at
            limit 1
            """,
            (location_fingerprint,),
        )
        row = cur.fetchone()

    if row is not None:
        cur.execute(
            """
            update master.master_restaurant
            set
                display_name = %s,
                normalized_name = %s,
                address_line1 = %s,
                normalized_address1 = %s,
                city = %s,
                state_code = %s,
                zip_code = coalesce(%s, zip_code),
                updated_at = now()
            where master_restaurant_id = %s::uuid
            """,
            (
                display_name,
                normalized_name,
                address_line1,
                normalized_address1,
                city,
                state_code,
                zip_code,
                row["master_restaurant_id"],
            ),
        )
        return row["master_restaurant_id"], 1

    cur.execute(
        """
        insert into master.master_restaurant (
            location_fingerprint,
            display_name,
            normalized_name,
            address_line1,
            normalized_address1,
            city,
            state_code,
            zip_code
        )
        values (%s, %s, %s, %s, %s, %s, %s, %s)
        returning master_restaurant_id::text as master_restaurant_id
        """,
        (
            location_fingerprint,
            display_name,
            normalized_name,
            address_line1,
            normalized_address1,
            city,
            state_code,
            zip_code,
        ),
    )
    return cur.fetchone()["master_restaurant_id"], 1


def _ensure_identifier(cur, *, master_restaurant_id: str, source_id: str, payload: dict[str, Any]) -> int:
    restaurant = payload.get("restaurant", {})
    camis = _clean_text(restaurant.get("camis_raw"))
    if camis is None:
        return 0

    cur.execute(
        """
        select master_restaurant_identifier_id::text
        from master.master_restaurant_identifier
        where
            master_restaurant_id = %s::uuid
            and source_id = %s::uuid
            and identifier_type = 'camis'
            and identifier_value = %s
        limit 1
        """,
        (master_restaurant_id, source_id, camis),
    )
    if cur.fetchone() is not None:
        return 0

    cur.execute(
        """
        insert into master.master_restaurant_identifier (
            master_restaurant_id,
            source_id,
            identifier_type,
            identifier_value,
            is_primary,
            confidence
        )
        values (%s::uuid, %s::uuid, 'camis', %s, true, 1.00)
        """,
        (master_restaurant_id, source_id, camis),
    )
    return 1


def _ensure_source_link(cur, *, master_restaurant_id: str, source_id: str, payload: dict[str, Any]) -> int:
    source_restaurant_key = _source_restaurant_key(payload)
    cur.execute(
        """
        insert into master.master_restaurant_source_link (
            master_restaurant_id,
            source_id,
            source_restaurant_key,
            match_method,
            match_confidence,
            match_status
        )
        values (%s::uuid, %s::uuid, %s, 'exact_source_identifier', 1.00, 'matched')
        on conflict (source_id, source_restaurant_key)
        do update set
            master_restaurant_id = excluded.master_restaurant_id,
            match_method = excluded.match_method,
            match_confidence = excluded.match_confidence,
            match_status = excluded.match_status,
            updated_at = now()
        """,
        (master_restaurant_id, source_id, source_restaurant_key),
    )
    return 1


def _upsert_official_report(cur, *, master_inspection_id: str, source_id: str, payload: dict[str, Any]) -> int:
    source_page_url = _clean_text(payload.get("source_metadata", {}).get("source_url"))
    cur.execute(
        """
        select master_inspection_report_id::text as master_inspection_report_id
        from master.master_inspection_report
        where
            master_inspection_id = %s::uuid
            and report_role = 'official_source_report'
        limit 1
        """,
        (master_inspection_id,),
    )
    existing = cur.fetchone()
    if existing is None:
        cur.execute(
            """
            insert into master.master_inspection_report (
                master_inspection_id,
                source_id,
                report_role,
                report_format,
                availability_status,
                source_page_url,
                source_file_url,
                storage_path,
                is_current
            )
            values (
                %s::uuid,
                %s::uuid,
                'official_source_report',
                'json',
                'not_provided_by_source',
                %s,
                null,
                null,
                true
            )
            """,
            (master_inspection_id, source_id, source_page_url),
        )
        return 1

    cur.execute(
        """
        update master.master_inspection_report
        set
            source_id = %s::uuid,
            source_page_url = %s,
            updated_at = now()
        where master_inspection_report_id = %s::uuid
        """,
        (source_id, source_page_url, existing["master_inspection_report_id"]),
    )
    return 1


def normalize_inspection_payload(*, source_id: str, payload: dict[str, Any]) -> NormalizedInspectionResult:
    inspection = payload.get("inspection", {})
    source_inspection_key = _source_inspection_key(payload)
    platform_id, _ = _get_source_metadata(source_id)

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            normalized_count = 0
            master_restaurant_id, touched = _get_or_create_restaurant(cur, payload)
            normalized_count += touched
            normalized_count += _ensure_identifier(
                cur,
                master_restaurant_id=master_restaurant_id,
                source_id=source_id,
                payload=payload,
            )
            normalized_count += _ensure_source_link(
                cur,
                master_restaurant_id=master_restaurant_id,
                source_id=source_id,
                payload=payload,
            )

            inspection_date = _parse_date(inspection.get("inspection_date_raw"))
            if inspection_date is None or inspection_date == date(1900, 1, 1):
                conn.commit()
                return NormalizedInspectionResult(
                    master_restaurant_id=master_restaurant_id,
                    master_inspection_id="",
                    source_inspection_key=source_inspection_key,
                    normalized_count=normalized_count,
                )

            existing = _find_existing_inspection(
                cur,
                platform_id=platform_id,
                source_inspection_key=source_inspection_key,
            )
            if existing is None:
                cur.execute(
                    """
                    insert into master.master_inspection (
                        master_restaurant_id,
                        platform_id,
                        source_id,
                        source_inspection_key,
                        inspection_date,
                        inspection_type,
                        score,
                        grade,
                        official_status,
                        report_url,
                        is_current
                    )
                    values (
                        %s::uuid,
                        %s::uuid,
                        %s::uuid,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        true
                    )
                    returning master_inspection_id::text as master_inspection_id
                    """,
                    (
                        master_restaurant_id,
                        platform_id,
                        source_id,
                        source_inspection_key,
                        inspection_date,
                        _clean_text(inspection.get("inspection_type_raw")),
                        _parse_score(inspection.get("score_raw")),
                        _clean_text(inspection.get("grade_raw")),
                        _clean_text(inspection.get("action_raw")),
                        _clean_text(payload.get("source_metadata", {}).get("source_url")),
                    ),
                )
                master_inspection_id = cur.fetchone()["master_inspection_id"]
                canonical_source_id = source_id
            else:
                cur.execute(
                    """
                    update master.master_inspection
                    set
                        master_restaurant_id = %s::uuid,
                        platform_id = %s::uuid,
                        inspection_date = %s,
                        inspection_type = %s,
                        score = %s,
                        grade = %s,
                        official_status = %s,
                        report_url = %s,
                        updated_at = now()
                    where master_inspection_id = %s::uuid
                    """,
                    (
                        master_restaurant_id,
                        platform_id,
                        inspection_date,
                        _clean_text(inspection.get("inspection_type_raw")),
                        _parse_score(inspection.get("score_raw")),
                        _clean_text(inspection.get("grade_raw")),
                        _clean_text(inspection.get("action_raw")),
                        _clean_text(payload.get("source_metadata", {}).get("source_url")),
                        existing["master_inspection_id"],
                    ),
                )
                master_inspection_id = existing["master_inspection_id"]
                canonical_source_id = existing["source_id"]
            normalized_count += 1
            normalized_count += _upsert_official_report(
                cur,
                master_inspection_id=master_inspection_id,
                source_id=canonical_source_id,
                payload=payload,
            )
        conn.commit()

    return NormalizedInspectionResult(
        master_restaurant_id=master_restaurant_id,
        master_inspection_id=master_inspection_id,
        source_inspection_key=source_inspection_key,
        normalized_count=normalized_count,
    )


def normalize_finding_payload(*, source_id: str, payload: dict[str, Any]) -> int:
    source_inspection_key = _source_inspection_key(payload)
    source_finding_key = _source_finding_key(payload)
    platform_id, _ = _get_source_metadata(source_id)

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            inspection_row = _find_existing_inspection(
                cur,
                platform_id=platform_id,
                source_inspection_key=source_inspection_key,
            )
            if inspection_row is None:
                return 0

            cur.execute(
                """
                select master_inspection_finding_id::text as master_inspection_finding_id
                from master.master_inspection_finding
                where
                    master_inspection_id = %s::uuid
                    and source_finding_key = %s
                limit 1
                """,
                (inspection_row["master_inspection_id"], source_finding_key),
            )
            existing = cur.fetchone()

            payload_json = {
                "critical_flag_raw": _clean_text(payload.get("critical_flag_raw")),
            }
            finding_order = payload.get("finding_order")
            params = (
                inspection_row["master_inspection_id"],
                inspection_row["source_id"],
                source_finding_key,
                finding_order,
                _clean_text(payload.get("violation_code_raw")),
                _clean_text(payload.get("violation_code_raw")),
                _clean_text(payload.get("violation_description_raw")) or "Unknown finding",
                _clean_text(payload.get("critical_flag_raw")),
                json.dumps(payload_json),
                _clean_text(payload.get("violation_description_raw")),
                _clean_text(payload.get("critical_flag_raw")),
            )

            if existing is None:
                cur.execute(
                    """
                    insert into master.master_inspection_finding (
                        master_inspection_id,
                        source_id,
                        source_finding_key,
                        finding_order,
                        official_code,
                        official_clause_reference,
                        official_text,
                        official_detail_text,
                        official_detail_json,
                        normalized_title,
                        severity,
                        is_current
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
                        %s::jsonb,
                        %s,
                        %s,
                        true
                    )
                    """,
                    params,
                )
            else:
                cur.execute(
                    """
                    update master.master_inspection_finding
                    set
                        master_inspection_id = %s::uuid,
                        source_id = %s::uuid,
                        finding_order = %s,
                        official_code = %s,
                        official_clause_reference = %s,
                        official_text = %s,
                        official_detail_text = %s,
                        official_detail_json = %s::jsonb,
                        normalized_title = %s,
                        severity = %s,
                        updated_at = now()
                    where master_inspection_finding_id = %s::uuid
                    """,
                    (*params, existing["master_inspection_finding_id"]),
                )
        conn.commit()

    return 1
