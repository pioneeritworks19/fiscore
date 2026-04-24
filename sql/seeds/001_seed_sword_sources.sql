insert into ops.source_registry (
    source_slug,
    source_name,
    platform_name,
    jurisdiction_name,
    source_type,
    base_url,
    cadence_type,
    target_freshness_days,
    parser_id,
    parser_version
) values
    ('sword_mi_allegan', 'Sword Solutions - Allegan County', 'Sword Solutions', 'Allegan County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1'),
    ('sword_mi_grand_traverse', 'Sword Solutions - Grand Traverse County', 'Sword Solutions', 'Grand Traverse County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1'),
    ('sword_mi_livingston', 'Sword Solutions - Livingston County', 'Sword Solutions', 'Livingston County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1'),
    ('sword_mi_marquette', 'Sword Solutions - Marquette County', 'Sword Solutions', 'Marquette County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1'),
    ('sword_mi_muskegon', 'Sword Solutions - Muskegon County', 'Sword Solutions', 'Muskegon County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1'),
    ('sword_mi_oakland', 'Sword Solutions - Oakland County', 'Sword Solutions', 'Oakland County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1'),
    ('sword_mi_washtenaw', 'Sword Solutions - Washtenaw County', 'Sword Solutions', 'Washtenaw County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1'),
    ('sword_mi_wayne', 'Sword Solutions - Wayne County', 'Sword Solutions', 'Wayne County, MI', 'html_listing', 'https://swordsolutions.com/inspections/', 'weekly', 7, 'sword', 'sword-v1')
on conflict (source_slug) do update
set
    source_name = excluded.source_name,
    platform_name = excluded.platform_name,
    jurisdiction_name = excluded.jurisdiction_name,
    source_type = excluded.source_type,
    base_url = excluded.base_url,
    cadence_type = excluded.cadence_type,
    target_freshness_days = excluded.target_freshness_days,
    parser_id = excluded.parser_id,
    parser_version = excluded.parser_version,
    updated_at = now();
