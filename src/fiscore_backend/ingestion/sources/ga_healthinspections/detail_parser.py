from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
import re
from typing import Any
from urllib.parse import urljoin, urlparse

from bs4 import BeautifulSoup


@dataclass(frozen=True)
class GeorgiaInspectionDetail:
    county_name: str | None
    restaurant_name_raw: str | None
    license_number_raw: str | None
    address_raw: str | None
    city_raw: str | None
    state_raw: str | None
    zip_code_raw: str | None
    inspection_date_raw: str | None
    inspection_type_raw: str | None
    inspection_score_raw: str | None
    inspection_grade_raw: str | None
    inspector_name_raw: str | None
    detail_url: str
    report_url: str | None
    source_record_key: str

    def to_payload(self, *, source_url: str) -> dict[str, Any]:
        return {
            "county_name": self.county_name,
            "inspection_id_raw": self.source_record_key,
            "source_url": source_url,
            "restaurant": {
                "restaurant_name_raw": self.restaurant_name_raw,
                "license_number_raw": self.license_number_raw,
                "address_raw": self.address_raw,
                "city_raw": self.city_raw,
                "state_raw": self.state_raw,
                "zip_code_raw": self.zip_code_raw,
            },
            "inspection_summary": {
                "inspection_date_raw": self.inspection_date_raw,
                "inspection_type_raw": self.inspection_type_raw,
                "inspection_score_raw": self.inspection_score_raw,
                "inspection_grade_raw": self.inspection_grade_raw,
                "inspector_name_raw": self.inspector_name_raw,
            },
            "detail_url": self.detail_url,
            "report_url": self.report_url,
        }


@dataclass(frozen=True)
class GeorgiaFinding:
    violation_code_raw: str | None
    violation_category_raw: str | None
    points_deducted_raw: str | None
    corrected_during_inspection: bool | None
    is_repeat_violation: bool | None
    official_text: str
    official_detail_text: str | None
    official_detail_json: dict[str, Any] | None
    auditor_comments: str | None
    source_record_key: str

    def to_payload(self, *, inspection_payload: dict[str, Any], source_url: str) -> dict[str, Any]:
        return {
            "source_url": source_url,
            "detail_url": inspection_payload.get("detail_url"),
            "report_url": inspection_payload.get("report_url"),
            "county_name": inspection_payload.get("county_name"),
            "restaurant": inspection_payload.get("restaurant"),
            "inspection_summary": inspection_payload.get("inspection_summary"),
            "violation_code_raw": self.violation_code_raw,
            "violation_category_raw": self.violation_category_raw,
            "points_deducted_raw": self.points_deducted_raw,
            "corrected_during_inspection": self.corrected_during_inspection,
            "is_repeat_violation": self.is_repeat_violation,
            "official_text": self.official_text,
            "official_detail_text": self.official_detail_text,
            "official_detail_json": self.official_detail_json,
            "auditor_comments": self.auditor_comments,
        }


@dataclass(frozen=True)
class GeorgiaDetailParseResult:
    inspection: GeorgiaInspectionDetail | None
    findings: list[GeorgiaFinding]
    warnings: list[str]


@dataclass(frozen=True)
class GeorgiaInspectionHistoryRecord:
    inspection: GeorgiaInspectionDetail
    findings: list[GeorgiaFinding]
    warnings: list[str]


@dataclass(frozen=True)
class GeorgiaDetailHistoryParseResult:
    inspections: list[GeorgiaInspectionHistoryRecord]
    warnings: list[str]


def _clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = " ".join(str(value).split())
    return cleaned or None


def _build_source_record_key(*values: str | None) -> str:
    joined = "|".join(value or "" for value in values)
    return sha256(joined.encode("utf-8")).hexdigest()


def _extract_label_value(lines: list[str], label: str) -> str | None:
    prefix = f"{label}:"
    for line in lines:
        if line.lower().startswith(prefix.lower()):
            return _clean_text(line[len(prefix) :])
    return None


def _extract_column_value(columns: dict[str, Any], index: str, prefix: str) -> str | None:
    raw = _clean_text(columns.get(index) if isinstance(columns, dict) else None)
    if raw is None:
        return None
    if raw.lower().startswith(prefix.lower()):
        return _clean_text(raw[len(prefix) :])
    return raw


def _parse_grade(score: str | None) -> str | None:
    cleaned = _clean_text(score)
    if cleaned is None:
        return None
    try:
        numeric = float(cleaned)
    except ValueError:
        return None
    if numeric >= 90:
        return "A"
    if numeric >= 80:
        return "B"
    if numeric >= 70:
        return "C"
    return "U"


