begin;

create temp table temp_sword_orphan_candidates as
with unlinked_restaurants as (
    select mr.master_restaurant_id
    from master.master_restaurant mr
    where not exists (
        select 1
        from master.master_restaurant_source_link mrl
        where mrl.master_restaurant_id = mr.master_restaurant_id
    )
),
sword_identifier_candidates as (
    select distinct
        mr.master_restaurant_id,
        mi.source_id,
        sr.source_slug,
        sr.jurisdiction_name,
        nullif(trim(mri.identifier_value), '') as license_number
    from unlinked_restaurants ur
    join master.master_restaurant mr
        on mr.master_restaurant_id = ur.master_restaurant_id
    join master.master_inspection mi
        on mi.master_restaurant_id = mr.master_restaurant_id
    join ops.source_registry sr
        on sr.source_id = mi.source_id
    join master.master_restaurant_identifier mri
        on mri.master_restaurant_id = mr.master_restaurant_id
       and mri.source_id = mi.source_id
       and mri.identifier_type = 'license_number'
    where sr.platform_name = 'Sword Solutions'
)
select
    master_restaurant_id,
    source_id,
    source_slug,
    jurisdiction_name,
    license_number,
    jurisdiction_name || '|' || license_number as source_restaurant_key
from sword_identifier_candidates
where jurisdiction_name is not null
  and license_number is not null;

create temp table temp_sword_orphan_key_collisions as
select
    source_id,
    source_slug,
    source_restaurant_key,
    count(distinct master_restaurant_id) as restaurant_count
from temp_sword_orphan_candidates
group by source_id, source_slug, source_restaurant_key
having count(distinct master_restaurant_id) > 1;

create temp table temp_sword_orphan_existing_conflicts as
select distinct
    c.source_id,
    c.source_slug,
    c.source_restaurant_key,
    l.master_restaurant_id as linked_master_restaurant_id
from temp_sword_orphan_candidates c
join master.master_restaurant_source_link l
    on l.source_id = c.source_id
   and l.source_restaurant_key = c.source_restaurant_key;

create temp table temp_sword_orphan_safe_inserts as
select
    c.master_restaurant_id,
    c.source_id,
    c.source_slug,
    c.source_restaurant_key
from temp_sword_orphan_candidates c
left join temp_sword_orphan_key_collisions collisions
    on collisions.source_id = c.source_id
   and collisions.source_restaurant_key = c.source_restaurant_key
left join temp_sword_orphan_existing_conflicts existing_conflicts
    on existing_conflicts.source_id = c.source_id
   and existing_conflicts.source_restaurant_key = c.source_restaurant_key
where collisions.source_restaurant_key is null
  and existing_conflicts.source_restaurant_key is null;

-- Preview 1: safe repairs that can be inserted immediately.
select
    source_slug,
    count(*)::int as safe_restaurant_count
from temp_sword_orphan_safe_inserts
group by source_slug
order by safe_restaurant_count desc, source_slug;

-- Preview 2: ambiguous orphan keys shared by multiple restaurants.
select
    source_slug,
    source_restaurant_key,
    restaurant_count::int as ambiguous_restaurant_count
from temp_sword_orphan_key_collisions
order by ambiguous_restaurant_count desc, source_slug, source_restaurant_key;

-- Preview 3: orphan keys that already exist on another linked restaurant.
select
    source_slug,
    source_restaurant_key,
    linked_master_restaurant_id
from temp_sword_orphan_existing_conflicts
order by source_slug, source_restaurant_key, linked_master_restaurant_id;

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
    'repair_from_existing_identifier',
    1.00,
    'matched'
from temp_sword_orphan_safe_inserts;

-- Post-repair verification 1: remaining unlinked Sword-backed restaurants.
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

-- Post-repair verification 2: unresolved orphan keys after the safe insert pass.
with remaining_orphans as (
    select
        c.master_restaurant_id,
        c.source_id,
        c.source_slug,
        c.source_restaurant_key
    from temp_sword_orphan_candidates c
    where not exists (
        select 1
        from master.master_restaurant_source_link mrl
        where mrl.master_restaurant_id = c.master_restaurant_id
          and mrl.source_id = c.source_id
    )
)
select
    source_slug,
    source_restaurant_key,
    count(distinct master_restaurant_id)::int as unresolved_restaurant_count
from remaining_orphans
group by source_slug, source_restaurant_key
order by unresolved_restaurant_count desc, source_slug, source_restaurant_key;

commit;
