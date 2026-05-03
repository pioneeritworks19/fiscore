import logging
import json

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
from fiscore_backend.ingestion.sources.nyc_dohmh.fetcher import NYCDOHMHFetcher
from fiscore_backend.ingestion.sources.nyc_dohmh.normalizer import (
    normalize_finding_payload,
    normalize_inspection_payload,
)
from fiscore_backend.ingestion.sources.nyc_dohmh.request_builder import build_run_plan
from fiscore_backend.ingestion.sources.nyc_dohmh.search_parser import parse_search_results
from fiscore_backend.models import WorkerRunRequest, WorkerRunResponse
from fiscore_backend.storage import RawArtifactStorage, hash_text

logger = logging.getLogger(__name__)


class NYCDOHMHAdapter:
    """Initial NYC DOHMH dataset adapter scaffold."""

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
                message="NYC DOHMH adapter could not load the source registry record.",
                warnings=[f"Database access failed while loading source registry: {exc}"],
            )

        if source is None:
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=settings.default_parser_version,
                message=f"No NYC DOHMH source registry record exists for {request.source_slug}.",
            )

        run_plan = build_run_plan(source, request)
        scrape_run_id: str | None = None
        fetcher = NYCDOHMHFetcher()
        artifact_count = 0
        parse_result_count = 0
        normalized_record_count = 0

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
            metadata_artifact = fetcher.fetch_metadata(run_plan)
            columns_artifact = fetcher.fetch_columns(run_plan)
            row_artifacts = fetcher.fetch_row_pages(run_plan)

            storage = RawArtifactStorage()

            def persist_artifact(artifact, *, artifact_type: str) -> str | None:
                nonlocal artifact_count
                if scrape_run_id is None:
                    return None
                try:
                    artifact_path = storage.build_raw_path(
                        source_slug=request.source_slug,
                        scrape_run_id=scrape_run_id,
                        filename=artifact.filename,
                        content_family="json",
                    )
                    storage_uri = storage.upload_text(
                        artifact=artifact_path,
                        content=artifact.content,
                        content_type=artifact.content_type,
                    )
                    raw_artifact_id = create_raw_artifact_index(
                        source_id=source.source_id,
                        scrape_run_id=scrape_run_id,
                        artifact_type=artifact_type,
                        source_url=artifact.source_url,
                        storage_path=storage_uri,
                        content_hash=hash_text(artifact.content),
                    )
                    artifact_count += 1
                    return raw_artifact_id
                except Exception as exc:  # pragma: no cover - environment-specific connectivity
                    record_warning(
                        category="storage",
                        code="raw_artifact_persist_failed",
                        message=f"NYC raw artifact persistence failed: {exc}",
                        component="adapter",
                        stage="storage",
                        source_url=artifact.source_url,
                    )
                    return None

            metadata_raw_artifact_id = persist_artifact(metadata_artifact, artifact_type="json")
            columns_raw_artifact_id = persist_artifact(columns_artifact, artifact_type="json")
            if metadata_raw_artifact_id is None:
                warnings.append("NYC metadata artifact was not indexed.")
            if columns_raw_artifact_id is None:
                warnings.append("NYC columns artifact was not indexed.")

            for row_artifact in row_artifacts:
                row_raw_artifact_id = persist_artifact(row_artifact, artifact_type="json")
                parsed = parse_search_results(
                    row_artifact.content,
                    source_url=row_artifact.source_url,
                    dataset_id=str(run_plan.request_context["dataset_id"]),
                )

                for parser_warning in parsed.warnings:
                    warnings.append(parser_warning)
                    record_warning(
                        category="parse",
                        code="nyc_row_parse_warning",
                        message=parser_warning,
                        component="search_parser",
                        stage="parse",
                        raw_artifact_id=row_raw_artifact_id,
                        source_url=row_artifact.source_url,
                    )

                for candidate in parsed.candidates:
                    inspection_payload = candidate.to_payload(
                        source_url=row_artifact.source_url,
                        dataset_id=str(run_plan.request_context["dataset_id"]),
                    )
                    inspection_parse_result_id: str | None = None
                    if scrape_run_id is not None:
                        inspection_parse_result_id = create_parse_result(
                            source_id=source.source_id,
                            scrape_run_id=scrape_run_id,
                            raw_artifact_id=row_raw_artifact_id,
                            parser_version=source.parser_version,
                            record_type="inspection",
                            source_record_key=candidate.source_inspection_key,
                            parse_status=("parsed_with_warnings" if parsed.warnings else "parsed"),
                            payload=json.dumps(inspection_payload),
                            warning_count=len(parsed.warnings),
                        )
                        parse_result_count += 1

                        for parser_warning in parsed.warnings:
                            create_parser_warning(
                                parse_result_id=inspection_parse_result_id,
                                warning_code="nyc_row_parse_warning",
                                warning_message=parser_warning,
                            )

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
                            message=(
                                "NYC inspection normalization failed for "
                                f"{candidate.source_inspection_key}: {exc}"
                            ),
                            component="normalizer",
                            stage="normalize",
                            parse_result_id=inspection_parse_result_id,
                            raw_artifact_id=row_raw_artifact_id,
                            source_record_key=candidate.source_inspection_key,
                            source_url=row_artifact.source_url,
                        )
                        continue

                    if not normalized_inspection.master_inspection_id:
                        continue

                    for finding_payload in inspection_payload.get("findings", []):
                        finding_payload_with_context = {
                            **finding_payload,
                            "restaurant": inspection_payload["restaurant"],
                            "inspection": inspection_payload["inspection"],
                        }
                        try:
                            normalized_record_count += normalize_finding_payload(
                                source_id=source.source_id,
                                payload=finding_payload_with_context,
                            )
                        except Exception as exc:  # pragma: no cover - environment-specific connectivity
                            record_warning(
                                category="normalize",
                                code="finding_normalization_failed",
                                message=(
                                    "NYC finding normalization failed for "
                                    f"{finding_payload.get('source_finding_key')}: {exc}"
                                ),
                                component="normalizer",
                                stage="normalize",
                                parse_result_id=inspection_parse_result_id,
                                raw_artifact_id=row_raw_artifact_id,
                                source_record_key=candidate.source_inspection_key,
                                source_url=row_artifact.source_url,
                            )

            if scrape_run_id is not None:
                mark_scrape_run_completed(
                    scrape_run_id,
                    artifact_count=artifact_count,
                    parsed_record_count=parse_result_count,
                    normalized_record_count=normalized_record_count,
                    warning_count=len(warnings),
                    error_count=0,
                )
        except Exception as exc:  # pragma: no cover - environment-specific connectivity
            if scrape_run_id is not None:
                try:
                    mark_scrape_run_failed(scrape_run_id, str(exc))
                except Exception:
                    logger.exception("Could not mark NYC scrape run failed")
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=source.parser_version,
                scrape_run_id=scrape_run_id,
                message="NYC DOHMH run failed before completion.",
                warnings=[*warnings, *operational_warnings, str(exc)],
                date_from=run_plan.date_from,
                date_to=run_plan.date_to,
                artifact_count=artifact_count,
                parse_result_count=parse_result_count,
                normalized_record_count=normalized_record_count,
                request_context=run_plan.request_context,
            )

        return WorkerRunResponse(
            accepted=True,
            source_slug=request.source_slug,
            run_mode=request.run_mode,
            parser_version=source.parser_version,
            scrape_run_id=scrape_run_id,
            message="NYC DOHMH run completed metadata fetch, artifact persistence, parsing, and normalization.",
            artifact_count=artifact_count,
            parse_result_count=parse_result_count,
            normalized_record_count=normalized_record_count,
            date_from=run_plan.date_from,
            date_to=run_plan.date_to,
            request_context={
                **run_plan.request_context,
                "row_page_count": artifact_count - 2 if artifact_count >= 2 else 0,
            },
            warnings=[*warnings, *operational_warnings],
        )
