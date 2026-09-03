-- F-005 / F-006 foundation: recurrence columns + birthdays table.

alter table app.personal_events
  add column if not exists recurrence_rule text,
  add column if not exists recurrence_until date;

comment on column app.personal_events.recurrence_rule is
  'Compact iCalendar RRULE body (FREQ=…); null means non-recurring.';
comment on column app.personal_events.recurrence_until is
  'Optional inclusive end date for recurring series expansion bounds.';

create table if not exists app.birthdays (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app.users (id) on delete cascade,
  name text not null,
  month smallint not null check (month between 1 and 12),
  day smallint not null check (day between 1 and 31),
  year integer check (year is null or year >= 1),
  notes text,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists birthdays_user_md
  on app.birthdays (user_id, month, day)
  where deleted_at is null;

alter table app.birthdays enable row level security;

create policy birthdays_select_own on app.birthdays
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy birthdays_insert_own on app.birthdays
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy birthdays_update_own on app.birthdays
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy birthdays_delete_own on app.birthdays
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

grant select, insert, update, delete on table app.birthdays to authenticated;

create trigger birthdays_set_updated_at
  before update on app.birthdays
  for each row
  execute function app.set_updated_at();
