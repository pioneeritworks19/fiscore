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
    return re.sub(r"[^a-z0-9]+", "", cleaned.lower())


def _normalize_name(value: str | None) -> str | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    return re.sub(r"[^a-z0-9]+", " ", cleaned.lower()).strip() or None


def _location_fingerprint(payload: dict[str, Any]) -> str:
    restaurant = payload.get("restaurant", {})
    city = _clean_text(restaurant.get("city_raw"))
    state = _clean_text(restaurant.get("state_raw")) or "GA"
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
    facility_token = _clean_text(payload.get("facility_token"))
    if facility_token:
        return f"ga-facility:{facility_token}"

    restaurant = payload.get("restaurant", {})
    facility_token = _clean_text(restaurant.get("facility_token"))
    if facility_token:
        return f"ga-facility:{facility_token}"

    permit_number = _clean_text(restaurant.get("license_number_raw"))
    if permit_number:
        return f"ga-permit:{permit_number}"
    return _location_fingerprint(payload)


def _source_inspection_key(payload: dict[str, Any]) -> str:
    inspection_id_raw = _clean_text(payload.get("inspection_id_raw"))
    if inspection_id_raw:
        return f"ga-inspection:{inspection_id_raw}"

    inspection_source_record_key = _clean_text(payload.get("inspection_source_record_key"))
    if inspection_source_record_key:
        return f"ga-record:{inspection_source_record_key}"

    report_url = _clean_text(payload.get("report_url"))
    if report_url:
        return f"ga-report:{report_url}"

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
    if joined.replace("|", ""):
        return sha256(joined.encode("utf-8")).hexdigest()

    detail_url = _clean_text(payload.get("detail_url"))
    if detail_url:
        return f"ga-detail:{detail_url}"

    return sha256(repr(payload).encode("utf-8")).hexdigest()


def _source_finding_key(payload: dict[str, Any]) -> str:
    inspection_id_raw = _clean_text(payload.get("inspection_id_raw"))
    violation_index_raw = _clean_text(payload.get("violation_index_raw"))
    if inspection_id_raw and violation_index_raw:
        return f"ga-finding:{inspection_id_raw}:{violation_index_raw}"

    joined = "|".join(
        value or ""
        for value in [
            _source_inspection_key(payload),
            _clean_text(payload.get("violation_code_raw")),
            _clean_text(payload.get("official_text")),
            _clean_text(payload.get("official_detail_text")),
        ]
    )
    return sha256(joined.encode("utf-8")).hexdigest()


def _parse_date(value: str | None) -> date | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    cleaned = cleaned.replace("-", "/")
    month, day, year = cleaned.split("/")
    return date(int(year), int(month), int(day))


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


def build_source_inspection_key(payload: dict[str, Any]) -> str:
    return _source_inspection_key(payload)


def find_existing_source_inspection_keys(*, source_id: str, source_inspection_keys: list[str]) -> set[str]:
    cleaned_keys = [key for key in source_inspection_keys if _clean_text(key)]
    if not cleaned_keys:
        return set()

    platform_id, _ = _get_source_metadata(source_id)
    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                """
                select source_inspection_key
                from master.master_inspection
                where
                    platform_id = %s::uuid
                    and source_inspection_key = any(%s::text[])
                """,
                (platform_id, cleaned_keys),
            )
            return {str(row["source_inspection_key"]) for row in cur.fetchall()}


