create table if not exists ops.scrape_run_issue (
    scrape_run_issue_id uuid primary key default gen_random_uuid(),
    scrape_run_id uuid not null references ops.scrape_run(scrape_run_id),
    source_id uuid not null references ops.source_registry(source_id),
    severity text not null,
    category text not null,
    issue_code text not null,
    issue_message text not null,
    component text,
    stage text,
    parse_result_id uuid references ingestion.parse_result(parse_result_id),
    raw_artifact_id uuid references ingestion.raw_artifact_index(raw_artifact_id),
    source_record_key text,
    source_url text,
    issue_metadata jsonb,
    created_at timestamptz not null default now()
);

create index if not exists idx_scrape_run_issue_scrape_run_id
    on ops.scrape_run_issue(scrape_run_id, created_at desc);

create index if not exists idx_scrape_run_issue_severity
    on ops.scrape_run_issue(severity, created_at desc);
