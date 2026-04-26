import json
import logging

from fiscore_backend.config import get_settings
from fiscore_backend.ingestion.core.artifact_index import create_raw_artifact_index
from fiscore_backend.ingestion.core.parse_result_store import create_parse_result, create_parser_warning
from fiscore_backend.ingestion.core.run_issue_store import create_scrape_run_issue
from fiscore_backend.ingestion.core.run_logger import (
    mark_scrape_run_completed,
    mark_scrape_run_failed,
    mark_scrape_run_running,
)
from fiscore_backend.ingestion.core.source_registry import create_scrape_run, get_source_by_slug
from fiscore_backend.ingestion.sources.ga_healthinspections.detail_parser import (
    parse_detail_history_results,
)
from fiscore_backend.ingestion.sources.ga_healthinspections.fetcher import GeorgiaHealthInspectionsFetcher
from fiscore_backend.ingestion.sources.ga_healthinspections.normalizer import (
    attach_report_artifact,
    normalize_finding_payload,
    normalize_inspection_payload,
)
from fiscore_backend.ingestion.sources.ga_healthinspections.request_builder import build_run_plan
from fiscore_backend.ingestion.sources.ga_healthinspections.search_parser import parse_search_results
from fiscore_backend.models import WorkerRunRequest, WorkerRunResponse
from fiscore_backend.storage import RawArtifactStorage, hash_bytes, hash_text

logger = logging.getLogger(__name__)


