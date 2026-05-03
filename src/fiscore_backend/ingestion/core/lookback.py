from __future__ import annotations

from fiscore_backend.models import RunMode, WorkerRunRequest


def resolve_lookback_days(
    *,
    request: WorkerRunRequest,
    incremental_default: int,
    reconciliation_default: int,
) -> int:
    configured = request.request_context.get("lookback_days")
    if configured is not None:
        value = int(configured)
        if value < 1:
            raise ValueError("request_context.lookback_days must be at least 1.")
        return value

    if request.run_mode == "incremental":
        return incremental_default
    if request.run_mode == "reconciliation":
        return reconciliation_default

    raise ValueError(f"Lookback days are not applicable for run mode {request.run_mode}.")


def is_small_incremental_run(*, request: WorkerRunRequest, threshold_days: int = 7) -> bool:
    if request.run_mode != "incremental":
        return False

    configured = request.request_context.get("lookback_days")
    if configured is None:
        return False

    return int(configured) <= threshold_days
