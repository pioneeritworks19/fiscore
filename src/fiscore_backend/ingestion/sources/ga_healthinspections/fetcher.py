from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from base64 import b64encode
import json
from typing import Any
from urllib.parse import quote, urljoin, urlparse

import httpx
from bs4 import BeautifulSoup

from fiscore_backend.ingestion.sources.ga_healthinspections.request_builder import GeorgiaRunPlan


@dataclass(frozen=True)
class SearchPartition:
    county_name: str | None
    county_value: str | None


@dataclass(frozen=True)
class SearchPageArtifact:
    source_url: str
    filename: str
    content: str
    content_type: str
    county_name: str | None
    page_number: int | None = None


@dataclass(frozen=True)
class BinaryArtifact:
    source_url: str
    filename: str
    content: bytes
    content_type: str


@dataclass(frozen=True)
class JsonArtifact:
    source_url: str
    filename: str
    content: str
    content_type: str
    county_name: str | None = None


@dataclass(frozen=True)
class SearchConfig:
    landing_url: str
    search_url: str
    county_field_name: str | None
    permit_type_field_name: str | None
    permit_type_value: str | None
    date_from_field_name: str | None
    date_to_field_name: str | None
    county_partitions: list[SearchPartition]


def _format_date(value: date | None) -> str | None:
    if value is None:
        return None
    return value.strftime("%m/%d/%Y")


def _format_api_date(value: date | None) -> str | None:
    if value is None:
        return None
    return value.isoformat()


def _clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = " ".join(value.split())
    return cleaned or None


def _encode_api_value(value: str | None) -> str:
    return b64encode((value or "").encode("utf-8")).decode("ascii")


def _find_select_near_text(soup: BeautifulSoup, text: str):
    needle = text.lower()
    for label in soup.find_all(["label", "td", "th", "span", "div"]):
        label_text = _clean_text(label.get_text(" ", strip=True))
        if not label_text or needle not in label_text.lower():
            continue
        if label.name == "label" and label.get("for"):
            control = soup.find(attrs={"id": label["for"]})
            if control is not None and control.name == "select":
                return control
        sibling = label.find_next("select")
        if sibling is not None:
            return sibling
    for select_tag in soup.find_all("select"):
        select_name = _clean_text(select_tag.get("name")) or ""
        select_id = _clean_text(select_tag.get("id")) or ""
        if needle in select_name.lower() or needle in select_id.lower():
            return select_tag
    return None


def _find_input_near_text(soup: BeautifulSoup, text: str):
    needle = text.lower()
    for label in soup.find_all(["label", "td", "th", "span", "div"]):
        label_text = _clean_text(label.get_text(" ", strip=True))
        if not label_text or needle not in label_text.lower():
            continue
        if label.name == "label" and label.get("for"):
            control = soup.find(attrs={"id": label["for"]})
            if control is not None and control.name == "input":
                return control
        sibling = label.find_next("input")
        if sibling is not None:
            return sibling
    return None


def _find_date_inputs(soup: BeautifulSoup) -> tuple[str | None, str | None]:
    date_inputs = [
        input_tag
        for input_tag in soup.find_all("input")
        if (input_tag.get("placeholder") or "").lower() == "mm/dd/yyyy"
    ]
    if len(date_inputs) >= 2:
        return date_inputs[0].get("name"), date_inputs[1].get("name")
    return None, None


def _extract_form_action(soup: BeautifulSoup, base_url: str) -> str:
    form = soup.find("form")
    fallback_path = _build_default_search_url(base_url)
    if form is None:
        return fallback_path
    action = (form.get("action") or "").strip()
    if not action:
        return fallback_path
    if action.startswith("http://") or action.startswith("https://"):
        return action
    if action.startswith("/"):
        return urljoin(base_url, action)
    if action.lower().endswith("georgia/search.cfm"):
        return _build_default_search_url(base_url)
    return urljoin(base_url, action)


def _build_default_search_url(base_url: str) -> str:
    parsed = urlparse(base_url)
    return f"{parsed.scheme}://{parsed.netloc}/georgia/search.cfm"


def _extract_select_options(select_tag) -> list[SearchPartition]:
    partitions: list[SearchPartition] = []
    for option in select_tag.find_all("option"):
        text = _clean_text(option.get_text(" ", strip=True))
        value = _clean_text(option.get("value"))
        if not text or "select" in text.lower():
            continue
        partitions.append(SearchPartition(county_name=text, county_value=value or text))
    return partitions


