alter table master.master_inspection_finding
    add column if not exists official_detail_text text;

alter table master.master_inspection_finding
    add column if not exists auditor_comments text;
