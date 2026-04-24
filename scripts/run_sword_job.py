from __future__ import annotations

import json
import sys

from fiscore_backend.ingestion.sources.sword.adapter import SwordSourceAdapter
from fiscore_backend.models import WorkerRunRequest


def main() -> None:
    source_slug = sys.argv[1] if len(sys.argv) > 1 else "sword_mi_wayne"
    run_mode = sys.argv[2] if len(sys.argv) > 2 else "incremental"

    request = WorkerRunRequest(
        source_slug=source_slug,
        run_mode=run_mode,
        trigger_type="manual",
    )
    response = SwordSourceAdapter().handle_run(request)
    print(json.dumps(response.model_dump(mode="json"), indent=2, default=str))


if __name__ == "__main__":
    main()

