import httpx
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2 import id_token

from fiscore_backend.config import Settings, get_settings
from fiscore_backend.ingestion.core.adapter_registry import get_adapter_for_source
from fiscore_backend.ingestion.core.source_registry import get_source_by_slug
from fiscore_backend.models import WorkerRunRequest, WorkerRunResponse


def _dispatch_run_local(request: WorkerRunRequest, *, settings: Settings) -> WorkerRunResponse:
    try:
        source = get_source_by_slug(request.source_slug)
    except Exception as exc:  # pragma: no cover - environment-specific connectivity
        return WorkerRunResponse(
            accepted=False,
            source_slug=request.source_slug,
            run_mode=request.run_mode,
            parser_version=settings.default_parser_version,
            message=f"Could not resolve source registry record for {request.source_slug}.",
            warnings=[f"Source lookup failed: {exc}"],
        )
    if source is not None:
        adapter = get_adapter_for_source(source)
        if adapter is not None:
            return adapter.handle_run(request)

    return WorkerRunResponse(
        accepted=False,
        source_slug=request.source_slug,
        run_mode=request.run_mode,
        parser_version="unknown",
        message=f"No source adapter registered for {request.source_slug}.",
    )


def _worker_run_url(settings: Settings) -> str:
    if not settings.worker_base_url:
        raise ValueError("WORKER_BASE_URL is required when RUN_DISPATCH_MODE is worker_http.")
    return f"{settings.worker_base_url.rstrip('/')}/jobs/run"


def _dispatch_run_via_worker(request: WorkerRunRequest, *, settings: Settings) -> WorkerRunResponse:
    audience = settings.resolved_worker_audience
    if not audience:
        raise ValueError("WORKER_AUDIENCE or WORKER_BASE_URL is required when RUN_DISPATCH_MODE is worker_http.")

    token = id_token.fetch_id_token(GoogleAuthRequest(), audience)
    response = httpx.post(
        _worker_run_url(settings),
        json=request.model_dump(),
        headers={"Authorization": f"Bearer {token}"},
        timeout=30.0,
    )
    response.raise_for_status()
    return WorkerRunResponse.model_validate(response.json())


def dispatch_run(request: WorkerRunRequest) -> WorkerRunResponse:
    settings = get_settings()
    if settings.run_dispatch_mode == "worker_http":
        try:
            return _dispatch_run_via_worker(request, settings=settings)
        except Exception as exc:  # pragma: no cover - environment-specific connectivity
            return WorkerRunResponse(
                accepted=False,
                source_slug=request.source_slug,
                run_mode=request.run_mode,
                parser_version=settings.default_parser_version,
                message=f"Could not dispatch {request.source_slug} to the worker service.",
                warnings=[f"Worker dispatch failed: {exc}"],
            )

    return _dispatch_run_local(request, settings=settings)
