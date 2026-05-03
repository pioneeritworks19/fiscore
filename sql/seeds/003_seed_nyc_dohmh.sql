insert into ops.platform_registry (
    platform_slug,
    platform_name,
    base_domain,
    status,
    default_parser_id,
    default_parser_version
) values (
    'nyc-dohmh',
    'NYC DOHMH',
    'data.cityofnewyork.us',
    'active',
    'nyc-dohmh',
    'nyc-dohmh-v1'
)
on conflict (platform_slug) do update
set
    platform_name = excluded.platform_name,
    base_domain = excluded.base_domain,
    status = excluded.status,
    default_parser_id = excluded.default_parser_id,
    default_parser_version = excluded.default_parser_version,
    updated_at = now();

insert into ops.source_registry (
    platform_id,
    source_slug,
    source_name,
    platform_name,
    jurisdiction_name,
    source_type,
    base_url,
    source_config,
    cadence_type,
    target_freshness_days,
    parser_id,
    parser_version,
    status
) values (
    (select platform_id from ops.platform_registry where platform_slug = 'nyc-dohmh'),
    'nyc_dohmh_restaurant_inspections',
    'NYC DOHMH Restaurant Inspection Results',
    'NYC DOHMH',
    'New York City, NY',
    'api_dataset',
    'https://data.cityofnewyork.us/resource/43nn-pn8j.json',
    jsonb_build_object(
        'dataset_id', '43nn-pn8j',
        'metadata_url', 'https://data.cityofnewyork.us/api/views/43nn-pn8j',
        'columns_url', 'https://data.cityofnewyork.us/api/views/43nn-pn8j/columns.json',
        'resource_url', 'https://data.cityofnewyork.us/resource/43nn-pn8j.json',
        'borough_partitions', jsonb_build_array('Bronx', 'Brooklyn', 'Manhattan', 'Queens', 'Staten Island')
    ),
    'daily',
    2,
    'nyc-dohmh',
    'nyc-dohmh-v1',
    'active'
)
on conflict (source_slug) do update
set
    platform_id = excluded.platform_id,
    source_name = excluded.source_name,
    platform_name = excluded.platform_name,
    jurisdiction_name = excluded.jurisdiction_name,
    source_type = excluded.source_type,
    base_url = excluded.base_url,
    source_config = excluded.source_config,
    cadence_type = excluded.cadence_type,
    target_freshness_days = excluded.target_freshness_days,
    parser_id = excluded.parser_id,
    parser_version = excluded.parser_version,
    status = excluded.status,
    updated_at = now();
