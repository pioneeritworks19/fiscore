import logging
import json

from fiscore_backend.ingestion.core.artifact_index import create_raw_artifact_index
from fiscore_backend.ingestion.core.parse_result_store import create_parse_result, create_parser_warning
from fiscore_backend.ingestion.core.run_issue_store import create_scrape_run_issue
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

        def record_issue(
            *,
            severity: str,
            category: str,
            code: str,
            message: str,
            component: str,
            stage: str | None = None,
            parse_result_id: str | None = None,
            raw_artifact_id: str | None = None,
            source_record_key: str | None = None,
            source_url: str | None = None,
        ) -> None:
            warnings.append(message)
            if scrape_run_id is None:
                return
            try:
                create_scrape_run_issue(
                    scrape_run_id=scrape_run_id,
                    source_id=source.source_id,
                    severity=severity,
                    category=category,
                    code=code,
                    message=message,
                    component=component,
                    stage=stage,
                    parse_result_id=parse_result_id,
                    raw_artifact_id=raw_artifact_id,
                    source_record_key=source_record_key,
                    source_url=source_url,
                )
            except Exception:  # pragma: no cover - do not fail the run for issue logging
                logger.exception("Could not persist scrape run issue")

        def record_warning(**kwargs) -> None:
            record_issue(severity="warning", **kwargs)

        def record_error(**kwargs) -> None:
            record_issue(severity="error", **kwargs)

        try:
            scrape_run_id = create_scrape_run(
                source_id=source.source_id,
                request=request,
                parser_version=source.parser_version,
                request_context=run_plan.request_context,
                source_snapshot={
                    "source_slug": source.source_slug,
                    "source_name": source.source_name,
                    "platform_name": source.platform_name,
                    "jurisdiction_name": source.jurisdiction_name,
                    "base_url": source.base_url,
                    "parser_version": source.parser_version,
                },
            )
        except Exception as exc:  # pragma: no cover - environment-specific connectivity
            logger.exception("Unable to create scrape run")
            warnings.append(f"Database access failed while logging scrape run: {exc}")

        if scrape_run_id is not None:
            try:
                mark_scrape_run_running(scrape_run_id)
            except Exception as exc:  # pragma: no cover - environment-specific connectivity
                record_warning(
                    category="db",
                    code="scrape_run_mark_running_failed",
                    message=f"Could not mark scrape run as running: {exc}",
                    component="run_logger",
                    stage="start",
                )

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
                            record_warning(
                                category="parse",
                                code="sword_search_parse_warning",
                                message=f"Search parser (page {fetched_artifact.page_number or '?'}): {parser_warning}",
                                component="search_parser",
                                stage="search",
                                raw_artifact_id=raw_artifact_id,
                                source_url=fetched_artifact.source_url,
                            )
                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                    record_warning(
                        category="storage",
                        code="raw_artifact_persist_failed",
                        message=f"Raw artifact persistence failed: {exc}",
                        component="adapter",
                        stage="search",
                    )

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
                            record_warning(
                                category="normalize",
                                code="inspection_normalization_failed",
                                message=(
                                    "Inspection normalization failed for header "
                                    f"{candidate.header_id or candidate.source_record_key}: {exc}"
                                ),
                                component="normalizer",
                                stage="normalize",
                                parse_result_id=parse_result_id,
                                raw_artifact_id=candidate_raw_artifact_id,
                                source_record_key=candidate.source_record_key,
                                source_url=candidate_source_url,
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
                                    record_warning(
                                        category="parse",
                                        code="sword_detail_parse_warning",
                                        message=detail_warning,
                                        component="detail_parser",
                                        stage="detail",
                                        raw_artifact_id=detail_raw_artifact_id,
                                        source_record_key=candidate.source_record_key,
                                        source_url=detail_artifact.source_url,
                                    )

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
                                        record_warning(
                                            category="normalize",
                                            code="finding_normalization_failed",
                                            message=(
                                                "Finding normalization failed for header "
                                                f"{finding.header_id or 'unknown'} detail {finding.detail_id or 'unknown'}: {exc}"
                                            ),
                                            component="normalizer",
                                            stage="normalize",
                                            parse_result_id=finding_parse_result_id,
                                            raw_artifact_id=detail_raw_artifact_id,
                                            source_record_key=finding.source_record_key,
                                            source_url=detail_artifact.source_url,
                                        )

                                    for detail_warning in detail_parse.warnings:
                                        create_parser_warning(
                                            parse_result_id=finding_parse_result_id,
                                            warning_code="sword_detail_parse_warning",
                                            warning_message=detail_warning,
                                        )
                            except Exception as exc:  # pragma: no cover - environment-specific connectivity
                                record_warning(
                                    category="fetch",
                                    code="detail_fetch_or_parse_failed",
                                    message=f"Detail fetch or parse failed for header {candidate.header_id}: {exc}",
                                    component="adapter",
                                    stage="detail",
                                    source_record_key=candidate.source_record_key,
                                    source_url=candidate_source_url,
                                )
                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                    record_warning(
                        category="db",
                        code="search_parse_persist_failed",
                        message=f"Search parse persistence failed: {exc}",
                        component="adapter",
                        stage="search",
                    )
        except Exception as exc:  # pragma: no cover - fetch/runtime-specific
            logger.exception("Sword fetch failed")
            if scrape_run_id is not None:
                try:
                    record_error(
                        category="fetch",
                        code="sword_run_failed",
                        message=str(exc),
                        component="adapter",
                        stage="run",
                    )
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
                    warning_count=0,
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
