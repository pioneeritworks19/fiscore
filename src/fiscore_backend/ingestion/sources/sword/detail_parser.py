from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
from typing import Any


@dataclass(frozen=True)
class SwordDetailFinding:
    detail_id: str | None
    header_id: str | None
    violation_code_raw: str | None
    violation_category_raw: str | None
    violation_items_raw: str | None
    violation_problem_raw: str | None
    violation_correction_raw: str | None
    violation_comments_raw: str | None
    official_text: str
    official_detail_text: str | None
    official_detail_json: dict[str, Any] | None
    auditor_comments: str | None
    source_record_key: str

    def to_payload(self, *, source_url: str) -> dict[str, Any]:
        return {
            "source_url": source_url,
            "detail_id": self.detail_id,
            "header_id": self.header_id,
            "violation_code_raw": self.violation_code_raw,
            "violation_category_raw": self.violation_category_raw,
            "violation_items_raw": self.violation_items_raw,
            "violation_problem_raw": self.violation_problem_raw,
            "violation_correction_raw": self.violation_correction_raw,
            "violation_comments_raw": self.violation_comments_raw,
            "official_text": self.official_text,
            "official_detail_text": self.official_detail_text,
            "official_detail_json": self.official_detail_json,
            "auditor_comments": self.auditor_comments,
        }


@dataclass(frozen=True)
class SwordDetailParseResult:
    findings: list[SwordDetailFinding]
    warnings: list[str]


def _clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = " ".join(value.split())
    return cleaned or None


def _build_source_record_key(*values: str | None) -> str:
    joined = "|".join(value or "" for value in values)
    return sha256(joined.encode("utf-8")).hexdigest()


def _build_official_text(*parts: tuple[str, str | None]) -> str:
    rendered: list[str] = []
    for label, value in parts:
        cleaned = _clean_text(value)
        if cleaned:
            rendered.append(f"{label}: {cleaned}")
    return "\n".join(rendered)


def _build_official_summary(
    *,
    category: str | None,
    violation_code: str | None,
    items: str | None,
) -> str:
    summary_parts: list[str] = []
    cleaned_category = _clean_text(category)
    cleaned_code = _clean_text(violation_code)
    cleaned_items = _clean_text(items)

    if cleaned_category:
        summary_parts.append(cleaned_category)
    elif cleaned_items:
        summary_parts.append(cleaned_items)

    if cleaned_code:
        if summary_parts:
            summary_parts[-1] = f"{summary_parts[-1]} ({cleaned_code})"
        else:
            summary_parts.append(cleaned_code)

    if not summary_parts and cleaned_items:
        summary_parts.append(cleaned_items)

    return " - ".join(summary_parts) or "Unknown finding"


def _build_official_detail_json(
    *,
    items: str | None,
    problems: str | None,
    corrections: str | None,
) -> dict[str, str] | None:
    detail: dict[str, str] = {}
    if items:
        detail["items"] = items
    if problems:
        detail["problems"] = problems
    if corrections:
        detail["corrections"] = corrections
    return detail or None


def parse_detail_results(raw_text: str, *, source_url: str) -> SwordDetailParseResult:
    try:
        payload = json.loads(raw_text)
    except json.JSONDecodeError:
        return SwordDetailParseResult(findings=[], warnings=["detail_json_decode_failed"])

    if not isinstance(payload, list):
        return SwordDetailParseResult(findings=[], warnings=["detail_payload_not_list"])

    findings: list[SwordDetailFinding] = []
    for item in payload:
        if not isinstance(item, dict):
            continue

        detail_id = _clean_text(item.get("DetailID"))
        header_id = _clean_text(item.get("HeaderID"))
        violation_code = _clean_text(item.get("Violation"))
        category = _clean_text(item.get("ViolationCategory"))
        items = _clean_text(item.get("Items"))
        problems = _clean_text(item.get("Problems"))
        corrections = _clean_text(item.get("Corrections"))
        comments = _clean_text(item.get("Comments"))

        official_detail_text = _build_official_text(
            ("Items", items),
            ("Problems", problems),
            ("Corrections", corrections),
        )
        official_text = _build_official_summary(
            category=category,
            violation_code=violation_code,
            items=items,
        )
        official_detail_json = _build_official_detail_json(
            items=items,
            problems=problems,
            corrections=corrections,
        )

        findings.append(
            SwordDetailFinding(
                detail_id=detail_id,
                header_id=header_id,
                violation_code_raw=violation_code,
                violation_category_raw=category,
                violation_items_raw=items,
                violation_problem_raw=problems,
                violation_correction_raw=corrections,
                violation_comments_raw=comments,
                official_text=official_text,
                official_detail_text=official_detail_text or None,
                official_detail_json=official_detail_json,
                auditor_comments=comments,
                source_record_key=_build_source_record_key(
                    header_id,
                    detail_id,
                    violation_code,
                    official_text,
                ),
            )
        )

    return SwordDetailParseResult(findings=findings, warnings=[])
