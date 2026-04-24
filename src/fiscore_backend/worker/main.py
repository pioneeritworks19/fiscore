from fastapi import FastAPI

from fiscore_backend.config import get_settings
from fiscore_backend.ingestion.core.dispatcher import dispatch_run
from fiscore_backend.logging import configure_logging
from fiscore_backend.models import HealthResponse, WorkerRunRequest, WorkerRunResponse

configure_logging()
settings = get_settings()

app = FastAPI(
    title="FiScore Worker",
    version="0.1.0",
    summary="Cloud Run worker scaffold for source ingestion jobs.",
)


@app.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    return HealthResponse(
        status="ok",
        service="fiscore-worker",
        environment=settings.app_env,
    )


@app.post("/jobs/run", response_model=WorkerRunResponse)
def run_job(request: WorkerRunRequest) -> WorkerRunResponse:
    return dispatch_run(request)