def _get_or_create_restaurant(cur, *, source_id: str, payload: dict[str, Any]) -> tuple[str, int]:
    restaurant = payload.get("restaurant", {})
    facility_token = _clean_text(payload.get("facility_token")) or _clean_text(
        restaurant.get("facility_token")
    )
    permit_number = _clean_text(restaurant.get("license_number_raw"))
    location_fingerprint = _location_fingerprint(payload)
    display_name = _clean_text(restaurant.get("restaurant_name_raw")) or "Unknown restaurant"
    address_line1 = _clean_text(restaurant.get("address_raw")) or "Unknown address"
    city = _clean_text(restaurant.get("city_raw")) or "Unknown city"
    state_code = _clean_text(restaurant.get("state_raw")) or "GA"
    zip_code = _clean_text(restaurant.get("zip_code_raw"))
    normalized_name = _normalize_name(display_name)
    normalized_address1 = _normalize_name(address_line1)

    row = None
    if facility_token is not None:
        cur.execute(
            """
            select mri.master_restaurant_id::text as master_restaurant_id
            from master.master_restaurant_identifier mri
            where
                mri.source_id = %s::uuid
                and
                mri.identifier_type = 'facility_token'
                and mri.identifier_value = %s
            order by mri.created_at
            limit 1
            """,
            (source_id, facility_token),
        )
        row = cur.fetchone()

    if row is None and permit_number is not None:
        cur.execute(
            """
            select mri.master_restaurant_id::text as master_restaurant_id
            from master.master_restaurant_identifier mri
            where
                mri.source_id = %s::uuid
                and mri.identifier_type = 'permit_number'
                and mri.identifier_value = %s
            order by mri.created_at
            limit 1
            """,
            (source_id, permit_number),
        )
        row = cur.fetchone()

    if row is None and facility_token is None and permit_number is None:
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
    inserted = 0
    facility_token = _clean_text(payload.get("facility_token")) or _clean_text(
        restaurant.get("facility_token")
    )
    if facility_token is not None:
        cur.execute(
            """
            select master_restaurant_identifier_id::text
            from master.master_restaurant_identifier
            where
                master_restaurant_id = %s::uuid
                and identifier_type = 'facility_token'
                and identifier_value = %s
            limit 1
            """,
            (master_restaurant_id, facility_token),
        )
        if cur.fetchone() is None:
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
                values (%s::uuid, %s::uuid, 'facility_token', %s, false, 1.00)
                """,
                (master_restaurant_id, source_id, facility_token),
            )
            inserted += 1

    permit_number = _clean_text(restaurant.get("license_number_raw"))
    if permit_number is None:
        return inserted

    cur.execute(
        """
        select master_restaurant_identifier_id::text
        from master.master_restaurant_identifier
        where
            master_restaurant_id = %s::uuid
            and source_id = %s::uuid
            and identifier_type = 'permit_number'
            and identifier_value = %s
        limit 1
        """,
        (master_restaurant_id, source_id, permit_number),
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
        values (%s::uuid, %s::uuid, 'permit_number', %s, true, 1.00)
        """,
        (master_restaurant_id, source_id, permit_number),
    )
    return inserted + 1


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
    storage_path: str | None = None,
    report_format: str | None = None,
) -> int:
    report_url = _clean_text(payload.get("report_url"))
    cur.execute(
        """
        select master_inspection_report_id::text as master_inspection_report_id
        from master.master_inspection_report
        where
            master_inspection_id = %s::uuid
            and report_role = 'official_audit_report'
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
                'official_audit_report',
                %s,
                %s,
                %s,
                %s,
                %s,
                true
            )
            """,
            (
                master_inspection_id,
                source_id,
                report_format,
                "available" if report_url else "not_provided_by_source",
                _clean_text(payload.get("detail_url")),
                report_url,
                storage_path,
            ),
        )
        return 1

    cur.execute(
        """
        update master.master_inspection_report
        set
            source_id = %s::uuid,
            report_format = %s,
            availability_status = %s,
            source_page_url = %s,
            source_file_url = %s,
            storage_path = %s,
            is_current = true,
            updated_at = now()
        where master_inspection_report_id = %s::uuid
        """,
        (
            source_id,
            report_format,
            "available" if report_url else "not_provided_by_source",
            _clean_text(payload.get("detail_url")),
            report_url,
            storage_path,
            existing["master_inspection_report_id"],
        ),
    )
    return 1


