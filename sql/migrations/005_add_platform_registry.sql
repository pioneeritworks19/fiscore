create table if not exists ops.platform_registry (
    platform_id uuid primary key default gen_random_uuid(),
    platform_slug text not null unique,
    platform_name text not null,
    base_domain text,
    status text not null default 'active',
    default_parser_id text,
    default_parser_version text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table ops.source_registry
    add column if not exists platform_id uuid references ops.platform_registry(platform_id);

insert into ops.platform_registry (
    platform_slug,
    platform_name,
    base_domain,
    status,
    default_parser_id,
    default_parser_version
)
values (
    'sword-solutions',
    'Sword Solutions',
    'swordsolutions.com',
    'active',
    'sword',
    'sword-v1'
)
on conflict (platform_slug) do update
set
    platform_name = excluded.platform_name,
    base_domain = excluded.base_domain,
    status = excluded.status,
    default_parser_id = excluded.default_parser_id,
    default_parser_version = excluded.default_parser_version,
    updated_at = now();

update ops.source_registry sr
set platform_id = pr.platform_id
from ops.platform_registry pr
where
    pr.platform_slug = 'sword-solutions'
    and sr.platform_id is null
    and sr.platform_name = 'Sword Solutions';