def _parse_bool(value: str | None) -> bool | None:
    cleaned = (_clean_text(value) or "").lower()
    if cleaned in {"yes", "y", "true"}:
        return True
    if cleaned in {"no", "n", "false"}:
        return False
    return None


def _extract_restaurant_name(soup: BeautifulSoup, fallback_lines: list[str]) -> str | None:
    heading = soup.find(["h1", "h2", "h3"])
    if heading is not None:
        text = _clean_text(heading.get_text(" ", strip=True))
        if text and "violations" not in text.lower():
            return text
    return fallback_lines[0] if fallback_lines else None


def _parse_city_state_zip(text: str | None) -> tuple[str | None, str | None, str | None]:
    cleaned = _clean_text(text)
    if cleaned is None:
        return None, None, None
    match = re.match(r"(.+?),\s*([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$", cleaned)
    if match:
        return match.group(1).strip(), match.group(2).strip(), match.group(3).strip()
    return cleaned, None, None


def _split_violation_blocks(lines: list[str]) -> list[list[str]]:
    blocks: list[list[str]] = []
    current: list[str] = []
    for line in lines:
        if re.match(r"^[0-9]{1,2}[A-Z]\s*[-.]", line):
            if current:
                blocks.append(current)
            current = [line]
            continue
        if current:
            current.append(line)
    if current:
        blocks.append(current)
    return blocks


def _parse_html_detail_record(
    html: str,
    *,
    source_url: str,
    county_name: str | None = None,
    fallback_restaurant: dict[str, Any] | None = None,
) -> GeorgiaInspectionHistoryRecord:
    soup = BeautifulSoup(html, "html.parser")
    lines = [_clean_text(line) for line in soup.get_text("\n", strip=True).splitlines()]
    lines = [line for line in lines if line]

    inspection_date = _extract_label_value(lines, "Date")
    inspection_type = _extract_label_value(lines, "Inspection Purpose")
    inspection_score = _extract_label_value(lines, "Score")
    inspector_name = _extract_label_value(lines, "Inspector")
    permit_number = (
        _extract_label_value(lines, "Permit #")
        or _extract_label_value(lines, "Permit")
        or (fallback_restaurant or {}).get("license_number_raw")
    )
    address = _extract_label_value(lines, "Address") or (fallback_restaurant or {}).get("address_raw")
    city_state_zip = _extract_label_value(lines, "City/State") or _extract_label_value(lines, "City")
    city, state, zip_code = _parse_city_state_zip(city_state_zip)

    report_link = next(
        (
            urljoin(source_url, link["href"])
            for link in soup.find_all("a", href=True)
            if "inspection report" in (link.get_text(" ", strip=True) or "").lower()
        ),
        None,
    )

    restaurant_name = _extract_restaurant_name(
        soup,
        [value for value in [(fallback_restaurant or {}).get("restaurant_name_raw")] if value],
    )
    inspection = GeorgiaInspectionDetail(
        county_name=county_name,
        restaurant_name_raw=restaurant_name,
        license_number_raw=_clean_text(permit_number),
        address_raw=_clean_text(address),
        city_raw=city or (fallback_restaurant or {}).get("city_raw"),
        state_raw=state or (fallback_restaurant or {}).get("state_raw") or "GA",
        zip_code_raw=zip_code or (fallback_restaurant or {}).get("zip_code_raw"),
        inspection_date_raw=inspection_date,
        inspection_type_raw=inspection_type,
        inspection_score_raw=inspection_score,
        inspection_grade_raw=_parse_grade(inspection_score),
        inspector_name_raw=inspector_name,
        detail_url=source_url,
        report_url=report_link,
        source_record_key=_build_source_record_key(
            county_name,
            permit_number,
            inspection_date,
            inspection_type,
            report_link,
            source_url,
        ),
    )

    findings: list[GeorgiaFinding] = []
    warnings: list[str] = []
    try:
        violation_index = next(i for i, line in enumerate(lines) if line.lower() == "violations")
    except StopIteration:
        violation_index = -1

    if violation_index >= 0:
        violation_lines = lines[violation_index + 1 :]
        for block in _split_violation_blocks(violation_lines):
            title_line = block[0]
            code_line = next((line for line in block[1:] if re.search(r"\d{3}-\d", line)), None)
            points_line = next((line for line in block if line.lower().startswith("points:")), None)
            corrected_line = next(
                (
                    line
                    for line in block
                    if line.lower().startswith("corrected during inspection")
                ),
                None,
            )
            repeat_line = next((line for line in block if line.lower().startswith("repeat:")), None)
            notes_line = next(
                (line for line in block if line.lower().startswith("inspector notes:")),
                None,
            )

            title_match = re.match(r"^([0-9]{1,2}[A-Z])\s*-\s*(.+)$", title_line)
            violation_category = title_match.group(2).strip() if title_match else title_line
            points_value = None
            if points_line:
                points_value = _clean_text(points_line.split(":", 1)[1])

            official_detail_json = {
                key: value
                for key, value in {
                    "code_reference": _clean_text(code_line),
                    "points_deducted": points_value,
                    "corrected_during_inspection": _parse_bool(
                        corrected_line.split(":", 1)[1] if corrected_line and ":" in corrected_line else None
                    ),
                    "is_repeat_violation": _parse_bool(
                        repeat_line.split(":", 1)[1] if repeat_line and ":" in repeat_line else None
                    ),
                }.items()
                if value is not None
            } or None

            findings.append(
                GeorgiaFinding(
                    violation_code_raw=_clean_text(code_line),
                    violation_category_raw=_clean_text(violation_category),
                    points_deducted_raw=points_value,
                    corrected_during_inspection=_parse_bool(
                        corrected_line.split(":", 1)[1] if corrected_line and ":" in corrected_line else None
                    ),
                    is_repeat_violation=_parse_bool(
                        repeat_line.split(":", 1)[1] if repeat_line and ":" in repeat_line else None
                    ),
                    official_text=_clean_text(title_line) or "Unknown finding",
                    official_detail_text=_clean_text(notes_line.split(":", 1)[1]) if notes_line and ":" in notes_line else None,
                    official_detail_json=official_detail_json,
                    auditor_comments=_clean_text(notes_line.split(":", 1)[1]) if notes_line and ":" in notes_line else None,
                    source_record_key=_build_source_record_key(
                        inspection.source_record_key,
                        title_line,
                        code_line,
                        notes_line,
                    ),
                )
            )

    return GeorgiaInspectionHistoryRecord(
        inspection=inspection,
        findings=findings,
        warnings=warnings,
    )


