from dataclasses import dataclass
from datetime import date
import json
import re
from urllib.parse import urljoin

import httpx
from typing import Iterator

from fiscore_backend.ingestion.sources.sword.request_builder import SwordRunPlan


@dataclass(frozen=True)
class FetchedArtifact:
    source_url: str
    filename: str
    content: str
    content_type: str
    should_parse_candidates: bool = True
    page_number: int | None = None
    partition_key: str | None = None


def _format_sword_date(value: date) -> str:
    return f"{value.strftime('%B')} {value.day}, {value.year}"


class SwordFetcher:
    search_page_size = 20

    def _license_value(self, source_restaurant_key: str) -> str:
        if "|" in source_restaurant_key:
            return source_restaurant_key.rsplit("|", 1)[-1]
        return source_restaurant_key

    def _build_search_params(
        self,
        run_plan: SwordRunPlan,
        *,
        page_number: int,
        city_name: str | None = None,
        source_restaurant_key: str | None = None,
    ) -> dict[str, str]:
        params: dict[str, str] = {
            "Address": "",
            "City": city_name or "",
            "License": self._license_value(source_restaurant_key) if source_restaurant_key else "",
            "Name": "",
            "page": str(page_number),
            "type": "sword",
            "total": str(self.search_page_size),
            "action": "get_locations",
        }

        county_value = run_plan.request_context.get("county_value")
        if county_value:
            params["County"] = str(county_value)

        if run_plan.date_from is not None:
            params["from_date"] = _format_sword_date(run_plan.date_from)
        if run_plan.date_to is not None:
            params["to_date"] = _format_sword_date(run_plan.date_to)
        if run_plan.request_context.get("show_partial"):
            params["partial"] = "on"

        return params

    def _build_inspection_params(
        self,
        run_plan: SwordRunPlan,
        *,
        location: dict[str, str],
    ) -> dict[str, str]:
        params: dict[str, str] = {
            "Address": location.get("Address", ""),
            "City": "",
            "License": location.get("License", ""),
            "Name": location.get("Name", ""),
            "page": "0",
            "type": "sword",
            "total": str(self.search_page_size),
            "action": "get_inspections",
        }

        county_value = run_plan.request_context.get("county_value")
        if county_value:
            params["County"] = str(county_value)

        if run_plan.date_from is not None:
            params["from_date"] = _format_sword_date(run_plan.date_from)
        if run_plan.date_to is not None:
            params["to_date"] = _format_sword_date(run_plan.date_to)
        if run_plan.request_context.get("show_partial"):
            params["partial"] = "on"

        return params

    def _partition_label(self, city_name: str | None) -> str:
        if not city_name:
            return "all"
        return re.sub(r"[^a-z0-9]+", "-", city_name.lower()).strip("-")

    def _count_results(self, payload: str) -> int:
        try:
            decoded = json.loads(payload)
        except json.JSONDecodeError:
            return 0

        if isinstance(decoded, list):
            return len(decoded)

        return 0

    def _decode_rows(self, payload: str) -> list[dict[str, str]]:
        try:
            decoded = json.loads(payload)
        except json.JSONDecodeError:
            return []
        if not isinstance(decoded, list):
            return []
        return [item for item in decoded if isinstance(item, dict)]

    def _enrich_inspection_rows(
        self,
        *,
        location: dict[str, str],
        inspections: list[dict[str, str]],
    ) -> str:
        county_value = location.get("County", "")
        enriched: list[dict[str, str]] = []
        for inspection in inspections:
            row = dict(inspection)
            row.setdefault("HeaderID", "")
            row.setdefault("IncidentDate", "")
            row.setdefault("IncidentType", "")
            row.setdefault("Score", "")
            row["County"] = county_value
            row["License"] = location.get("License", "")
            row["Name"] = location.get("Name", "")
            row["Address"] = location.get("Address", "")
            row["Address2"] = location.get("Address2", "")
            row["City"] = location.get("City", "")
            row["State"] = location.get("State", "")
            row["ZipCode"] = location.get("ZipCode", "")
            enriched.append(row)
        return json.dumps(enriched)

    def _headers(self, *, base_url: str) -> dict[str, str]:
        return {
            "Referer": str(base_url),
            "X-Requested-With": "XMLHttpRequest",
        }

    def _fetch_locations_page(
        self,
        *,
        ajax_url: str,
        base_url: str,
        run_plan: SwordRunPlan,
        page_number: int,
        city_name: str | None,
        source_restaurant_key: str | None,
    ) -> httpx.Response:
        response = httpx.get(
            ajax_url,
            params=self._build_search_params(
                run_plan,
                page_number=page_number,
                city_name=city_name,
                source_restaurant_key=source_restaurant_key,
            ),
            timeout=30.0,
            follow_redirects=True,
            headers=self._headers(base_url=base_url),
        )
        response.raise_for_status()
        return response

    def _fetch_inspections(
        self,
        *,
        ajax_url: str,
        base_url: str,
        run_plan: SwordRunPlan,
        location: dict[str, str],
    ) -> httpx.Response:
        response = httpx.get(
            ajax_url,
            params=self._build_inspection_params(run_plan, location=location),
            timeout=30.0,
            follow_redirects=True,
            headers=self._headers(base_url=base_url),
        )
        response.raise_for_status()
        return response

    def _iter_inspection_artifacts(
        self,
        *,
        ajax_url: str,
        base_url: str,
        run_plan: SwordRunPlan,
        locations: list[dict[str, str]],
        partition_key: str | None,
        partition_label: str,
    ) -> Iterator[FetchedArtifact]:
        for location_index, location in enumerate(locations, start=1):
            inspection_response = self._fetch_inspections(
                ajax_url=ajax_url,
                base_url=base_url,
                run_plan=run_plan,
                location=location,
            )
            inspection_rows = self._decode_rows(inspection_response.text)
            if not inspection_rows:
                continue

            yield FetchedArtifact(
                source_url=str(inspection_response.url),
                filename=f"inspections_{partition_label}_{location_index:03d}.json",
                content=self._enrich_inspection_rows(location=location, inspections=inspection_rows),
                content_type=inspection_response.headers.get("content-type", "application/json"),
                should_parse_candidates=True,
                page_number=location_index,
                partition_key=partition_key,
            )

    def fetch_search_results(self, run_plan: SwordRunPlan) -> Iterator[FetchedArtifact]:
        ajax_url = urljoin(run_plan.request_context["base_url"], "/wp-admin/admin-ajax.php")
        base_url = str(run_plan.request_context["base_url"])
        target_source_restaurant_keys = run_plan.target_source_restaurant_keys or (None,)
        city_partitions = run_plan.city_partitions or (None,)

        if run_plan.target_source_restaurant_keys:
            for source_restaurant_key in target_source_restaurant_keys:
                response = self._fetch_locations_page(
                    ajax_url=ajax_url,
                    base_url=base_url,
                    run_plan=run_plan,
                    page_number=0,
                    city_name=None,
                    source_restaurant_key=source_restaurant_key,
                )
                locations = self._decode_rows(response.text)
                license_value = self._license_value(source_restaurant_key).lower()
                yield FetchedArtifact(
                    source_url=str(response.url),
                    filename=f"search_results_all-{license_value}_page_001.json",
                    content=response.text,
                    content_type=response.headers.get("content-type", "application/json"),
                    should_parse_candidates=False,
                    page_number=1,
                    partition_key=source_restaurant_key,
                )
                yield from self._iter_inspection_artifacts(
                    ajax_url=ajax_url,
                    base_url=base_url,
                    run_plan=run_plan,
                    locations=locations,
                    partition_key=source_restaurant_key,
                    partition_label=f"all-{license_value}",
                )
            return

        for source_restaurant_key in target_source_restaurant_keys:
            for city_name in city_partitions:
                page_value = 0
                page_number = 1
                partition_label = self._partition_label(city_name)
                if source_restaurant_key:
                    partition_label = f"{partition_label}-{self._license_value(source_restaurant_key).lower()}"

                while True:
                    response = self._fetch_locations_page(
                        ajax_url=ajax_url,
                        base_url=base_url,
                        run_plan=run_plan,
                        page_number=page_value,
                        city_name=city_name,
                        source_restaurant_key=source_restaurant_key,
                    )
                    result_count = self._count_results(response.text)
                    if result_count == 0:
                        break

                    yield FetchedArtifact(
                        source_url=str(response.url),
                        filename=f"search_results_{partition_label}_page_{page_number:03d}.json",
                        content=response.text,
                        content_type=response.headers.get("content-type", "application/json"),
                        should_parse_candidates=True,
                        page_number=page_number,
                        partition_key=source_restaurant_key or city_name,
                    )

                    if result_count < self.search_page_size:
                        break

                    page_value += 1
                    page_number += 1

    def fetch_detail_results(self, *, base_url: str, header_id: str) -> FetchedArtifact:
        ajax_url = urljoin(base_url, "/wp-admin/admin-ajax.php")
        response = httpx.get(
            ajax_url,
            params={
                "action": "get_details",
                "header_id": header_id,
            },
            timeout=30.0,
            follow_redirects=True,
            headers={
                "Referer": str(base_url),
                "X-Requested-With": "XMLHttpRequest",
            },
        )
        response.raise_for_status()

        return FetchedArtifact(
            source_url=str(response.url),
            filename=f"detail_{header_id}.json",
            content=response.text,
            content_type=response.headers.get("content-type", "application/json"),
        )
