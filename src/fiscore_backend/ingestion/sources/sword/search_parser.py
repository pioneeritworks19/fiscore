from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
import re
from typing import Any
from urllib.parse import urljoin

from bs4 import BeautifulSoup


@dataclass(frozen=True)
class SwordSearchCandidate:
    row_number: int
    header_id: str | None
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
    detail_url: str | None
    source_record_key: str

    def to_payload(self, *, county_name: str, source_url: str) -> dict[str, Any]:
        return {
            "county_name": county_name,
            "source_url": source_url,
            "row_number": self.row_number,
            "header_id": self.header_id,
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
            },
            "detail_url": self.detail_url,
        }


@dataclass(frozen=True)
class SwordSearchParseResult:
    candidates: list[SwordSearchCandidate]
    warnings: list[str]


def _clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = " ".join(value.split())
    return cleaned or None


def _build_source_record_key(*values: str | None) -> str:
    joined = "|".join(value or "" for value in values)
    return sha256(joined.encode("utf-8")).hexdigest()


def _parse_json_layout(raw_text: str, *, source_url: str, county_name: str) -> list[SwordSearchCandidate]:
    try:
        payload = json.loads(raw_text)
    except json.JSONDecodeError:
        return []

    if not isinstance(payload, list):
        return []

    candidates: list[SwordSearchCandidate] = []
    for row_number, item in enumerate(payload, start=1):
        if not isinstance(item, dict):
            continue

        restaurant_name = _clean_text(item.get("Name"))
        license_number = _clean_text(item.get("License"))
        address = _clean_text(item.get("Address"))
        address2 = _clean_text(item.get("Address2"))
        full_address = " ".join(part for part in [address, address2] if part)
        city = _clean_text(item.get("City"))
        state = _clean_text(item.get("State")) or "MI"
        zip_code = _clean_text(item.get("ZipCode"))
        inspection_date = _clean_text(item.get("IncidentDate"))
        inspection_type = _clean_text(item.get("IncidentType"))
        score = _clean_text(item.get("Score"))
        header_id = _clean_text(item.get("HeaderID"))
        county_value = _clean_text(item.get("County"))

        if not any((restaurant_name, license_number, full_address, inspection_date)):
            continue

        detail_url = source_url
        if header_id:
            detail_url = f"{source_url}#header-{header_id}"

            candidates.append(
                SwordSearchCandidate(
                    row_number=row_number,
                    header_id=header_id,
                    restaurant_name_raw=restaurant_name,
                    license_number_raw=license_number,
                    address_raw=full_address or None,
                    city_raw=city,
                    state_raw=state,
                    zip_code_raw=zip_code,
                    inspection_date_raw=inspection_date,
                    inspection_type_raw=inspection_type,
                    inspection_score_raw=score,
                    inspection_grade_raw=None,
                    detail_url=detail_url,
                    source_record_key=_build_source_record_key(
                        county_name,
                        restaurant_name,
                        license_number,
                        full_address or None,
                        inspection_date,
                        inspection_type,
                        county_value,
                        header_id,
                    ),
                )
            )

    return candidates


