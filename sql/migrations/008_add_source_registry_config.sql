alter table ops.source_registry
    add column if not exists source_config jsonb;
