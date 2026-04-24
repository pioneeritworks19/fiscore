from fiscore_backend.ingestion.sources.sword.adapter import SwordSourceAdapter
from fiscore_backend.models import WorkerRunRequest, WorkerRunResponse


def dispatch_run(request: WorkerRunRequest) -> WorkerRunResponse:
    if request.source_slug.startswith("sword_"):
        return SwordSourceAdapter().handle_run(request)

    return WorkerRunResponse(
        accepted=False,
        source_slug=request.source_slug,
        run_mode=request.run_mode,
        parser_version="unknown",
        message=f"No source adapter registered for {request.source_slug}.",
    )

