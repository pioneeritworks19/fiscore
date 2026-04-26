from __future__ import annotations

from typing import Protocol

from fiscore_backend.ingestion.core.source_registry import SourceRegistryRecord
from fiscore_backend.ingestion.sources.ga_healthinspections.adapter import GeorgiaHealthInspectionsAdapter
from fiscore_backend.ingestion.sources.sword.adapter import SwordSourceAdapter


class SourceAdapter(Protocol):
    def handle_run(self, request): ...


def get_adapter_for_source(source: SourceRegistryRecord) -> SourceAdapter | None:
    if source.parser_id == "sword":
        return SwordSourceAdapter()
    if source.parser_id == "ga-healthinspections":
        return GeorgiaHealthInspectionsAdapter()
    return None
