import json
from pathlib import Path

from fiscore_backend.ingestion.sources.nyc_dohmh.search_parser import parse_search_results


FIXTURE_PATH = Path(__file__).parent / "fixtures" / "nyc_dohmh" / "sample_rows_page.json"


def test_parse_search_results_groups_rows_and_derives_keys() -> None:
    raw_text = FIXTURE_PATH.read_text(encoding="utf-8")

    result = parse_search_results(
        raw_text,
        source_url="https://data.cityofnewyork.us/resource/43nn-pn8j.json?$limit=3",
        dataset_id="43nn-pn8j",
    )

    assert result.warnings == []
    assert len(result.candidates) == 2

    first, second = result.candidates

    assert first.source_restaurant_key == "nyc-camis:12345678"
    assert first.source_inspection_key
    assert len(first.findings) == 2
    assert first.findings[0]["source_finding_key"] != first.findings[1]["source_finding_key"]

    payload = first.to_payload(
        source_url="https://data.cityofnewyork.us/resource/43nn-pn8j.json?$limit=3",
        dataset_id="43nn-pn8j",
    )
    assert payload["restaurant"]["address_line1_raw"] == "10 W 10 ST"
    assert payload["inspection"]["score_raw"] == "12"

    assert second.source_restaurant_key == "nyc-camis:98765432"
    assert second.inspection_date_raw == "1900-01-01"
    assert second.findings == []


def test_parse_search_results_warns_on_missing_camis() -> None:
    raw_text = json.dumps(
        [
            {
                "dba": "Missing CAMIS",
                "inspection_date": "2026-04-21",
                "violation_code": "10F",
            }
        ]
    )

    result = parse_search_results(
        raw_text,
        source_url="https://data.cityofnewyork.us/resource/43nn-pn8j.json?$limit=1",
        dataset_id="43nn-pn8j",
    )

    assert result.candidates == []
    assert result.warnings == ["Skipped row 1 because CAMIS was missing."]
