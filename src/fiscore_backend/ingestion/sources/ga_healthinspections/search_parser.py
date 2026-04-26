from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
import re
from typing import Any
from urllib.parse import parse_qs, urljoin, urlparse

from bs4 import BeautifulSoup


@dataclass(frozen=True)
class GeorgiaSearchCandidate:
    row_number: int
    county_name: str | None
    facility_token: str | None
    establishment_name_raw: str | None
    permit_number_raw: str | None
    address_raw: str | None
    city_raw: str | None
    state_raw: str | None
    zip_code_raw: str | None
    detail_url: str | None
    source_record_key: str

    def to_payload(self, *, source_url: str) -> dict[str, Any]:
        return {
            "county_name": self.county_name,
            "facility_token": self.facility_token,
            "source_url": source_url,
            "restaurant": {
                "restaurant_name_raw": self.establishment_name_raw,
                "license_number_raw": self.permit_number_raw,
                "address_raw": self.address_raw,
                "city_raw": self.city_raw,
                "state_raw": self.state_raw,
                "zip_code_raw": self.zip_code_raw,
            },
            "detail_url": self.detail_url,
        }


@dataclass(frozen=True)
class GeorgiaSearchParseResult:
    candidates: list[GeorgiaSearchCandidate]
    warnings: list[str]


def _clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = " ".join(value.split())
    return cleaned or None


def _build_source_record_key(*values: str | None) -> str:
    joined = "|".join(value or "" for value in values)
    return sha256(joined.encode("utf-8")).hexdigest()


def _county_from_url(source_url: str) -> str | None:
    parsed = urlparse(source_url)
    county = parse_qs(parsed.query).get("county")
    if not county:
        return None
    return _clean_text(county[0])


def _parse_city_state_zip(text: str | None) -> tuple[str | None, str | None, str | None]:
    cleaned = _clean_text(text)
    if cleaned is None:
        return None, None, None
    match = re.match(r"(.+?),\s*([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$", cleaned)
    if match:
        return match.group(1).strip(), match.group(2).strip(), match.group(3).strip()
    return cleaned, None, None


def _parse_map_address(value: str | None) -> tuple[str | None, str | None, str | None, str | None]:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None, None, None, None
    parts = [part.strip() for part in re.split(r"[\r\n]+", str(value)) if part.strip()]
    if len(parts) >= 2:
        city, state, zip_code = _parse_city_state_zip(parts[1])
        return _clean_text(parts[0]), city, state, zip_code
    return cleaned, None, None, None


def _looks_like_detail_link(href: str, text: str) -> bool:
    lowered_href = href.lower()
    lowered_text = text.lower()
    if "report_full" in lowered_href or "inspection report" in lowered_text:
        return False
    return any(
        token in lowered_href or token in lowered_text
        for token in ("details", "detail", "inspection", "view", "establishment")
    )


def _from_api_payload(
    raw_text: str,
    *,
    source_url: str,
    county_name: str | None = None,
) -> GeorgiaSearchParseResult | None:
    try:
        payload = json.loads(raw_text)
    except json.JSONDecodeError:
        return None

    rows: list[dict[str, Any]] | None = None
    if isinstance(payload, list):
        rows = [item for item in payload if isinstance(item, dict)]
    elif isinstance(payload, dict):
        for key in ("data", "results", "items", "facilities"):
            value = payload.get(key)
            if isinstance(value, list):
                rows = [item for item in value if isinstance(item, dict)]
                break
    if rows is None:
        return None

    candidates: list[GeorgiaSearchCandidate] = []
    for row_number, item in enumerate(rows, start=1):
        columns = item.get("columns") if isinstance(item.get("columns"), dict) else {}
        name = _clean_text(
            item.get("name")
            or item.get("facilityName")
            or item.get("establishmentName")
            or item.get("title")
        )
        permit_number = _clean_text(
            item.get("permitNumber")
            or item.get("permit_number")
            or item.get("permitNo")
            or item.get("permit")
            or (
                str(columns.get("3")).split(":", 1)[1].strip()
                if columns.get("3") and ":" in str(columns.get("3"))
                else None
            )
        )
        facility_token = _clean_text(
            item.get("id")
            or item.get("facilityId")
            or item.get("facilityToken")
            or item.get("encodedFacilityId")
            or item.get("facility")
        )
        parsed_address, parsed_city, parsed_state, parsed_zip = _parse_map_address(
            item.get("mapAddress") or item.get("address") or item.get("address1")
        )
        address = parsed_address
        city = _clean_text(item.get("city")) or parsed_city
        state = _clean_text(item.get("state")) or parsed_state or "GA"
        zip_code = _clean_text(item.get("zip") or item.get("zipCode")) or parsed_zip
        candidate_county_name = (
            _clean_text(item.get("county") or item.get("countyName"))
            or county_name
            or _county_from_url(source_url)
            or "Georgia"
        )

        if not any((name, permit_number, facility_token)):
            continue

        detail_url = "https://ga.healthinspections.us/stateofgeorgia/#facility"
        candidates.append(
            GeorgiaSearchCandidate(
                row_number=row_number,
                county_name=candidate_county_name,
                facility_token=facility_token,
                establishment_name_raw=name,
                permit_number_raw=permit_number,
                address_raw=address,
                city_raw=city,
                state_raw=state,
                zip_code_raw=zip_code,
                detail_url=detail_url,
                source_record_key=_build_source_record_key(
                    candidate_county_name,
                    facility_token,
                    name,
                    permit_number,
                    address,
                ),
            )
        )

    return GeorgiaSearchParseResult(
        candidates=candidates,
        warnings=[] if candidates else ["no_search_candidates_parsed"],
    )


