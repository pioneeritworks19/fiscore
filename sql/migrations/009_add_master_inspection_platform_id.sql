alter table master.master_inspection
    add column if not exists platform_id uuid;

update master.master_inspection mi
set platform_id = sr.platform_id
from ops.source_registry sr
where mi.source_id = sr.source_id
  and mi.platform_id is null;

alter table master.master_inspection
    alter column platform_id set not null;

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'master_inspection_platform_id_fkey'
    ) then
        alter table master.master_inspection
            add constraint master_inspection_platform_id_fkey
            foreign key (platform_id) references ops.platform_registry(platform_id);
    end if;
end $$;

create index if not exists idx_master_inspection_platform_source_key
    on master.master_inspection(platform_id, source_inspection_key);

create index if not exists idx_master_inspection_finding_parent_source_key
    on master.master_inspection_finding(master_inspection_id, source_finding_key);