def parse_detail_history_results(
    raw_text: str,
    *,
    source_url: str,
    county_name: str | None = None,
    fallback_restaurant: dict[str, Any] | None = None,
) -> GeorgiaDetailHistoryParseResult:
    json_result = _parse_inspection_json_history(
        raw_text,
        source_url=source_url,
        county_name=county_name,
        fallback_restaurant=fallback_restaurant,
    )
    if json_result is not None:
        return json_result

    record = _parse_html_detail_record(
        raw_text,
        source_url=source_url,
        county_name=county_name,
        fallback_restaurant=fallback_restaurant,
    )
    return GeorgiaDetailHistoryParseResult(
        inspections=[record],
        warnings=record.warnings,
    )


def parse_detail_results(
    html: str,
    *,
    source_url: str,
    county_name: str | None = None,
    fallback_restaurant: dict[str, Any] | None = None,
) -> GeorgiaDetailParseResult:
    history = parse_detail_history_results(
        html,
        source_url=source_url,
        county_name=county_name,
        fallback_restaurant=fallback_restaurant,
    )
    if not history.inspections:
        return GeorgiaDetailParseResult(inspection=None, findings=[], warnings=history.warnings)
    latest = history.inspections[0]
    return GeorgiaDetailParseResult(
        inspection=latest.inspection,
        findings=[finding for record in history.inspections for finding in record.findings],
        warnings=history.warnings + latest.warnings,
    )


