from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from fiscore_backend.ingestion.core.dispatcher import dispatch_run
from fiscore_backend.models import WorkerRunRequest


def main() -> None:
    source_slug = sys.argv[1] if len(sys.argv) > 1 else "sword_mi_wayne"
    run_mode = sys.argv[2] if len(sys.argv) > 2 else "incremental"

    request = WorkerRunRequest(
        source_slug=source_slug,
        run_mode=run_mode,
        trigger_type="manual",
    )
    response = dispatch_run(request)
    print(json.dumps(response.model_dump(mode="json"), indent=2, default=str))


if __name__ == "__main__":
    main()
