import logging
import json

from fiscore_backend.ingestion.core.artifact_index import create_raw_artifact_index
from fiscore_backend.ingestion.core.parse_result_store import create_parse_result, create_parser_warning
from fiscore_backend.ingestion.core.run_logger import (
    mark_scrape_run_completed,
    mark_scrape_run_failed,
    mark_scrape_run_running,
)
from fiscore_backend.config import get_settings
from fiscore_backend.ingestion.core.source_registry import create_scrape_run, get_source_by_slug
from fiscore_backend.ingestion.sources.sword.detail_parser import parse_detail_results
from fiscore_backend.ingestion.sources.sword.fetcher import SwordFetcher
from fiscore_backend.ingestion.sources.sword.normalizer import (
    normalize_finding_payload,
    normalize_inspection_payload,
)
from fiscore_backend.ingestion.sources.sword.request_builder import build_run_plan
from fiscore_backend.ingestion.sources.sword.search_parser import parse_search_results
from fiscore_backend.models import WorkerRunRequest, WorkerRunResponse
from fiscore_backend.storage import RawArtifactStorage, hash_text

logger = logging.getLogger(__name__)


class SwordSourceAdapter:
    """First source adapter scaffold for Sword Solutions."""

    def handle_run(self, request: WorkerRunRequest) -> WorkerRunResponse:
        settings = get_settings()
        warnings: list[str] = []

        try:
            source = get_source_by_slug(request.source_slug)
        except Exception as exc:  # pragma: no cover - environment-specific connectivity
            logger.exception("Unable to load source registry record")
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=settings.default_parser_version,
                message="Sword adapter could not load the source registry record.",
                warnings=[f"Database access failed while loading source registry: {exc}"],
            )

        if source is None:
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=settings.default_parser_version,
                message=f"No Sword source registry record exists for {request.source_slug}.",
            )

        run_plan = build_run_plan(source, request.run_mode)
        scrape_run_id: str | None = None
        artifact_count = 0
        parse_result_count = 0
        normalized_record_count = 0
        fetcher = SwordFetcher()

        try:
            scrape_run_id = create_scrape_run(
                source_id=source.source_id,
                request=request,
                parser_version=source.parser_version,
            )
        except Exception as exc:  # pragma: no cover - environment-specific connectivity
            logger.exception("Unable to create scrape run")
            warnings.append(f"Database access failed while logging scrape run: {exc}")

        if scrape_run_id is not None:
            try:
                mark_scrape_run_running(scrape_run_id)
            except Exception as exc:  # pragma: no cover - environment-specific connectivity
                warnings.append(f"Could not mark scrape run as running: {exc}")

        try:
            fetched_artifacts = fetcher.fetch_search_results(run_plan)
            if not fetched_artifacts:
                raise ValueError("Sword search returned zero result pages.")

            raw_artifact_id: str | None = None
            storage = RawArtifactStorage()
            parsed_candidates: list[tuple[object, str | None, list[str], str]] = []

            if scrape_run_id is not None:
                try:
                    for fetched_artifact in fetched_artifacts:
                        content_hash = hash_text(fetched_artifact.content)
                        artifact_path = storage.build_html_path(
                            source_slug=request.source_slug,
                            scrape_run_id=scrape_run_id,
                            filename=fetched_artifact.filename,
                        )
                        storage_uri = storage.upload_text(
                            artifact=artifact_path,
                            content=fetched_artifact.content,
                            content_type=fetched_artifact.content_type,
                        )
                        raw_artifact_id = create_raw_artifact_index(
                            source_id=source.source_id,
                            scrape_run_id=scrape_run_id,
                            artifact_type="html",
                            source_url=fetched_artifact.source_url,
                            storage_path=storage_uri,
                            content_hash=content_hash,
                        )
                        artifact_count += 1

                        search_parse = parse_search_results(
                            fetched_artifact.content,
                            source_url=fetched_artifact.source_url,
                            county_name=source.jurisdiction_name,
                        )
                        parsed_candidates.extend(
                            (candidate, raw_artifact_id, search_parse.warnings, fetched_artifact.source_url)
                            for candidate in search_parse.candidates
                        )

                        for parser_warning in search_parse.warnings:
                            warnings.append(
                                f"Search parser (page {fetched_artifact.page_number or '?'}): {parser_warning}"
                            )
                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                    warnings.append(f"Raw artifact persistence failed: {exc}")

                try:
                    for candidate, candidate_raw_artifact_id, candidate_warnings, candidate_source_url in parsed_candidates:
                        parse_result_id = create_parse_result(
                            source_id=source.source_id,
                            scrape_run_id=scrape_run_id,
                            raw_artifact_id=candidate_raw_artifact_id,
                            parser_version=source.parser_version,
                            record_type="inspection",
                            source_record_key=candidate.source_record_key,
                            parse_status=(
                                "parsed_with_warnings" if candidate_warnings else "parsed"
                            ),
                            payload=json.dumps(
                                candidate.to_payload(
                                    county_name=source.jurisdiction_name,
                                    source_url=candidate_source_url,
                                )
                            ),
                            warning_count=len(candidate_warnings),
                        )
                        parse_result_count += 1
                        try:
                            normalized_inspection = normalize_inspection_payload(
                                source_id=source.source_id,
                                payload=candidate.to_payload(
                                    county_name=source.jurisdiction_name,
                                    source_url=candidate_source_url,
                                ),
                            )
                            normalized_record_count += normalized_inspection.normalized_count
                        except Exception as exc:  # pragma: no cover - environment-specific connectivity
                            warnings.append(
                                f"Inspection normalization failed for header {candidate.header_id or candidate.source_record_key}: {exc}"
                            )

                        for parser_warning in candidate_warnings:
                            create_parser_warning(
                                parse_result_id=parse_result_id,
                                warning_code="sword_search_parse_warning",
                                warning_message=parser_warning,
                            )

                        if candidate.header_id:
                            try:
                                detail_artifact = fetcher.fetch_detail_results(
                                    base_url=str(run_plan.request_context["base_url"]),
                                    header_id=candidate.header_id,
                                )
                                detail_hash = hash_text(detail_artifact.content)
                                detail_path = storage.build_html_path(
                                    source_slug=request.source_slug,
                                    scrape_run_id=scrape_run_id,
                                    filename=detail_artifact.filename,
                                )
                                detail_storage_uri = storage.upload_text(
                                    artifact=detail_path,
                                    content=detail_artifact.content,
                                    content_type=detail_artifact.content_type,
                                )
                                detail_raw_artifact_id = create_raw_artifact_index(
                                    source_id=source.source_id,
                                    scrape_run_id=scrape_run_id,
                                    artifact_type="html",
                                    source_url=detail_artifact.source_url,
                                    storage_path=detail_storage_uri,
                                    content_hash=detail_hash,
                                )
                                artifact_count += 1

                                detail_parse = parse_detail_results(
                                    detail_artifact.content,
                                    source_url=detail_artifact.source_url,
                                )
                                for detail_warning in detail_parse.warnings:
                                    warnings.append(f"Detail parser: {detail_warning}")

                                for finding in detail_parse.findings:
                                    finding_parse_result_id = create_parse_result(
                                        source_id=source.source_id,
                                        scrape_run_id=scrape_run_id,
                                        raw_artifact_id=detail_raw_artifact_id,
                                        parser_version=source.parser_version,
                                        record_type="finding",
                                        source_record_key=finding.source_record_key,
                                        parse_status=(
                                            "parsed_with_warnings"
                                            if detail_parse.warnings
                                            else "parsed"
                                        ),
                                        payload=json.dumps(
                                            finding.to_payload(
                                                source_url=detail_artifact.source_url,
                                            )
                                        ),
                                        warning_count=len(detail_parse.warnings),
                                    )
                                    parse_result_count += 1
                                    try:
                                        normalized_record_count += normalize_finding_payload(
                                            source_id=source.source_id,
                                            payload=finding.to_payload(
                                                source_url=detail_artifact.source_url,
                                            ),
                                        )
                                    except Exception as exc:  # pragma: no cover - environment-specific connectivity
                                        warnings.append(
                                            f"Finding normalization failed for header {finding.header_id or 'unknown'} detail {finding.detail_id or 'unknown'}: {exc}"
                                        )

                                    for detail_warning in detail_parse.warnings:
                                        create_parser_warning(
                                            parse_result_id=finding_parse_result_id,
                                            warning_code="sword_detail_parse_warning",
                                            warning_message=detail_warning,
                                        )
                            except Exception as exc:  # pragma: no cover - environment-specific connectivity
                                warnings.append(
                                    f"Detail fetch or parse failed for header {candidate.header_id}: {exc}"
                                )
                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                    warnings.append(f"Search parse persistence failed: {exc}")
        except Exception as exc:  # pragma: no cover - fetch/runtime-specific
            logger.exception("Sword fetch failed")
            if scrape_run_id is not None:
                try:
                    mark_scrape_run_failed(scrape_run_id, str(exc))
                except Exception:
                    pass
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=source.parser_version,
                message="Sword adapter failed while fetching the initial source artifact.",
                scrape_run_id=scrape_run_id,
                date_from=run_plan.date_from,
                date_to=run_plan.date_to,
                request_context=run_plan.request_context,
                warnings=warnings + [f"Fetch failed: {exc}"],
            )

        if scrape_run_id is not None:
            try:
                mark_scrape_run_completed(
                    scrape_run_id,
                    artifact_count=artifact_count,
                    parsed_record_count=parse_result_count,
                    normalized_record_count=normalized_record_count,
                    warning_count=len(warnings),
                    error_count=0,
                )
            except Exception as exc:  # pragma: no cover - environment-specific connectivity
                warnings.append(f"Could not finalize scrape run status: {exc}")

        logger.info(
            "Accepted Sword run",
            extra={
                "source_slug": request.source_slug,
                "run_mode": request.run_mode,
                "trigger_type": request.trigger_type,
                "strategy": run_plan.strategy,
                "scrape_run_id": scrape_run_id,
                "artifact_count": artifact_count,
                "parse_result_count": parse_result_count,
                "normalized_record_count": normalized_record_count,
            },
        )
        return WorkerRunResponse(
            accepted=True,
            source_slug=request.source_slug,
            run_mode=request.run_mode,
            parser_version=source.parser_version,
            message=(
                "Sword adapter accepted the run request and built the initial execution plan. "
                "Next implementation steps are fetch, raw artifact persistence, parsing, and "
                "normalization."
            ),
            scrape_run_id=scrape_run_id,
            date_from=run_plan.date_from,
            date_to=run_plan.date_to,
            artifact_count=artifact_count,
            parse_result_count=parse_result_count,
            normalized_record_count=normalized_record_count,
            request_context=run_plan.request_context,
            warnings=warnings,
        )
