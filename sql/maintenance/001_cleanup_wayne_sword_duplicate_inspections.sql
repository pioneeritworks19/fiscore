begin;

create temp table temp_wayne_sword_duplicate_rank as
with ranked as (
    select
        mi.master_inspection_id,
        mi.platform_id,
        mi.source_id,
        mi.source_inspection_key,
        mi.inspection_date,
        sr.source_slug,
        row_number() over (
            partition by mi.platform_id, mi.source_inspection_key
            order by
                case
                    when sr.source_slug like 'sword_mi_wayne_%'
                        and sr.source_slug not in (
                            'sword_mi_wayne_core',
                            'sword_mi_wayne_east',
                            'sword_mi_wayne_south',
                            'sword_mi_wayne_west'
                        ) then 0
                    when sr.source_slug in (
                        'sword_mi_wayne_core',
                        'sword_mi_wayne_east',
                        'sword_mi_wayne_south',
                        'sword_mi_wayne_west'
                    ) then 1
                    when sr.source_slug = 'sword_mi_wayne' then 2
                    else 3
                end,
                mi.created_at,
                mi.master_inspection_id
        ) as precedence_rank,
        first_value(mi.master_inspection_id) over (
            partition by mi.platform_id, mi.source_inspection_key
            order by
                case
                    when sr.source_slug like 'sword_mi_wayne_%'
                        and sr.source_slug not in (
                            'sword_mi_wayne_core',
                            'sword_mi_wayne_east',
                            'sword_mi_wayne_south',
                            'sword_mi_wayne_west'
                        ) then 0
                    when sr.source_slug in (
                        'sword_mi_wayne_core',
                        'sword_mi_wayne_east',
                        'sword_mi_wayne_south',
                        'sword_mi_wayne_west'
                    ) then 1
                    when sr.source_slug = 'sword_mi_wayne' then 2
                    else 3
                end,
                mi.created_at,
                mi.master_inspection_id
        ) as survivor_inspection_id,
        count(*) over (
            partition by mi.platform_id, mi.source_inspection_key
        ) as duplicate_count
    from master.master_inspection mi
    join ops.source_registry sr on sr.source_id = mi.source_id
    join ops.platform_registry pr on pr.platform_id = mi.platform_id
    where pr.platform_slug = 'sword-solutions'
      and sr.source_slug like 'sword_mi_wayne%'
)
select
    master_inspection_id,
    platform_id,
    source_id,
    source_inspection_key,
    inspection_date,
    source_slug,
    precedence_rank,
    survivor_inspection_id
from ranked
where duplicate_count > 1;

create temp table temp_wayne_sword_duplicate_losers as
select *
from temp_wayne_sword_duplicate_rank
where master_inspection_id <> survivor_inspection_id;

create temp table temp_wayne_sword_report_rank as
select
    mir.master_inspection_report_id,
    coalesce(dl.survivor_inspection_id, mir.master_inspection_id) as target_inspection_id,
    mir.report_role,
    row_number() over (
        partition by coalesce(dl.survivor_inspection_id, mir.master_inspection_id), mir.report_role
        order by
            case when mir.master_inspection_id = coalesce(dl.survivor_inspection_id, mir.master_inspection_id) then 0 else 1 end,
            mir.created_at,
            mir.master_inspection_report_id
    ) as keep_rank
from master.master_inspection_report mir
join temp_wayne_sword_duplicate_rank dr
    on dr.master_inspection_id = mir.master_inspection_id
left join temp_wayne_sword_duplicate_losers dl
    on dl.master_inspection_id = mir.master_inspection_id;

delete from master.master_inspection_report mir
using temp_wayne_sword_report_rank rr
where mir.master_inspection_report_id = rr.master_inspection_report_id
  and rr.keep_rank > 1;

update master.master_inspection_report mir
set
    master_inspection_id = dl.survivor_inspection_id,
    source_id = survivor_mi.source_id,
    updated_at = now()
from temp_wayne_sword_duplicate_losers dl
join master.master_inspection survivor_mi
    on survivor_mi.master_inspection_id = dl.survivor_inspection_id
where mir.master_inspection_id = dl.master_inspection_id;

create temp table temp_wayne_sword_finding_rank as
select
    mif.master_inspection_finding_id,
    coalesce(dl.survivor_inspection_id, mif.master_inspection_id) as target_inspection_id,
    mif.source_finding_key,
    row_number() over (
        partition by
            coalesce(dl.survivor_inspection_id, mif.master_inspection_id),
            mif.source_finding_key
        order by
            case when mif.master_inspection_id = coalesce(dl.survivor_inspection_id, mif.master_inspection_id) then 0 else 1 end,
            mif.created_at,
            mif.master_inspection_finding_id
    ) as keep_rank
from master.master_inspection_finding mif
join temp_wayne_sword_duplicate_rank dr
    on dr.master_inspection_id = mif.master_inspection_id
left join temp_wayne_sword_duplicate_losers dl
    on dl.master_inspection_id = mif.master_inspection_id
where mif.source_finding_key is not null;

delete from master.master_inspection_finding mif
using temp_wayne_sword_finding_rank fr
where mif.master_inspection_finding_id = fr.master_inspection_finding_id
  and fr.keep_rank > 1;

update master.master_inspection_finding mif
set
    master_inspection_id = dl.survivor_inspection_id,
    source_id = survivor_mi.source_id,
    updated_at = now()
from temp_wayne_sword_duplicate_losers dl
join master.master_inspection survivor_mi
    on survivor_mi.master_inspection_id = dl.survivor_inspection_id
where mif.master_inspection_id = dl.master_inspection_id;

delete from master.master_inspection mi
using temp_wayne_sword_duplicate_losers dl
where mi.master_inspection_id = dl.master_inspection_id;

commit;
