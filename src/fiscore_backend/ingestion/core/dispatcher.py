from fiscore_backend.config import get_settings
from fiscore_backend.ingestion.core.adapter_registry import get_adapter_for_source
from fiscore_backend.ingestion.core.source_registry import get_source_by_slug
from fiscore_backend.models import WorkerRunRequest, WorkerRunResponse


def dispatch_run(request: WorkerRunRequest) -> WorkerRunResponse:
    settings = get_settings()
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
