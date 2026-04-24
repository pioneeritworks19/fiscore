from __future__ import annotations

from dataclasses import dataclass
from datetime import date
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
    return re.sub(r"[^a-z0-9]+", "", cleaned.lower())


def _normalize_name(value: str | None) -> str | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    return re.sub(r"[^a-z0-9]+", " ", cleaned.lower()).strip() or None


def _location_fingerprint(payload: dict[str, Any]) -> str:
    restaurant = payload.get("restaurant", {})
    city = _clean_text(restaurant.get("city_raw"))
    state = _clean_text(restaurant.get("state_raw")) or "MI"
    zip_code = _clean_text(restaurant.get("zip_code_raw"))
    address = _clean_text(restaurant.get("address_raw"))
    joined = "|".join(
        filter(
            None,
            [
                _normalize_token(address),
                _normalize_token(city),
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
                _normalize_token(restaurant.get("license_number_raw")),
                _normalize_token(restaurant.get("restaurant_name_raw")),
            ],
        )
    )
    return sha256(fallback.encode("utf-8")).hexdigest()


def _source_restaurant_key(payload: dict[str, Any]) -> str:
    restaurant = payload.get("restaurant", {})
    county_name = _clean_text(payload.get("county_name"))
    license_number = _clean_text(restaurant.get("license_number_raw"))
    if county_name and license_number:
        return f"{county_name}|{license_number}"
    return _location_fingerprint(payload)


def _source_inspection_key(payload: dict[str, Any]) -> str:
    header_id = _clean_text(payload.get("header_id"))
    if header_id:
        return f"sword-header:{header_id}"

    inspection = payload.get("inspection_summary", {})
    restaurant = payload.get("restaurant", {})
    joined = "|".join(
        value or ""
        for value in [
            _clean_text(payload.get("county_name")),
            _clean_text(restaurant.get("license_number_raw")),
            _clean_text(inspection.get("inspection_date_raw")),
            _clean_text(inspection.get("inspection_type_raw")),
        ]
    )
    return sha256(joined.encode("utf-8")).hexdigest()


def _parse_date(value: str | None) -> date | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    if " " in cleaned:
        cleaned = cleaned.split(" ", 1)[0]
    return date.fromisoformat(cleaned)


def _parse_score(value: str | None) -> float | None:
    cleaned = _clean_text(value)
    if cleaned is None or cleaned == "0":
        return None
    return float(cleaned)


def _get_or_create_restaurant(cur, payload: dict[str, Any]) -> tuple[str, int]:
    restaurant = payload.get("restaurant", {})
    location_fingerprint = _location_fingerprint(payload)
    display_name = _clean_text(restaurant.get("restaurant_name_raw")) or "Unknown restaurant"
    address_line1 = _clean_text(restaurant.get("address_raw")) or "Unknown address"
    city = _clean_text(restaurant.get("city_raw")) or "Unknown city"
    state_code = _clean_text(restaurant.get("state_raw")) or "MI"
    zip_code = _clean_text(restaurant.get("zip_code_raw"))
    normalized_name = _normalize_name(display_name)
    normalized_address1 = _normalize_name(address_line1)

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
    license_number = _clean_text(restaurant.get("license_number_raw"))
    if license_number is None:
        return 0

    cur.execute(
        """
        select master_restaurant_identifier_id::text
        from master.master_restaurant_identifier
        where
            master_restaurant_id = %s::uuid
            and source_id = %s::uuid
            and identifier_type = 'license_number'
            and identifier_value = %s
        limit 1
        """,
        (master_restaurant_id, source_id, license_number),
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
        values (%s::uuid, %s::uuid, 'license_number', %s, true, 1.00)
        """,
        (master_restaurant_id, source_id, license_number),
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


def _upsert_official_report(
    cur,
    *,
    master_inspection_id: str,
    source_id: str,
    payload: dict[str, Any],
) -> int:
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
            null,
            'not_provided_by_source',
            %s,
            null,
            null,
            true
        )
        on conflict (master_inspection_id, source_id, report_role)
        do update set
            report_format = excluded.report_format,
            availability_status = excluded.availability_status,
            source_page_url = excluded.source_page_url,
            source_file_url = excluded.source_file_url,
            storage_path = excluded.storage_path,
            is_current = excluded.is_current,
            updated_at = now()
        """,
        (
            master_inspection_id,
            source_id,
            _clean_text(payload.get("detail_url")),
        ),
    )
    return 1