def _normalize_county_name(value: str | None) -> str | None:
    cleaned = _clean_text(value)
    if cleaned is None:
        return None
    return " ".join(cleaned.lower().replace("county", "").split()) or None


def _extract_food_service_value(select_tag) -> str | None:
    for option in select_tag.find_all("option"):
        text = _clean_text(option.get_text(" ", strip=True))
        if text and text.lower() == "food service":
            return _clean_text(option.get("value")) or text
    return None


class GeorgiaHealthInspectionsFetcher:
    def __init__(self) -> None:
        self.client = httpx.Client(timeout=30.0, follow_redirects=True)

    def fetch_landing_page(self, run_plan: GeorgiaRunPlan) -> tuple[SearchPageArtifact, SearchConfig]:
        response = self.client.get(str(run_plan.request_context["base_url"]))
        response.raise_for_status()

        soup = BeautifulSoup(response.text, "html.parser")
        county_select = _find_select_near_text(soup, "County")
        permit_select = _find_select_near_text(soup, "Permit Type")
        date_from_name, date_to_name = _find_date_inputs(soup)

        search_config = SearchConfig(
            landing_url=str(response.url),
            search_url=_extract_form_action(soup, str(response.url)),
            county_field_name=county_select.get("name") if county_select is not None else "county",
            permit_type_field_name=permit_select.get("name") if permit_select is not None else None,
            permit_type_value=_extract_food_service_value(permit_select) if permit_select is not None else "Food Service",
            date_from_field_name=date_from_name,
            date_to_field_name=date_to_name,
            county_partitions=_extract_select_options(county_select)
            if county_select is not None
            else [SearchPartition(county_name=None, county_value=None)],
        )
        return (
            SearchPageArtifact(
                source_url=str(response.url),
                filename="landing_page.html",
                content=response.text,
                content_type=response.headers.get("content-type", "text/html"),
                county_name=None,
            ),
            search_config,
        )

    def _build_search_params(
        self,
        search_config: SearchConfig,
        run_plan: GeorgiaRunPlan,
        partition: SearchPartition,
    ) -> dict[str, str]:
        params: dict[str, str] = {}
        if search_config.county_field_name and partition.county_value:
            params[search_config.county_field_name] = partition.county_value
        if search_config.permit_type_field_name and search_config.permit_type_value:
            params[search_config.permit_type_field_name] = search_config.permit_type_value

        formatted_from = _format_date(run_plan.date_from)
        formatted_to = _format_date(run_plan.date_to)
        if search_config.date_from_field_name and formatted_from:
            params[search_config.date_from_field_name] = formatted_from
        if search_config.date_to_field_name and formatted_to:
            params[search_config.date_to_field_name] = formatted_to
        return params

    def fetch_search_results(
        self,
        *,
        search_config: SearchConfig,
        run_plan: GeorgiaRunPlan,
    ) -> list[SearchPageArtifact]:
        artifacts: list[SearchPageArtifact] = []
        seen_urls: set[str] = set()

        for partition in search_config.county_partitions:
            response = self.client.get(
                search_config.search_url,
                params=self._build_search_params(search_config, run_plan, partition),
                headers={"Referer": search_config.landing_url},
            )
            response.raise_for_status()
            queue: list[tuple[str, str, int]] = [(str(response.url), response.text, 1)]

            while queue:
                page_url, page_html, page_number = queue.pop(0)
                if page_url in seen_urls:
                    continue
                seen_urls.add(page_url)

                artifacts.append(
                    SearchPageArtifact(
                        source_url=page_url,
                        filename=f"search_{partition.county_name or 'statewide'}_{page_number:03d}.html",
                        content=page_html,
                        content_type=response.headers.get("content-type", "text/html"),
                        county_name=partition.county_name,
                        page_number=page_number,
                    )
                )

                soup = BeautifulSoup(page_html, "html.parser")
                next_link = next(
                    (
                        urljoin(page_url, link["href"])
                        for link in soup.find_all("a", href=True)
                        if "next" in (_clean_text(link.get_text(" ", strip=True)) or "").lower()
                    ),
                    None,
                )
                if next_link and next_link not in seen_urls:
                    next_response = self.client.get(next_link, headers={"Referer": page_url})
                    next_response.raise_for_status()
                    queue.append((str(next_response.url), next_response.text, page_number + 1))

        return artifacts

    def fetch_search_api_results(
        self,
        *,
        landing_html: str,
        landing_url: str,
        search_config: SearchConfig,
        run_plan: GeorgiaRunPlan,
    ) -> list[JsonArtifact]:
        soup = BeautifulSoup(landing_html, "html.parser")
        permit_select = _find_select_near_text(soup, "Permit Type")
        permit_type_value = _extract_food_service_value(permit_select) if permit_select is not None else None

        artifacts: list[JsonArtifact] = []
        partitions = self._resolve_target_partitions(
            search_config=search_config,
            county_name=run_plan.request_context.get("county_name"),
        )
        for partition in partitions:
            artifacts.append(
                self.fetch_search_api_partition_result(
                    landing_url=landing_url,
                    search_config=search_config,
                    partition=partition,
                    date_from=run_plan.date_from,
                    date_to=run_plan.date_to,
                    permit_type_value=permit_type_value or "Food Service",
                )
            )
        return artifacts

    def _resolve_target_partitions(
        self,
        *,
        search_config: SearchConfig,
        county_name: str | None,
    ) -> list[SearchPartition]:
        partitions = search_config.county_partitions or [SearchPartition(county_name="Georgia", county_value=None)]
        normalized_target = _normalize_county_name(county_name)
        if not normalized_target:
            return partitions
        matched = [
            partition
            for partition in partitions
            if _normalize_county_name(partition.county_name) == normalized_target
        ]
        return matched or [SearchPartition(county_name=county_name, county_value=county_name)]

    def fetch_search_api_partition_result(
        self,
        *,
        landing_url: str,
        search_config: SearchConfig,
        partition: SearchPartition,
        date_from: date | None,
        date_to: date | None,
        permit_type_value: str,
    ) -> JsonArtifact:
        payload: dict[str, Any] = {
            "permitType": _encode_api_value(permit_type_value),
            "from": _encode_api_value(_format_api_date(date_from)),
            "to": _encode_api_value(_format_api_date(date_to)),
            "keyword": _encode_api_value(""),
        }
        if partition.county_value:
            payload[search_config.county_field_name or "county"] = _encode_api_value(
                partition.county_value
            )

        encoded_payload = quote(json.dumps(payload, separators=(",", ":")))
        api_url = urljoin(
            landing_url,
            f"/stateofgeorgia/API/index.cfm/search/{encoded_payload}/0",
        )
        response = self.client.get(
            api_url,
            headers={
                "Accept": "application/json, text/javascript, */*; q=0.01",
                "Referer": landing_url,
                "X-Requested-With": "XMLHttpRequest",
            },
        )
        response.raise_for_status()
        filename_suffix = (partition.county_name or "statewide").lower().replace(" ", "_")
        return JsonArtifact(
            source_url=str(response.url),
            filename=f"search_results_{filename_suffix}.json",
            content=response.text,
            content_type=response.headers.get("content-type", "application/json"),
            county_name=partition.county_name,
        )

    def fetch_detail_page(self, detail_url: str) -> SearchPageArtifact:
        response = self.client.get(detail_url)
        response.raise_for_status()
        slug = detail_url.rstrip("/").split("/")[-1] or "detail"
        return SearchPageArtifact(
            source_url=str(response.url),
            filename=f"{slug}.html",
            content=response.text,
            content_type=response.headers.get("content-type", "text/html"),
            county_name=None,
        )

    def fetch_report_artifact(self, report_url: str, *, filename_stem: str = "inspection_report") -> BinaryArtifact:
        response = self.client.get(report_url)
        response.raise_for_status()
        content_type = response.headers.get("content-type", "application/octet-stream")
        extension = "pdf" if "pdf" in content_type.lower() else "html"
        return BinaryArtifact(
            source_url=str(response.url),
            filename=f"{filename_stem}.{extension}",
            content=response.content,
            content_type=content_type,
        )

    def fetch_inspections_json(self, facility_token: str) -> JsonArtifact:
        api_url = urljoin(
            "https://ga.healthinspections.us/stateofgeorgia/",
            f"API/index.cfm/inspectionsData/{facility_token}",
        )
        response = self.client.get(
            api_url,
            headers={
                "Accept": "application/json, text/javascript, */*; q=0.01",
                "X-Requested-With": "XMLHttpRequest",
                "Referer": "https://ga.healthinspections.us/stateofgeorgia/#facility",
            },
        )
        response.raise_for_status()
        try:
            parsed = response.json()
            content = json.dumps(parsed)
        except json.JSONDecodeError:
            content = response.text
        return JsonArtifact(
            source_url=str(response.url),
            filename=f"inspections_{facility_token}.json",
            content=content,
            content_type=response.headers.get("content-type", "application/json"),
        )
