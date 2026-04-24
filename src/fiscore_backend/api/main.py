from fastapi import FastAPI

from fiscore_backend.api.routes.health import router as health_router
from fiscore_backend.config import get_settings
from fiscore_backend.logging import configure_logging

configure_logging()
settings = get_settings()

app = FastAPI(
    title="FiScore API",
    version="0.1.0",
    summary="Backend API scaffold for FiScore ingestion and ops workflows.",
)

app.include_router(health_router)


@app.get("/ready")
def ready() -> dict[str, str]:
    return {
        "status": "ready",
        "project_id": settings.gcp_project_id,
        "region": settings.gcp_region,
    }