def normalize_inspection_payload(*, source_id: str, payload: dict[str, Any]) -> NormalizedInspectionResult:
    inspection = payload.get("inspection_summary", {})
    source_inspection_key = _source_inspection_key(payload)

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

            cur.execute(
                """
                insert into master.master_inspection (
                    master_restaurant_id,
                    source_id,
                    source_inspection_key,
                    inspection_date,
                    inspection_type,
                    score,
                    grade,
                    report_url,
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
                    true
                )
                on conflict (source_id, source_inspection_key)
                do update set
                    master_restaurant_id = excluded.master_restaurant_id,
                    inspection_date = excluded.inspection_date,
                    inspection_type = excluded.inspection_type,
                    score = excluded.score,
                    grade = excluded.grade,
                    report_url = excluded.report_url,
                    updated_at = now()
                returning master_inspection_id::text as master_inspection_id
                """,
                (
                    master_restaurant_id,
                    source_id,
                    source_inspection_key,
                    _parse_date(inspection.get("inspection_date_raw")),
                    _clean_text(inspection.get("inspection_type_raw")),
                    _parse_score(inspection.get("inspection_score_raw")),
                    _clean_text(inspection.get("inspection_grade_raw")),
                    None,
                ),
            )
            master_inspection_id = cur.fetchone()["master_inspection_id"]
            normalized_count += 1
            normalized_count += _upsert_official_report(
                cur,
                master_inspection_id=master_inspection_id,
                source_id=source_id,
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
    header_id = _clean_text(payload.get("header_id"))
    if header_id is None:
        return 0

    source_inspection_key = f"sword-header:{header_id}"
    source_finding_key = _clean_text(payload.get("detail_id"))
    if source_finding_key:
        source_finding_key = f"sword-detail:{source_finding_key}"

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select master_inspection_id::text as master_inspection_id
                from master.master_inspection
                where source_id = %s::uuid and source_inspection_key = %s
                limit 1
                """,
                (source_id, source_inspection_key),
            )
            inspection_row = cur.fetchone()
            if inspection_row is None:
                return 0

            cur.execute(
                """
                select master_inspection_finding_id::text as master_inspection_finding_id
                from master.master_inspection_finding
                where source_id = %s::uuid and source_finding_key = %s
                limit 1
                """,
                (source_id, source_finding_key),
            )
            existing = cur.fetchone()

            if existing is None:
                cur.execute(
                    """
                    insert into master.master_inspection_finding (
                        master_inspection_id,
                        source_id,
                        source_finding_key,
                        official_code,
                        official_clause_reference,
                        official_text,
                        official_detail_text,
                        official_detail_json,
                        auditor_comments,
                        normalized_title,
                        normalized_category,
                        severity,
                        is_current
                    )
                    values (
                        %s::uuid,
                        %s::uuid,
                        %s,
                        %s,
                        %s::jsonb,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        true
                    )
                    """,
                    (
                        inspection_row["master_inspection_id"],
                        source_id,
                        source_finding_key,
                        _clean_text(payload.get("violation_code_raw")),
                        _clean_text(payload.get("violation_code_raw")),
                        _clean_text(payload.get("official_text")) or "Unknown finding",
                        _clean_text(payload.get("official_detail_text")),
                        json.dumps(payload.get("official_detail_json"))
                        if payload.get("official_detail_json") is not None
                        else None,
                        _clean_text(payload.get("auditor_comments")),
                        _clean_text(payload.get("violation_category_raw")),
                        _clean_text(payload.get("violation_category_raw")),
                        None,
                    ),
                )
            else:
                cur.execute(
                    """
                    update master.master_inspection_finding
                    set
                        master_inspection_id = %s::uuid,
                        official_code = %s,
                        official_clause_reference = %s,
                        official_text = %s,
                        official_detail_text = %s,
                        official_detail_json = %s::jsonb,
                        auditor_comments = %s,
                        normalized_title = %s,
                        normalized_category = %s,
                        updated_at = now()
                    where master_inspection_finding_id = %s::uuid
                    """,
                    (
                        inspection_row["master_inspection_id"],
                        _clean_text(payload.get("violation_code_raw")),
                        _clean_text(payload.get("violation_code_raw")),
                        _clean_text(payload.get("official_text")) or "Unknown finding",
                        _clean_text(payload.get("official_detail_text")),
                        json.dumps(payload.get("official_detail_json"))
                        if payload.get("official_detail_json") is not None
                        else None,
                        _clean_text(payload.get("auditor_comments")),
                        _clean_text(payload.get("violation_category_raw")),
                        _clean_text(payload.get("violation_category_raw")),
                        existing["master_inspection_finding_id"],
                    ),
                )
        conn.commit()

    return 1
