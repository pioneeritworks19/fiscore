begin;

create temp table temp_sword_unlinked_restaurant_link_candidates as
with unlinked_restaurants as (
    select mr.master_restaurant_id
    from master.master_restaurant mr
    where not exists (
        select 1
        from master.master_restaurant_source_link mrl
        where mrl.master_restaurant_id = mr.master_restaurant_id
    )
),
sword_inspection_candidates as (
    select
        mr.master_restaurant_id,
        mi.master_inspection_id,
        mi.source_id,
        sr.source_slug,
        mi.inspection_date,
        nullif(trim(pr.payload ->> 'county_name'), '') as county_name,
        nullif(trim(pr.payload #>> '{restaurant,license_number_raw}'), '') as license_number_raw
    from unlinked_restaurants ur
    join master.master_restaurant mr
        on mr.master_restaurant_id = ur.master_restaurant_id
    join master.master_inspection mi
        on mi.master_restaurant_id = mr.master_restaurant_id
    join ops.source_registry sr
        on sr.source_id = mi.source_id
    join ingestion.parse_result pr
        on pr.source_id = mi.source_id
       and pr.record_type = 'inspection'
       and (
            pr.source_record_key = mi.source_inspection_key
            or ('sword-header:' || coalesce(pr.payload ->> 'header_id', '')) = mi.source_inspection_key
       )
    where sr.platform_name = 'Sword Solutions'
),
ranked_candidates as (
    select
        master_restaurant_id,
        source_id,
        source_slug,
        inspection_date,
        county_name,
        license_number_raw,
        county_name || '|' || license_number_raw as source_restaurant_key,
        row_number() over (
            partition by master_restaurant_id, source_id
            order by inspection_date desc, master_inspection_id
        ) as candidate_rank
    from sword_inspection_candidates
    where county_name is not null
      and license_number_raw is not null
)
select
    master_restaurant_id,
    source_id,
    source_slug,
    source_restaurant_key
from ranked_candidates
where candidate_rank = 1;

create temp table temp_sword_unlinked_restaurant_link_inserts as
select
    c.master_restaurant_id,
    c.source_id,
    c.source_slug,
    c.source_restaurant_key
from temp_sword_unlinked_restaurant_link_candidates c
left join master.master_restaurant_source_link existing
    on existing.source_id = c.source_id
   and existing.source_restaurant_key = c.source_restaurant_key
where existing.master_restaurant_source_link_id is null;

-- Preview the repair set before inserting.
select
    source_slug,
    count(*)::int as restaurant_count
from temp_sword_unlinked_restaurant_link_inserts
group by source_slug
order by restaurant_count desc, source_slug;

insert into master.master_restaurant_source_link (
    master_restaurant_id,
    source_id,
    source_restaurant_key,
    match_method,
    match_confidence,
    match_status
)
select
    master_restaurant_id,
    source_id,
    source_restaurant_key,
    'repair_from_existing_inspection',
    1.00,
    'matched'
from temp_sword_unlinked_restaurant_link_inserts;

-- Post-repair verification: remaining unlinked Sword-backed restaurants.
select
    sr.source_slug,
    count(distinct mr.master_restaurant_id)::int as remaining_restaurant_count
from master.master_restaurant mr
join master.master_inspection mi
    on mi.master_restaurant_id = mr.master_restaurant_id
join ops.source_registry sr
    on sr.source_id = mi.source_id
where sr.platform_name = 'Sword Solutions'
  and not exists (
      select 1
      from master.master_restaurant_source_link mrl
      where mrl.master_restaurant_id = mr.master_restaurant_id
  )
group by sr.source_slug
order by remaining_restaurant_count desc, sr.source_slug;

commit;
