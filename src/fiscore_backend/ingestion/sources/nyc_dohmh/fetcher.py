from __future__ import annotations

from dataclasses import dataclass
import json
from urllib.parse import urlencode

import httpx

from fiscore_backend.ingestion.sources.nyc_dohmh.request_builder import NYCDOHMHRunPlan


@dataclass(frozen=True)
class JsonArtifact:
    source_url: str
    filename: str
    content: str
    content_type: str
    partition_key: str | None = None
    page_number: int | None = None


def _where_clause(run_plan: NYCDOHMHRunPlan, borough: str | None) -> str | None:
    clauses: list[str] = []
    if borough:
        escaped_borough = borough.replace("'", "''")
        clauses.append(f"boro = '{escaped_borough}'")
    if run_plan.date_from is not None and run_plan.date_to is not None:
        clauses.append(
            "inspection_date between "
            f"'{run_plan.date_from.isoformat()}' and '{run_plan.date_to.isoformat()}'"
        )
    if not clauses:
        return None
    return " and ".join(clauses)


class NYCDOHMHFetcher:
    def __init__(self) -> None:
        self.client = httpx.Client(timeout=30.0, follow_redirects=True)

    def fetch_metadata(self, run_plan: NYCDOHMHRunPlan) -> JsonArtifact:
        response = self.client.get(str(run_plan.request_context["metadata_url"]))
        response.raise_for_status()
        return JsonArtifact(
            source_url=str(response.url),
            filename="metadata.json",
            content=response.text,
            content_type=response.headers.get("content-type", "application/json"),
        )

    def fetch_columns(self, run_plan: NYCDOHMHRunPlan) -> JsonArtifact:
        response = self.client.get(str(run_plan.request_context["columns_url"]))
        response.raise_for_status()
        return JsonArtifact(
            source_url=str(response.url),
            filename="columns.json",
            content=response.text,
            content_type=response.headers.get("content-type", "application/json"),
        )

    def fetch_row_pages(self, run_plan: NYCDOHMHRunPlan) -> list[JsonArtifact]:
        artifacts: list[JsonArtifact] = []
        page_size = int(run_plan.request_context.get("page_size") or 5000)
        resource_url = str(run_plan.request_context["resource_url"])
        boroughs = run_plan.borough_partitions if run_plan.borough_partitions else (None,)

        for borough in boroughs:
            offset = 0
            page_number = 1
            while True:
                params = {
                    "$limit": str(page_size),
                    "$offset": str(offset),
                    "$order": "camis,inspection_date,inspection_type,violation_code",
                }
                where_clause = _where_clause(run_plan, borough)
                if where_clause:
                    params["$where"] = where_clause

                response = self.client.get(resource_url, params=params)
                response.raise_for_status()
                payload = response.json()
                if not isinstance(payload, list) or not payload:
                    break

                partition_label = (borough or "all").lower().replace(" ", "_")
                artifacts.append(
                    JsonArtifact(
                        source_url=f"{resource_url}?{urlencode(params)}",
                        filename=f"rows_{partition_label}_page_{page_number:03d}.json",
                        content=json.dumps(payload),
                        content_type=response.headers.get("content-type", "application/json"),
                        partition_key=borough,
                        page_number=page_number,
                    )
                )

                if len(payload) < page_size:
                    break
                offset += page_size
                page_number += 1

        return artifacts
