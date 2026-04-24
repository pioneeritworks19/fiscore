from dataclasses import dataclass
from datetime import date
import json
from urllib.parse import urljoin

import httpx

from fiscore_backend.ingestion.sources.sword.request_builder import SwordRunPlan


@dataclass(frozen=True)
class FetchedArtifact:
    source_url: str
    filename: str
    content: str
    content_type: str
    page_number: int | None = None


def _format_sword_date(value: date) -> str:
    return f"{value.strftime('%B')} {value.day}, {value.year}"


class SwordFetcher:
    search_page_size = 20

    def _build_search_params(self, run_plan: SwordRunPlan, *, page_offset: int) -> dict[str, str]:
        params: dict[str, str] = {
            "Address": "",
            "City": "",
            "License": "",
            "Name": "",
            "page": str(page_offset),
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

    def _count_results(self, payload: str) -> int:
        try:
            decoded = json.loads(payload)
        except json.JSONDecodeError:
            return 0

        if isinstance(decoded, list):
            return len(decoded)

        return 0

    def fetch_search_results(self, run_plan: SwordRunPlan) -> list[FetchedArtifact]:
        ajax_url = urljoin(run_plan.request_context["base_url"], "/wp-admin/admin-ajax.php")
        artifacts: list[FetchedArtifact] = []
        page_offset = 0
        page_number = 1

        while True:
            response = httpx.get(
                ajax_url,
                params=self._build_search_params(run_plan, page_offset=page_offset),
                timeout=30.0,
                follow_redirects=True,
                headers={
                    "Referer": str(run_plan.request_context["base_url"]),
                    "X-Requested-With": "XMLHttpRequest",
                },
            )
            response.raise_for_status()

            result_count = self._count_results(response.text)
            if result_count == 0:
                break

            artifacts.append(
                FetchedArtifact(
                    source_url=str(response.url),
                    filename=f"search_results_page_{page_number:03d}.json",
                    content=response.text,
                    content_type=response.headers.get("content-type", "application/json"),
                    page_number=page_number,
                )
            )

            if result_count < self.search_page_size:
                break

            page_offset += self.search_page_size
            page_number += 1

        return artifacts

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