def parse_search_results(html: str, *, source_url: str, county_name: str | None = None) -> GeorgiaSearchParseResult:
    api_result = _from_api_payload(html, source_url=source_url, county_name=county_name)
    if api_result is not None:
        if county_name:
            api_result = GeorgiaSearchParseResult(
                candidates=[
                    GeorgiaSearchCandidate(
                        row_number=candidate.row_number,
                        county_name=county_name,
                        facility_token=candidate.facility_token,
                        establishment_name_raw=candidate.establishment_name_raw,
                        permit_number_raw=candidate.permit_number_raw,
                        address_raw=candidate.address_raw,
                        city_raw=candidate.city_raw,
                        state_raw=candidate.state_raw,
                        zip_code_raw=candidate.zip_code_raw,
                        detail_url=candidate.detail_url,
                        source_record_key=candidate.source_record_key,
                    )
                    for candidate in api_result.candidates
                ],
                warnings=api_result.warnings,
            )
        return api_result

    soup = BeautifulSoup(html, "html.parser")
    county_name = _county_from_url(source_url)
    candidates: list[GeorgiaSearchCandidate] = []
    seen_urls: set[str] = set()

    for row_number, link in enumerate(soup.find_all("a", href=True), start=1):
        href = link.get("href", "").strip()
        text = _clean_text(link.get_text(" ", strip=True)) or ""
        if not href or not _looks_like_detail_link(href, text):
            continue

        detail_url = urljoin(source_url, href)
        if detail_url in seen_urls:
            continue
        seen_urls.add(detail_url)

        container = link.find_parent(["tr", "article", "section", "li", "div"]) or link
        lines = [
            _clean_text(line)
            for line in container.get_text("\n", strip=True).splitlines()
            if _clean_text(line)
        ]
        establishment_name = text or (lines[0] if lines else None)
        permit_number = next(
            (
                re.sub(r"^Permit\s*#?\s*:?\s*", "", line, flags=re.IGNORECASE)
                for line in lines
                if line and re.search(r"permit", line, re.IGNORECASE)
            ),
            None,
        )
        address = next(
            (
                line
                for line in lines
                if line
                and any(char.isdigit() for char in line)
                and not re.search(r"permit|score|date|inspection", line, re.IGNORECASE)
            ),
            None,
        )
        city, state, zip_code = _parse_city_state_zip(
            next(
                (
                    line
                    for line in lines
                    if line and re.search(r",[ ]*[A-Z]{2}[ ]+\d{5}", line)
                ),
                None,
            )
        )

        candidates.append(
            GeorgiaSearchCandidate(
                row_number=row_number,
                county_name=county_name,
                facility_token=None,
                establishment_name_raw=establishment_name,
                permit_number_raw=_clean_text(permit_number),
                address_raw=_clean_text(address),
                city_raw=city,
                state_raw=state or "GA",
                zip_code_raw=zip_code,
                detail_url=detail_url,
                source_record_key=_build_source_record_key(
                    county_name,
                    establishment_name,
                    permit_number,
                    address,
                    detail_url,
                ),
            )
        )

    warnings: list[str] = []
    if not candidates:
        warnings.append("no_search_candidates_parsed")

    return GeorgiaSearchParseResult(candidates=candidates, warnings=warnings)
