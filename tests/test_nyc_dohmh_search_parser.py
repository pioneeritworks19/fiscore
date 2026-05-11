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


def test_parse_search_results_normalizes_socrata_datetime_strings() -> None:
    raw_text = json.dumps(
        [
            {
                "camis": "12345678",
                "dba": "Sample Pizza",
                "boro": "Manhattan",
                "building": "10",
                "street": "W 10 ST",
                "zipcode": "10011",
                "inspection_date": "2026-04-20T00:00:00.000",
                "inspection_type": "Cycle Inspection / Initial Inspection",
                "action": "Violations were cited in the following area(s).",
                "score": "12",
                "grade": "A",
                "grade_date": "2026-04-20T00:00:00.000",
                "record_date": "2026-04-29T00:00:00.000",
                "violation_code": "10F",
                "violation_description": "Non-food contact surface improperly constructed.",
                "critical_flag": "Not Critical",
            }
        ]
    )

    result = parse_search_results(
        raw_text,
        source_url="https://data.cityofnewyork.us/resource/43nn-pn8j.json?$limit=1",
        dataset_id="43nn-pn8j",
    )

    assert result.warnings == []
    assert len(result.candidates) == 1
    candidate = result.candidates[0]
    assert candidate.inspection_date_raw == "2026-04-20"
    assert candidate.grade_date_raw == "2026-04-20"
    assert candidate.record_date_raw == "2026-04-29"