def normalize_inspection_payload(*, source_id: str, payload: dict[str, Any]) -> NormalizedInspectionResult:
    inspection = payload.get("inspection_summary", {})
    source_inspection_key = _source_inspection_key(payload)
    platform_id, _ = _get_source_metadata(source_id)

    with get_connection() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            normalized_count = 0
            master_restaurant_id, touched = _get_or_create_restaurant(cur, source_id=source_id, payload=payload)
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
                        inspector_name,
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
                        _parse_date(inspection.get("inspection_date_raw")),
                        _clean_text(inspection.get("inspection_type_raw")),
                        _parse_score(inspection.get("inspection_score_raw")),
                        _clean_text(inspection.get("inspection_grade_raw")),
                        _clean_text(inspection.get("inspector_name_raw")),
                        _clean_text(payload.get("report_url")),
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
                        inspector_name = %s,
                        report_url = %s,
                        updated_at = now()
                    where master_inspection_id = %s::uuid
                    """,
                    (
                        master_restaurant_id,
                        platform_id,
                        _parse_date(inspection.get("inspection_date_raw")),
                        _clean_text(inspection.get("inspection_type_raw")),
                        _parse_score(inspection.get("inspection_score_raw")),
                        _clean_text(inspection.get("inspection_grade_raw")),
                        _clean_text(inspection.get("inspector_name_raw")),
                        _clean_text(payload.get("report_url")),
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


def attach_report_artifact(
    *,
    source_id: str,
    inspection_payload: dict[str, Any],
    storage_path: str,
    report_format: str,
) -> int:
    source_inspection_key = _source_inspection_key(inspection_payload)
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
            _upsert_official_report(
                cur,
                master_inspection_id=inspection_row["master_inspection_id"],
                source_id=inspection_row["source_id"],
                payload=inspection_payload,
                storage_path=storage_path,
                report_format=report_format,
            )
        conn.commit()
    return 1


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

            params = (
                inspection_row["master_inspection_id"],
                inspection_row["source_id"],
                source_finding_key,
                _clean_text(payload.get("violation_code_raw")),
                _clean_text(payload.get("violation_code_raw")),
                _clean_text(payload.get("official_text")) or "Unknown finding",
                _clean_text(payload.get("official_detail_text")),
                json.dumps(payload.get("official_detail_json"))
                if payload.get("official_detail_json") is not None
                else None,
                _clean_text(payload.get("auditor_comments")),
                payload.get("corrected_during_inspection"),
                payload.get("is_repeat_violation"),
                _clean_text(payload.get("violation_category_raw")),
                _clean_text(payload.get("violation_category_raw")),
            )

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
                        corrected_during_inspection,
                        is_repeat_violation,
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
                        %s,
                        %s,
                        %s,
                        %s::jsonb,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s,
                        true
                    )
                    """,
                    (*params, None),
                )
            else:
                cur.execute(
                    """
                    update master.master_inspection_finding
                    set
                        master_inspection_id = %s::uuid,
                        source_id = %s::uuid,
                        official_code = %s,
                        official_clause_reference = %s,
                        official_text = %s,
                        official_detail_text = %s,
                        official_detail_json = %s::jsonb,
                        auditor_comments = %s,
                        corrected_during_inspection = %s,
                        is_repeat_violation = %s,
                        normalized_title = %s,
                        normalized_category = %s,
                        updated_at = now()
                    where master_inspection_finding_id = %s::uuid
                    """,
                    (
                        inspection_row["master_inspection_id"],
                        inspection_row["source_id"],
                        _clean_text(payload.get("violation_code_raw")),
                        _clean_text(payload.get("violation_code_raw")),
                        _clean_text(payload.get("official_text")) or "Unknown finding",
                        _clean_text(payload.get("official_detail_text")),
                        json.dumps(payload.get("official_detail_json"))
                        if payload.get("official_detail_json") is not None
                        else None,
                        _clean_text(payload.get("auditor_comments")),
                        payload.get("corrected_during_inspection"),
                        payload.get("is_repeat_violation"),
                        _clean_text(payload.get("violation_category_raw")),
                        _clean_text(payload.get("violation_category_raw")),
                        existing["master_inspection_finding_id"],
                    ),
                )
        conn.commit()

    return 1