class GeorgiaHealthInspectionsAdapter:
    """Statewide Georgia DPH food service adapter over the Tyler inspection portal."""

    def handle_run(self, request: WorkerRunRequest) -> WorkerRunResponse:
        settings = get_settings()
        warnings: list[str] = []
        operational_warnings: list[str] = []

        try:
            source = get_source_by_slug(request.source_slug)
        except Exception as exc:  # pragma: no cover - environment-specific connectivity
            logger.exception("Unable to load source registry record")
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=settings.default_parser_version,
                message="Georgia adapter could not load the source registry record.",
                warnings=[f"Database access failed while loading source registry: {exc}"],
            )

        if source is None:
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=settings.default_parser_version,
                message=f"No Georgia source registry record exists for {request.source_slug}.",
            )

        run_plan = build_run_plan(source, request.run_mode)
        scrape_run_id: str | None = None
        artifact_count = 0
        parse_result_count = 0
        normalized_record_count = 0
        fetcher = GeorgiaHealthInspectionsFetcher()

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
            issue_metadata: dict | None = None,
        ) -> None:
            operational_warnings.append(message)
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
                    issue_metadata=issue_metadata,
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
                    "source_config": source.source_config,
                    "parser_id": source.parser_id,
                    "parser_version": source.parser_version,
                },
            )
        except Exception as exc:  # pragma: no cover - environment-specific connectivity
            logger.exception("Unable to create scrape run")
            operational_warnings.append(f"Database access failed while logging scrape run: {exc}")

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
            landing_artifact, search_config = fetcher.fetch_landing_page(run_plan)
            search_artifacts = fetcher.fetch_search_api_results(
                landing_html=landing_artifact.content,
                landing_url=landing_artifact.source_url,
                search_config=search_config,
                run_plan=run_plan,
            )

            storage = RawArtifactStorage()
            seen_facility_tokens: set[str] = set()

            if scrape_run_id is not None:
                try:
                    landing_path = storage.build_html_path(
                        source_slug=request.source_slug,
                        scrape_run_id=scrape_run_id,
                        filename=landing_artifact.filename,
                    )
                    landing_storage_uri = storage.upload_text(
                        artifact=landing_path,
                        content=landing_artifact.content,
                        content_type=landing_artifact.content_type,
                    )
                    create_raw_artifact_index(
                        source_id=source.source_id,
                        scrape_run_id=scrape_run_id,
                        artifact_type="html",
                        source_url=landing_artifact.source_url,
                        storage_path=landing_storage_uri,
                        content_hash=hash_text(landing_artifact.content),
                    )
                    artifact_count += 1
                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                    record_warning(
                        category="storage",
                        code="landing_artifact_persist_failed",
                        message=f"Landing page persistence failed: {exc}",
                        component="adapter",
                        stage="landing",
                        source_url=landing_artifact.source_url,
                    )

                for search_artifact in search_artifacts:
                    try:
                        search_path = storage.build_raw_path(
                            source_slug=request.source_slug,
                            scrape_run_id=scrape_run_id,
                            filename=search_artifact.filename,
                            content_family="json",
                        )
                        search_storage_uri = storage.upload_text(
                            artifact=search_path,
                            content=search_artifact.content,
                            content_type=search_artifact.content_type,
                        )
                        create_raw_artifact_index(
                            source_id=source.source_id,
                            scrape_run_id=scrape_run_id,
                            artifact_type="json",
                            source_url=search_artifact.source_url,
                            storage_path=search_storage_uri,
                            content_hash=hash_text(search_artifact.content),
                        )
                        artifact_count += 1
                    except Exception as exc:  # pragma: no cover - environment-specific connectivity
                        record_warning(
                            category="storage",
                            code="search_artifact_persist_failed",
                            message=f"Search artifact persistence failed: {exc}",
                            component="adapter",
                            stage="search",
                            source_url=search_artifact.source_url,
                        )
                        continue

                    search_parse = parse_search_results(
                        search_artifact.content,
                        source_url=search_artifact.source_url,
                        county_name=search_artifact.county_name,
                    )
                    for parser_warning in search_parse.warnings:
                        record_warning(
                            category="parse",
                            code="ga_search_parse_warning",
                            message=parser_warning,
                            component="search_parser",
                            stage="search",
                            source_url=search_artifact.source_url,
                        )

                    for candidate in search_parse.candidates:
                        facility_token = candidate.facility_token
                        if not facility_token:
                            record_warning(
                                category="parse",
                                code="missing_facility_token",
                                message=(
                                    "Search candidate missing facility token for "
                                    f"{candidate.establishment_name_raw or 'unknown'}"
                                ),
                                component="search_parser",
                                stage="search",
                                source_record_key=candidate.source_record_key,
                                source_url=search_artifact.source_url,
                            )
                            continue
                        if facility_token in seen_facility_tokens:
                            continue
                        seen_facility_tokens.add(facility_token)

                        try:
                            detail_artifact = fetcher.fetch_inspections_json(facility_token)
                            detail_path = storage.build_raw_path(
                                source_slug=request.source_slug,
                                scrape_run_id=scrape_run_id,
                                filename=detail_artifact.filename,
                                content_family="json",
                            )
                            detail_storage_uri = storage.upload_text(
                                artifact=detail_path,
                                content=detail_artifact.content,
                                content_type=detail_artifact.content_type,
                            )
                            detail_raw_artifact_id = create_raw_artifact_index(
                                source_id=source.source_id,
                                scrape_run_id=scrape_run_id,
                                artifact_type="json",
                                source_url=detail_artifact.source_url,
                                storage_path=detail_storage_uri,
                                content_hash=hash_text(detail_artifact.content),
                            )
                            artifact_count += 1
                        except Exception as exc:  # pragma: no cover - environment-specific connectivity
                            record_warning(
                                category="fetch",
                                code="detail_fetch_failed",
                                message=f"Detail fetch failed for facility {facility_token}: {exc}",
                                component="fetcher",
                                stage="detail",
                                source_record_key=candidate.source_record_key,
                                source_url=candidate.detail_url,
                            )
                            continue

                        detail_parse = parse_detail_history_results(
                            detail_artifact.content,
                            source_url=detail_artifact.source_url,
                            county_name=candidate.county_name,
                            fallback_restaurant=candidate.to_payload(
                                source_url=search_artifact.source_url
                            )["restaurant"],
                        )
                        if not detail_parse.inspections:
                            record_warning(
                                category="parse",
                                code="inspection_payload_missing",
                                message=f"No inspection payload parsed for {candidate.detail_url}",
                                component="detail_parser",
                                stage="detail",
                                raw_artifact_id=detail_raw_artifact_id,
                                source_record_key=candidate.source_record_key,
                                source_url=candidate.detail_url,
                            )
                            continue

                        for history_warning in detail_parse.warnings:
                            record_warning(
                                category="parse",
                                code="ga_detail_parse_warning",
                                message=history_warning,
                                component="detail_parser",
                                stage="detail",
                                raw_artifact_id=detail_raw_artifact_id,
                                source_record_key=candidate.source_record_key,
                                source_url=detail_artifact.source_url,
                            )

                        for inspection_record in detail_parse.inspections:
                            inspection_payload = inspection_record.inspection.to_payload(
                                source_url=detail_artifact.source_url
                            )
                            inspection_parse_result_id = create_parse_result(
                                source_id=source.source_id,
                                scrape_run_id=scrape_run_id,
                                raw_artifact_id=detail_raw_artifact_id,
                                parser_version=source.parser_version,
                                record_type="inspection",
                                source_record_key=inspection_record.inspection.source_record_key,
                                parse_status=(
                                    "parsed_with_warnings" if inspection_record.warnings else "parsed"
                                ),
                                payload=json.dumps(inspection_payload),
                                warning_count=len(inspection_record.warnings),
                            )
                            parse_result_count += 1

                            try:
                                normalized_inspection = normalize_inspection_payload(
                                    source_id=source.source_id,
                                    payload=inspection_payload,
                                )
                                normalized_record_count += normalized_inspection.normalized_count
                            except Exception as exc:  # pragma: no cover - environment-specific connectivity
                                record_warning(
                                    category="normalize",
                                    code="inspection_normalization_failed",
                                    message=f"Inspection normalization failed for {candidate.detail_url}: {exc}",
                                    component="normalizer",
                                    stage="normalize",
                                    parse_result_id=inspection_parse_result_id,
                                    raw_artifact_id=detail_raw_artifact_id,
                                    source_record_key=inspection_record.inspection.source_record_key,
                                    source_url=candidate.detail_url,
                                )

                            for detail_warning in inspection_record.warnings:
                                create_parser_warning(
                                    parse_result_id=inspection_parse_result_id,
                                    warning_code="ga_detail_parse_warning",
                                    warning_message=detail_warning,
                                )
                                record_warning(
                                    category="parse",
                                    code="ga_detail_parse_warning",
                                    message=detail_warning,
                                    component="detail_parser",
                                    stage="detail",
                                    parse_result_id=inspection_parse_result_id,
                                    raw_artifact_id=detail_raw_artifact_id,
                                    source_record_key=inspection_record.inspection.source_record_key,
                                    source_url=detail_artifact.source_url,
                                )

                            report_url = inspection_payload.get("report_url")
                            if report_url:
                                try:
                                    filename_stem = (
                                        f"inspection_report_{inspection_record.inspection.source_record_key[:16]}"
                                    )
                                    report_artifact = fetcher.fetch_report_artifact(
                                        str(report_url),
                                        filename_stem=filename_stem,
                                    )
                                    report_family = (
                                        "pdf"
                                        if "pdf" in report_artifact.content_type.lower()
                                        else "html"
                                    )
                                    report_path = storage.build_raw_path(
                                        source_slug=request.source_slug,
                                        scrape_run_id=scrape_run_id,
                                        filename=report_artifact.filename,
                                        content_family=report_family,
                                    )
                                    report_storage_uri = storage.upload_bytes(
                                        artifact=report_path,
                                        content=report_artifact.content,
                                        content_type=report_artifact.content_type,
                                    )
                                    create_raw_artifact_index(
                                        source_id=source.source_id,
                                        scrape_run_id=scrape_run_id,
                                        artifact_type=report_family,
                                        source_url=report_artifact.source_url,
                                        storage_path=report_storage_uri,
                                        content_hash=hash_bytes(report_artifact.content),
                                    )
                                    artifact_count += 1
                                    normalized_record_count += attach_report_artifact(
                                        source_id=source.source_id,
                                        inspection_payload=inspection_payload,
                                        storage_path=report_storage_uri,
                                        report_format=report_family,
                                    )
                                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                                    record_warning(
                                        category="fetch",
                                        code="report_artifact_fetch_failed",
                                        message=f"Report artifact fetch failed for {report_url}: {exc}",
                                        component="fetcher",
                                        stage="report",
                                        parse_result_id=inspection_parse_result_id,
                                        source_record_key=inspection_record.inspection.source_record_key,
                                        source_url=str(report_url),
                                    )

                            for finding in inspection_record.findings:
                                finding_payload = finding.to_payload(
                                    inspection_payload=inspection_payload,
                                    source_url=detail_artifact.source_url,
                                )
                                finding_parse_result_id = create_parse_result(
                                    source_id=source.source_id,
                                    scrape_run_id=scrape_run_id,
                                    raw_artifact_id=detail_raw_artifact_id,
                                    parser_version=source.parser_version,
                                    record_type="finding",
                                    source_record_key=finding.source_record_key,
                                    parse_status=(
                                        "parsed_with_warnings" if inspection_record.warnings else "parsed"
                                    ),
                                    payload=json.dumps(finding_payload),
                                    warning_count=len(inspection_record.warnings),
                                )
                                parse_result_count += 1
                                try:
                                    normalized_record_count += normalize_finding_payload(
                                        source_id=source.source_id,
                                        payload=finding_payload,
                                    )
                                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                                    record_warning(
                                        category="normalize",
                                        code="finding_normalization_failed",
                                        message=f"Finding normalization failed for {candidate.detail_url}: {exc}",
                                        component="normalizer",
                                        stage="normalize",
                                        parse_result_id=finding_parse_result_id,
                                        raw_artifact_id=detail_raw_artifact_id,
                                        source_record_key=finding.source_record_key,
                                        source_url=candidate.detail_url,
                                    )

                                for detail_warning in inspection_record.warnings:
                                    create_parser_warning(
                                        parse_result_id=finding_parse_result_id,
                                        warning_code="ga_detail_parse_warning",
                                        warning_message=detail_warning,
                                    )
                                    record_warning(
                                        category="parse",
                                        code="ga_detail_parse_warning",
                                        message=detail_warning,
                                        component="detail_parser",
                                        stage="detail",
                                        parse_result_id=finding_parse_result_id,
                                        raw_artifact_id=detail_raw_artifact_id,
                                        source_record_key=finding.source_record_key,
                                        source_url=detail_artifact.source_url,
                                    )
        except Exception as exc:  # pragma: no cover - fetch/runtime-specific
            logger.exception("Georgia fetch failed")
            if scrape_run_id is not None:
                try:
                    record_error(
                        category="fetch",
                        code="ga_run_failed",
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
                message="Georgia adapter failed while fetching the source artifacts.",
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
                operational_warnings.append(f"Could not finalize scrape run status: {exc}")

        warnings = operational_warnings

        return WorkerRunResponse(
            accepted=True,
            source_slug=request.source_slug,
            run_mode=request.run_mode,
            parser_version=source.parser_version,
            message=(
                "Georgia adapter accepted the run request and executed the statewide source "
                "through county-partitioned discovery, detail parsing, normalization, and audit "
                "report artifact capture."
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
