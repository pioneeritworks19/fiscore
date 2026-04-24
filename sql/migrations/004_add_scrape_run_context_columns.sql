alter table ops.scrape_run
    add column if not exists request_context jsonb;

alter table ops.scrape_run
    add column if not exists source_snapshot jsonb;
