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