def _parse_card_layout(soup: BeautifulSoup, *, source_url: str, county_name: str) -> list[SwordSearchCandidate]:
    candidates: list[SwordSearchCandidate] = []
    text = soup.get_text("\n", strip=True)
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    row_number = 0
    current_restaurant_name: str | None = None
    current_address: str | None = None
    current_city: str | None = None
    current_state: str | None = "MI"
    current_license: str | None = None
    current_county: str | None = None

    for index, line in enumerate(lines):
        upper_line = line.upper()
        if line and line == upper_line and "SWORD SOLUTIONS" not in upper_line and "NEXT PAGE" not in upper_line:
            current_restaurant_name = line
            current_address = lines[index + 1] if index + 1 < len(lines) else None
            city_state_zip = lines[index + 2] if index + 2 < len(lines) else None
            if city_state_zip and "," in city_state_zip:
                current_city = city_state_zip.split(",")[0].strip()
            continue

        if line == "License #" and index + 1 < len(lines):
            current_license = lines[index + 1]
            continue

        if line == "County" and index + 1 < len(lines):
            current_county = lines[index + 1]
            continue

        if line.startswith("Inspection Date "):
            row_number += 1
            inspection_date = line.replace("Inspection Date ", "", 1).strip()
            inspection_type_raw = None
            if index + 1 < len(lines) and lines[index + 1].startswith("Inspection Type "):
                inspection_type_raw = lines[index + 1].replace("Inspection Type ", "", 1).strip()
            elif "Inspection Type " in line:
                match = re.search(r"Inspection Type (.+)$", line)
                if match:
                    inspection_type_raw = match.group(1).strip()

            candidates.append(
                SwordSearchCandidate(
                    row_number=row_number,
                    header_id=None,
                    restaurant_name_raw=current_restaurant_name,
                    license_number_raw=current_license,
                    address_raw=current_address,
                    city_raw=current_city,
                    state_raw=current_state,
                    zip_code_raw=None,
                    inspection_date_raw=inspection_date,
                    inspection_type_raw=inspection_type_raw,
                    inspection_score_raw=None,
                    inspection_grade_raw=None,
                    detail_url=source_url,
                    source_record_key=_build_source_record_key(
                        county_name,
                        current_restaurant_name,
                        current_license,
                        current_address,
                        inspection_date,
                        inspection_type_raw,
                        current_county,
                    ),
                )
            )

    return candidates


def parse_search_results(html: str, *, source_url: str, county_name: str) -> SwordSearchParseResult:
    json_candidates = _parse_json_layout(html, source_url=source_url, county_name=county_name)
    if json_candidates:
        return SwordSearchParseResult(candidates=json_candidates, warnings=[])

    soup = BeautifulSoup(html, "html.parser")
    warnings: list[str] = []
    candidates: list[SwordSearchCandidate] = []

    card_candidates = _parse_card_layout(soup, source_url=source_url, county_name=county_name)
    if card_candidates:
        return SwordSearchParseResult(candidates=card_candidates, warnings=warnings)

    tables = soup.find_all("table")
    if not tables:
        return SwordSearchParseResult(
            candidates=[],
            warnings=["no_table_elements_found_in_search_results"],
        )

    for table in tables:
        rows = table.find_all("tr")
        if len(rows) < 2:
            continue

        headers = [_clean_text(cell.get_text(" ", strip=True)) for cell in rows[0].find_all(["th", "td"])]
        normalized_headers = [header.lower() if header else "" for header in headers]

        if not any(
            keyword in " ".join(normalized_headers)
            for keyword in ("restaurant", "license", "inspection", "address")
        ):
            continue

        for row_index, row in enumerate(rows[1:], start=1):
            cells = row.find_all("td")
            if not cells:
                continue

            texts = [_clean_text(cell.get_text(" ", strip=True)) for cell in cells]
            link = row.find("a", href=True)
            detail_url = urljoin(source_url, link["href"]) if link else None

            restaurant_name = texts[0] if len(texts) > 0 else None
            license_number = texts[1] if len(texts) > 1 else None
            address = texts[2] if len(texts) > 2 else None
            city = texts[3] if len(texts) > 3 else None
            state = texts[4] if len(texts) > 4 else "MI"
            inspection_date = texts[5] if len(texts) > 5 else None
            inspection_type = texts[6] if len(texts) > 6 else None
            inspection_score = texts[7] if len(texts) > 7 else None
            inspection_grade = texts[8] if len(texts) > 8 else None

            if not any((restaurant_name, license_number, address, inspection_date)):
                continue

            candidates.append(
                SwordSearchCandidate(
                    row_number=row_index,
                    restaurant_name_raw=restaurant_name,
                    license_number_raw=license_number,
                    address_raw=address,
                    city_raw=city,
                    state_raw=state,
                    zip_code_raw=None,
                    inspection_date_raw=inspection_date,
                    inspection_type_raw=inspection_type,
                    inspection_score_raw=inspection_score,
                    inspection_grade_raw=inspection_grade,
                    detail_url=detail_url,
                    source_record_key=_build_source_record_key(
                        county_name,
                        restaurant_name,
                        license_number,
                        address,
                        inspection_date,
                    ),
                )
            )

        break

    if not candidates:
        warnings.append("no_search_candidates_parsed")

    return SwordSearchParseResult(candidates=candidates, warnings=warnings)
