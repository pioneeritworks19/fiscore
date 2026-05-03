alter table master.master_inspection
    add column if not exists inspector_name text;

alter table master.master_inspection_finding
    add column if not exists corrected_during_inspection boolean,
    add column if not exists is_repeat_violation boolean;
