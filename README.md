# Vrijdag

> A calendar that knows what the day has to offer.
>
> **Your time × the world around it.**

Vrijdag is a personal calendar that sits your schedule next to the world around it: weather,
seasons, holidays, and small true observations about time. The calendar comes first. Everything
else is additive — and optional.

This repository contains the application source. Detailed product and engineering documentation
is maintained privately by the team.

---

## What Vrijdag is

A reliable calendar, with layers built on top:

1. **Your time** — events, birthdays, recurring dates, openings between commitments.
2. **The world** — weather, sunrise and sunset, public holidays, school holidays, seasons.
3. **Weird Little Things** — small, non-obvious observations that are actually true today.
4. **Memory** — what you chose to mark and revisit. Opt-in, always.

## What Vrijdag is not

- A productivity coach or habit tracker.
- A social network or shared calendar product.
- An app that talks more than it needs to.
- A system that decides on your behalf whether you went somewhere or what belongs in your calendar.

## Principles

These survive every replan.

### Reliability before magic

If a weather strip fails, the day still renders. If your birthday disappears, trust is gone.
Calendar features fail loudly and recover. World-layer features degrade to absence.

### Personal data and world data are separate

Your events, notes, and choices live in a different part of the system from weather, holidays,
and listings. World data can be rebuilt from scratch. Your data must not notice.

### Nothing important is inferred

Attendance, calendar writes, and destructive actions require an explicit gesture from you.
Suggestions are allowed. Silent state changes are not.

### The app may be quiet

"Nothing unusual today" is a finished screen, not an apology. No feature requires content to
exist in order to look complete.

### The world is optional; the calendar is not

A user who grants nothing — no location, no Google, no history — still has a good calendar.

### Say what is true

When data is approximate, stale, or regional, the app says so. "Official school holiday dates
for region Noord", not "Schools are closed."

### Respect your data

- Disconnecting an integration does not delete what it imported. You choose.
- Deleting an event moves it to a holding area for 30 days before permanent removal. You can
  restore it during that time.
- Revoked tokens and failed syncs must never look like data loss.
- Account deletion is the only immediate-removal path, and it is always explicit.

### Privacy by design

- No secrets in the client. Third-party access goes through the server.
- Telemetry defaults differ by region; you can turn reporting off in Settings.
- Analytics carries no event titles, notes, or other personal content.

## Tone

Vrijdag states facts about time. It does not give advice, celebrate your actions, or use
exclamation marks. Dutch and English from day one.

## Technology

| Layer | Choice |
| --- | --- |
| Client | Flutter / Dart, iOS first |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| Languages | Dutch (`nl`) and English (`en`) |

## Repository

```text
app/        Flutter client
supabase/   Database migrations, Edge Functions, seed data
services/   Background workers, added only when a real need appears
tools/      Developer scripts (localization checks, database safety)
```

## Status

Early development. The Flutter project and database migrations are not in this repository yet.

## Contributing

Issues and pull requests are welcome for the open-source parts of the project. For security
concerns, please report privately rather than in a public issue.

This README is the public face of the project. Internal briefs, architecture documents, and
decision logs are not published here.
