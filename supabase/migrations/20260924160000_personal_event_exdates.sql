-- F-005: dates skipped when a repeating event is expanded.
-- Row-level security is already enabled on app.personal_events.

alter table app.personal_events
  add column if not exists recurrence_exdates date[] not null default '{}';

comment on column app.personal_events.recurrence_exdates is
  'Calendar dates excluded from the series. Editing all events keeps this list.';
