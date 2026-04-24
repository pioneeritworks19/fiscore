from fastapi import APIRouter

from fiscore_backend.config import get_settings
from fiscore_backend.models import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service="fiscore-api",
        environment=settings.app_env,
    )

