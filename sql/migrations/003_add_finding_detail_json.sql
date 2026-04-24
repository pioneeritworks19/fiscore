alter table master.master_inspection_finding
    add column if not exists official_detail_json jsonb;
