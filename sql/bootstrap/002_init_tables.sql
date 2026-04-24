create extension if not exists pgcrypto;

create table if not exists ops.source_registry (
    source_id uuid primary key default gen_random_uuid(),
    source_slug text not null unique,
    source_name text not null,
    platform_name text not null,
    jurisdiction_name text not null,
    source_type text not null,
    base_url text not null,
    cadence_type text not null,
    target_freshness_days integer not null,
    parser_id text not null,
    parser_version text not null,
    status text not null default 'active',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists ops.scrape_run (
    scrape_run_id uuid primary key default gen_random_uuid(),
    source_id uuid not null references ops.source_registry(source_id),
    run_mode text not null,
    trigger_type text not null,
    run_status text not null default 'queued',
    parser_version text not null,
    started_at timestamptz not null default now(),
    completed_at timestamptz,
    discovery_count integer not null default 0,
    artifact_count integer not null default 0,
    parsed_record_count integer not null default 0,
    normalized_record_count integer not null default 0,
    warning_count integer not null default 0,
    error_count integer not null default 0,
    error_summary text
);

create table if not exists ops.source_health (
    source_health_id uuid primary key default gen_random_uuid(),
    source_id uuid not null references ops.source_registry(source_id),
    health_status text not null,
    freshness_age_days integer,
    last_evaluated_at timestamptz not null default now(),
    signal_summary jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists ops.operational_alert (
    operational_alert_id uuid primary key default gen_random_uuid(),
    source_id uuid references ops.source_registry(source_id),
    scrape_run_id uuid references ops.scrape_run(scrape_run_id),
    alert_type text not null,
    severity text not null,
    status text not null default 'open',
    title text not null,
    message text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists ops.rerun_request (
    rerun_request_id uuid primary key default gen_random_uuid(),
    source_id uuid not null references ops.source_registry(source_id),
    requested_scope text not null,
    requested_by text,
    request_payload jsonb,
    status text not null default 'pending',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists ingestion.raw_artifact_index (
    raw_artifact_id uuid primary key default gen_random_uuid(),
    source_id uuid not null references ops.source_registry(source_id),
    scrape_run_id uuid not null references ops.scrape_run(scrape_run_id),
    artifact_type text not null,
    source_url text not null,
    storage_path text not null,
    content_hash text not null,
    fetched_at timestamptz not null default now(),
    created_at timestamptz not null default now()
);

create table if not exists ingestion.parse_result (
    parse_result_id uuid primary key default gen_random_uuid(),
    source_id uuid not null references ops.source_registry(source_id),
    scrape_run_id uuid not null references ops.scrape_run(scrape_run_id),
    raw_artifact_id uuid references ingestion.raw_artifact_index(raw_artifact_id),
    parser_version text not null,
    record_type text not null,
    source_record_key text,
    parse_status text not null,
    payload jsonb not null,
    warning_count integer not null default 0,
    error_count integer not null default 0,
    created_at timestamptz not null default now()
);

create table if not exists ingestion.parser_warning (
    parser_warning_id uuid primary key default gen_random_uuid(),
    parse_result_id uuid not null references ingestion.parse_result(parse_result_id),
    warning_code text not null,
    warning_message text not null,
    created_at timestamptz not null default now()
);

create table if not exists master.master_restaurant (
    master_restaurant_id uuid primary key default gen_random_uuid(),
    location_fingerprint text not null,
    display_name text not null,
    normalized_name text,
    address_line1 text not null,
    address_line2 text,
    normalized_address1 text,
    normalized_unit text,
    city text not null,
    state_code text not null,
    zip_code text,
    country_code text not null default 'US',
    status text not null default 'active',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists master.master_restaurant_identifier (
    master_restaurant_identifier_id uuid primary key default gen_random_uuid(),
    master_restaurant_id uuid not null references master.master_restaurant(master_restaurant_id),
    source_id uuid references ops.source_registry(source_id),
    identifier_type text not null,
    identifier_value text not null,
    is_primary boolean not null default false,
    confidence numeric(5, 2),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists master.master_restaurant_source_link (
    master_restaurant_source_link_id uuid primary key default gen_random_uuid(),
    master_restaurant_id uuid not null references master.master_restaurant(master_restaurant_id),
    source_id uuid not null references ops.source_registry(source_id),
    source_restaurant_key text not null,
    match_method text not null,
    match_confidence numeric(5, 2),
    match_status text not null,
    matched_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (source_id, source_restaurant_key)
);

create table if not exists master.master_inspection (
    master_inspection_id uuid primary key default gen_random_uuid(),
    master_restaurant_id uuid not null references master.master_restaurant(master_restaurant_id),
    source_id uuid not null references ops.source_registry(source_id),
    source_inspection_key text not null,
    inspection_date date not null,
    inspection_type text,
    score numeric(8, 2),
    grade text,
    official_status text,
    report_url text,
    is_current boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (source_id, source_inspection_key)
);

create table if not exists master.master_inspection_report (
    master_inspection_report_id uuid primary key default gen_random_uuid(),
    master_inspection_id uuid not null references master.master_inspection(master_inspection_id),
    source_id uuid not null references ops.source_registry(source_id),
    report_role text not null,
    report_format text,
    availability_status text not null,
    source_page_url text,
    source_file_url text,
    storage_path text,
    is_current boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (master_inspection_id, source_id, report_role)
);

create table if not exists master.master_inspection_finding (
    master_inspection_finding_id uuid primary key default gen_random_uuid(),
    master_inspection_id uuid not null references master.master_inspection(master_inspection_id),
    source_id uuid not null references ops.source_registry(source_id),
    source_finding_key text,
    finding_order integer,
    official_code text,
    official_clause_reference text,
    official_text text not null,
    official_detail_text text,
    official_detail_json jsonb,
    auditor_comments text,
    normalized_title text,
    normalized_category text,
    severity text,
    is_current boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists master.source_clause_reference (
    source_clause_reference_id uuid primary key default gen_random_uuid(),
    source_id uuid not null references ops.source_registry(source_id),
    clause_code text not null,
    violation_category text,
    clause_description text not null,
    content_hash text,
    is_current boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists master.source_version (
    source_version_id uuid primary key default gen_random_uuid(),
    source_id uuid not null references ops.source_registry(source_id),
    entity_type text not null,
    entity_id uuid,
    source_entity_key text,
    version_number integer not null,
    is_current boolean not null default false,
    change_type text not null,
    change_summary text,
    raw_payload jsonb,
    content_hash text,
    effective_at timestamptz not null default now(),
    created_at timestamptz not null default now()
);
