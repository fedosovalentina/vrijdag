-- F-004: personal events (timed / all-day) with RLS.
-- location is free text (no geocoding). deleted_at supports undo / holding.

create type app.event_source as enum ('vrijdag', 'google', 'imported');
create type app.source_of_truth as enum ('vrijdag', 'google');

create table app.personal_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app.users (id) on delete cascade,
  title text not null,
  notes text,
  location text,
  starts_at timestamptz,
  ends_at timestamptz,
  start_date date,
  end_date date,
  timezone text not null default 'Europe/Amsterdam',
  all_day boolean not null default false,
  source app.event_source not null default 'vrijdag',
  source_of_truth app.source_of_truth not null default 'vrijdag',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint personal_events_timed_or_allday check (
    (
      all_day
      and start_date is not null
      and end_date is not null
      and starts_at is null
      and ends_at is null
    )
    or (
      not all_day
      and starts_at is not null
      and ends_at is not null
      and start_date is null
      and end_date is null
    )
  ),
  constraint personal_events_sane_timed check (
    ends_at is null or starts_at is null or ends_at >= starts_at
  ),
  constraint personal_events_sane_allday check (
    end_date is null or start_date is null or end_date >= start_date
  )
);

create index personal_events_user_timed
  on app.personal_events (user_id, starts_at, ends_at)
  where deleted_at is null and not all_day;

create index personal_events_user_allday
  on app.personal_events (user_id, start_date, end_date)
  where deleted_at is null and all_day;

alter table app.personal_events enable row level security;

create policy personal_events_select_own on app.personal_events
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy personal_events_insert_own on app.personal_events
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy personal_events_update_own on app.personal_events
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy personal_events_delete_own on app.personal_events
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

grant select, insert, update, delete on table app.personal_events to authenticated;

create trigger personal_events_set_updated_at
  before update on app.personal_events
  for each row
  execute function app.set_updated_at();
