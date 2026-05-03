from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
from typing import Any


def _clean_text(value: Any) -> str | None:
    if value is None:
        return None
    cleaned = " ".join(str(value).split())
    return cleaned or None


def _hash_parts(*values: str | None) -> str:
    joined = "|".join(value or "" for value in values)
    return sha256(joined.encode("utf-8")).hexdigest()


@dataclass(frozen=True)
class NYCGroupedInspectionCandidate:
    camis_raw: str
    dba_raw: str | None
    boro_raw: str | None
    building_raw: str | None
    street_raw: str | None
    zipcode_raw: str | None
    phone_raw: str | None
    cuisine_description_raw: str | None
    inspection_date_raw: str | None
    inspection_type_raw: str | None
    action_raw: str | None
    score_raw: str | None
    grade_raw: str | None
    grade_date_raw: str | None
    record_date_raw: str | None
    source_restaurant_key: str
    source_inspection_key: str
    findings: list[dict[str, Any]]

    def to_payload(self, *, source_url: str, dataset_id: str) -> dict[str, Any]:
        address_line1_raw = " ".join(
            part for part in [self.building_raw, self.street_raw] if part
        ) or None
        return {
            "source_metadata": {
                "dataset_id": dataset_id,
                "source_url": source_url,
            },
            "restaurant": {
                "camis_raw": self.camis_raw,
                "dba_raw": self.dba_raw,
                "boro_raw": self.boro_raw,
                "building_raw": self.building_raw,
                "street_raw": self.street_raw,
                "zipcode_raw": self.zipcode_raw,
                "phone_raw": self.phone_raw,
                "cuisine_description_raw": self.cuisine_description_raw,
                "address_line1_raw": address_line1_raw,
                "source_restaurant_key": self.source_restaurant_key,
            },
            "inspection": {
                "inspection_date_raw": self.inspection_date_raw,
                "inspection_type_raw": self.inspection_type_raw,
                "action_raw": self.action_raw,
                "score_raw": self.score_raw,
                "grade_raw": self.grade_raw,
                "grade_date_raw": self.grade_date_raw,
                "record_date_raw": self.record_date_raw,
                "source_inspection_key": self.source_inspection_key,
            },
            "findings": self.findings,
        }


@dataclass(frozen=True)
class NYCSearchParseResult:
    candidates: list[NYCGroupedInspectionCandidate]
    warnings: list[str]


def parse_search_results(
    raw_text: str,
    *,
    source_url: str,
    dataset_id: str,
) -> NYCSearchParseResult:
    try:
        rows = json.loads(raw_text)
    except json.JSONDecodeError:
        return NYCSearchParseResult(candidates=[], warnings=["NYC row payload was not valid JSON."])

    if not isinstance(rows, list):
        return NYCSearchParseResult(candidates=[], warnings=["NYC row payload was not a JSON list."])

    warnings: list[str] = []
    grouped: dict[tuple[str, str | None, str | None, str | None, str | None, str | None], dict[str, Any]] = {}

    for row_number, row in enumerate(rows, start=1):
        if not isinstance(row, dict):
            warnings.append(f"Skipped non-dict row at position {row_number}.")
            continue

        camis = _clean_text(row.get("camis"))
        if not camis:
            warnings.append(f"Skipped row {row_number} because CAMIS was missing.")
            continue

        group_key = (
            camis,
            _clean_text(row.get("inspection_date")),
            _clean_text(row.get("inspection_type")),
            _clean_text(row.get("action")),
            _clean_text(row.get("score")),
            _clean_text(row.get("grade")),
        )
        group = grouped.setdefault(
            group_key,
            {
                "camis_raw": camis,
                "dba_raw": _clean_text(row.get("dba")),
                "boro_raw": _clean_text(row.get("boro")),
                "building_raw": _clean_text(row.get("building")),
                "street_raw": _clean_text(row.get("street")),
                "zipcode_raw": _clean_text(row.get("zipcode")),
                "phone_raw": _clean_text(row.get("phone")),
                "cuisine_description_raw": _clean_text(row.get("cuisine_description")),
                "inspection_date_raw": group_key[1],
                "inspection_type_raw": group_key[2],
                "action_raw": group_key[3],
                "score_raw": group_key[4],
                "grade_raw": group_key[5],
                "grade_date_raw": _clean_text(row.get("grade_date")),
                "record_date_raw": _clean_text(row.get("record_date")),
                "findings": [],
            },
        )

        violation_code = _clean_text(row.get("violation_code"))
        violation_description = _clean_text(row.get("violation_description"))
        critical_flag = _clean_text(row.get("critical_flag"))
        if violation_code or violation_description or critical_flag:
            source_inspection_key = _hash_parts(
                camis,
                group["inspection_date_raw"],
                group["inspection_type_raw"],
                group["action_raw"],
                group["score_raw"],
            )
            group["findings"].append(
                {
                    "violation_code_raw": violation_code,
                    "violation_description_raw": violation_description,
                    "critical_flag_raw": critical_flag,
                    "finding_order": len(group["findings"]) + 1,
                    "source_finding_key": _hash_parts(
                        source_inspection_key,
                        violation_code,
                        violation_description,
                        critical_flag,
                        str(len(group["findings"]) + 1),
                    ),
                }
            )

    candidates = [
        NYCGroupedInspectionCandidate(
            camis_raw=group["camis_raw"],
            dba_raw=group["dba_raw"],
            boro_raw=group["boro_raw"],
            building_raw=group["building_raw"],
            street_raw=group["street_raw"],
            zipcode_raw=group["zipcode_raw"],
            phone_raw=group["phone_raw"],
            cuisine_description_raw=group["cuisine_description_raw"],
            inspection_date_raw=group["inspection_date_raw"],
            inspection_type_raw=group["inspection_type_raw"],
            action_raw=group["action_raw"],
            score_raw=group["score_raw"],
            grade_raw=group["grade_raw"],
            grade_date_raw=group["grade_date_raw"],
            record_date_raw=group["record_date_raw"],
            source_restaurant_key=f"nyc-camis:{group['camis_raw']}",
            source_inspection_key=_hash_parts(
                group["camis_raw"],
                group["inspection_date_raw"],
                group["inspection_type_raw"],
                group["action_raw"],
                group["score_raw"],
            ),
            findings=group["findings"],
        )
        for group in grouped.values()
    ]

    return NYCSearchParseResult(candidates=candidates, warnings=warnings)
