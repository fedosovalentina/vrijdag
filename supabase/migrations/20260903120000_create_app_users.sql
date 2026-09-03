-- F-002: app.users profile + RLS. school_holiday_region is text until world enum ships (F-033).

create table app.users (
  id uuid primary key references auth.users (id) on delete cascade,
  language text not null default 'nl' check (language in ('nl', 'en')),
  timezone text not null default 'Europe/Amsterdam',
  home_city text,
  home_latitude double precision,
  home_longitude double precision,
  school_holiday_region text,
  location_permission boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table app.users is 'Profile extension of auth.users — personal preferences only.';

alter table app.users enable row level security;

create policy users_select_own on app.users
  for select
  to authenticated
  using (id = (select auth.uid()));

create policy users_insert_own on app.users
  for insert
  to authenticated
  with check (id = (select auth.uid()));

create policy users_update_own on app.users
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- No delete policy for authenticated: account deletion goes through a server path (F-002 Phase D).

grant select, insert, update on table app.users to authenticated;

create or replace function app.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger users_set_updated_at
  before update on app.users
  for each row
  execute function app.set_updated_at();

-- Create profile row when a new auth user appears (magic link / Apple).
create or replace function app.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = app, auth, public
as $$
begin
  insert into app.users (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function app.handle_new_user();
