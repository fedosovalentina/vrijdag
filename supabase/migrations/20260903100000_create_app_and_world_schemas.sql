-- Personal and world schema separation (DEC-009).
-- Creates schemas, importer role, and a canary table with RLS in app.

create schema if not exists app;
create schema if not exists world;

comment on schema app is 'Personal data — RLS required on every table.';
comment on schema world is 'World data — rebuilt from importers; no FK into app.';

-- ---------------------------------------------------------------------------
-- Canary table: proves migrations apply and RLS check passes.
-- ---------------------------------------------------------------------------

create table app.schema_version (
  id int primary key default 1 check (id = 1),
  version int not null default 1,
  updated_at timestamptz not null default now()
);

alter table app.schema_version enable row level security;

create policy schema_version_service_read on app.schema_version
  for select
  to service_role
  using (true);

-- Authenticated users get no access until real policies ship with features.

-- ---------------------------------------------------------------------------
-- Roles and grants
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'vrijdag_importer') then
    create role vrijdag_importer noinherit nologin;
  end if;
end
$$;

grant usage on schema world to vrijdag_importer;
grant usage on schema app to authenticated, anon, service_role;
grant usage on schema world to authenticated, anon;

revoke all on schema app from vrijdag_importer;
revoke all on all tables in schema app from vrijdag_importer;

alter default privileges in schema world
  grant select, insert, update, delete on tables to vrijdag_importer;

-- Expose app schema to PostgREST (Supabase API).
alter role authenticator set pgrst.db_schemas = 'public, app, world';

notify pgrst, 'reload config';