def _parse_inspection_json_history(
    raw_text: str,
    *,
    source_url: str,
    county_name: str | None,
    fallback_restaurant: dict[str, Any] | None,
 ) -> GeorgiaDetailHistoryParseResult | None:
    try:
        payload = json.loads(raw_text)
    except json.JSONDecodeError:
        return None

    rows: list[dict[str, Any]] | None = None
    if isinstance(payload, list):
        rows = [item for item in payload if isinstance(item, dict)]
    elif isinstance(payload, dict):
        for key in ("data", "inspections", "items", "results"):
            value = payload.get(key)
            if isinstance(value, list):
                rows = [item for item in value if isinstance(item, dict)]
                break
    if rows is None:
        return None

    restaurant_name = (fallback_restaurant or {}).get("restaurant_name_raw")
    permit_number = (fallback_restaurant or {}).get("license_number_raw")
    address = (fallback_restaurant or {}).get("address_raw")
    city = (fallback_restaurant or {}).get("city_raw")
    state = (fallback_restaurant or {}).get("state_raw") or "GA"
    zip_code = (fallback_restaurant or {}).get("zip_code_raw")

    records: list[GeorgiaInspectionHistoryRecord] = []
    warnings: list[str] = []

    for row in rows:
        columns = row.get("columns") if isinstance(row.get("columns"), dict) else {}
        inspection_date = _clean_text(
            row.get("date")
            or row.get("inspectionDate")
            or row.get("lastInspectionDate")
            or _extract_column_value(columns, "0", "Date:")
        )
        inspection_type = _clean_text(
            row.get("inspectionPurpose")
            or row.get("purpose")
            or row.get("inspectionType")
            or _extract_column_value(columns, "1", "Inspection Purpose:")
        )
        inspection_score = _clean_text(
            row.get("score")
            or _extract_column_value(columns, "2", "Score:")
        )
        inspector_name = _clean_text(
            row.get("inspector")
            or row.get("inspectorName")
            or _extract_column_value(columns, "3", "Inspector:")
        )
        report_url = _clean_text(
            row.get("inspectionReportUrl")
            or row.get("reportUrl")
            or row.get("report")
            or row.get("printablePath")
        )
        if report_url and not report_url.startswith("http"):
            parsed_source = urlparse(source_url)
            report_url = urljoin(f"{parsed_source.scheme}://{parsed_source.netloc}/", report_url)

        inspection_id = _clean_text(row.get("inspectionId"))
        detail_key = _build_source_record_key(
            inspection_id,
            county_name,
            permit_number,
            inspection_date,
            inspection_type,
            report_url,
            source_url,
        )
        inspection = GeorgiaInspectionDetail(
            county_name=county_name,
            restaurant_name_raw=restaurant_name,
            license_number_raw=permit_number,
            address_raw=address,
            city_raw=city,
            state_raw=state,
            zip_code_raw=zip_code,
            inspection_date_raw=inspection_date,
            inspection_type_raw=inspection_type,
            inspection_score_raw=inspection_score,
            inspection_grade_raw=_parse_grade(inspection_score),
            inspector_name_raw=inspector_name,
            detail_url=source_url,
            report_url=report_url,
            source_record_key=detail_key,
        )

        violations = row.get("violations")
        record_findings: list[GeorgiaFinding] = []
        if isinstance(violations, dict):
            for violation_index, violation in violations.items():
                if not isinstance(violation, list):
                    continue

                title = _clean_text(violation[0] if len(violation) > 0 else None)
                code = _clean_text(violation[1] if len(violation) > 1 else None)
                points = _clean_text(
                    (violation[2] if len(violation) > 2 else None)
                )
                corrected = _clean_text(violation[3] if len(violation) > 3 else None)
                repeat = _clean_text(violation[4] if len(violation) > 4 else None)
                notes = _clean_text(violation[5] if len(violation) > 5 else None)

                if points and points.lower().startswith("points:"):
                    points = _clean_text(points.split(":", 1)[1])
                if corrected and ":" in corrected:
                    corrected = _clean_text(corrected.split(":", 1)[1])
                if repeat and ":" in repeat:
                    repeat = _clean_text(repeat.split(":", 1)[1])
                if notes and ":" in notes:
                    notes = _clean_text(notes.split(":", 1)[1])

                corrected_bool = _parse_bool(corrected)
                repeat_bool = _parse_bool(repeat)

                record_findings.append(
                    GeorgiaFinding(
                        violation_code_raw=code,
                        violation_category_raw=title,
                        points_deducted_raw=points,
                        corrected_during_inspection=corrected_bool,
                        is_repeat_violation=repeat_bool,
                        official_text=title or "Unknown finding",
                        official_detail_text=notes,
                        official_detail_json={
                            key: value
                            for key, value in {
                                "points_deducted": points,
                                "corrected_during_inspection": corrected_bool,
                                "is_repeat_violation": repeat_bool,
                                "inspection_id": inspection_id,
                                "violation_index": violation_index,
                            }.items()
                            if value is not None
                        }
                        or None,
                        auditor_comments=notes,
                        source_record_key=_build_source_record_key(
                            inspection.source_record_key,
                            violation_index,
                            code,
                            title,
                        ),
                    )
                )

        records.append(
            GeorgiaInspectionHistoryRecord(
                inspection=inspection,
                findings=record_findings,
                warnings=[],
            )
        )

    if not records:
        warnings.append("no_inspection_rows_parsed")

    return GeorgiaDetailHistoryParseResult(
        inspections=records,
        warnings=warnings,
    )
