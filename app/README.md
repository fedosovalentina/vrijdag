# app — Vrijdag Flutter client

iOS first, Android buildable but unreleased.

## Run locally

```bash
# From repo root — local Supabase (optional for Phase 4+)
supabase start
supabase db reset

cd app
flutter pub get
flutter run
```

Without `--dart-define`, debug builds default to **local** at
`http://127.0.0.1:54421` (see `supabase/config.toml` — ports are offset from
the CLI defaults so another local Supabase project can keep `54321`).

| Service | Port |
| --- | --- |
| API (Kong) | 54421 |
| Postgres | 54422 |
| Studio | 54423 |
| Mailpit / Inbucket | 54424 |

## Structure

```text
lib/
  main.dart           entry — bootstrap + ProviderScope
  app.dart            root widget
  core/               infrastructure (config, errors, analytics, …)
  shared/             theme, widgets, formatters
  features/           feature-first: data / domain / presentation
test/
  unit/
  widget/
  golden/
```

State management: **Riverpod** only.

## Environments

Environment is selected at **build time** via `--dart-define`. There is no runtime
switch in the UI.

| Environment | `VRIJDAG_ENV` | Supabase | Typical use |
| --- | --- | --- | --- |
| Local | `local` (default) | `supabase start` | development |
| Staging | `staging` | staging project | TestFlight internal |
| Production | `production` | production project | App Store |

### Client-safe dart-defines

These may appear in the app bundle:

| Define | Required | Notes |
| --- | --- | --- |
| `VRIJDAG_ENV` | no | `local` / `staging` / `production` |
| `SUPABASE_URL` | staging/prod | defaults to local stack URL when `local` |
| `SUPABASE_PUBLISHABLE_KEY` | staging/prod | anon key only |
| `SENTRY_DSN` | no | Sentry EU DSN |
| `POSTHOG_API_KEY` | no | PostHog EU project key |
| `POSTHOG_HOST` | no | defaults to `https://eu.i.posthog.com` |
| `APP_VERSION` | no | overrides package version for telemetry |

**Never** pass service role keys, OAuth secrets, or third-party API keys as
dart-defines.

### Example: staging debug run

```bash
flutter run \
  --dart-define=VRIJDAG_ENV=staging \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJ… \
  --dart-define=SENTRY_DSN=https://…@…ingest.de.sentry.io/… \
  --dart-define=POSTHOG_API_KEY=phc_…
```

### Local run with Sentry (AC-4)

Without a **real** `SENTRY_DSN`, the bootstrap screen shows "Sentry not configured"
and hides the test-crash button. README placeholders
(`YOUR_KEY@YOUR_ORG…/PROJECT`) are rejected on purpose.

#### Create an EU Sentry project

1. Open [https://sentry.io/signup/](https://sentry.io/signup/) (or log in).
2. Create / pick an organization. Prefer **EU data residency** when offered
   (DSN host will look like `….ingest.de.sentry.io`).
3. Create a project: platform **Flutter**.
4. Copy the **Client Keys (DSN)** — looks like:
   `https://a1b2c3d4@o123456.ingest.de.sentry.io/7890123`
   (numeric org/project ids, not the words YOUR_ORG / PROJECT).
5. Put it in your local `.env` as `SENTRY_DSN=…` (never commit `.env`).

#### Run with that DSN

```bash
# Preferred: load from .env yourself, or paste the real value once:
flutter run -d <device-id> \
  --dart-define=SENTRY_DSN='https://REAL_KEY@oNNNN.ingest.de.sentry.io/NNNN'
```

On the phone you should see **Sentry ready.** and **Test crash**. After tap,
open Sentry → Issues within a minute: look for `F-001 deliberate test crash`
with release `vrijdag@0.1.0+1` and environment `local`.

Do **not** paste the DSN into chat or commit it.

### Bundle secret check

After a release build, inspect the IPA/APK for forbidden strings:

```bash
# iOS — unpack and grep (example)
unzip -p build/ios/ipa/*.ipa Payload/Runner.app/Frameworks/App.framework/App \
  | strings | grep -E 'service_role|GOOGLE_OAUTH_CLIENT_SECRET' && exit 1 || true
```

## Rules

1. `domain` imports nothing from `data`, `presentation`, or Flutter.
2. A feature may not import another feature's `data` or `presentation`.
3. No user-visible string literals — use ARB / `AppLocalizations`.
4. Platform branching only in `core/platform`.
5. Secrets never in the client bundle.

## TestFlight

See [`tools/upload-testflight.sh`](../tools/upload-testflight.sh) at the repo root.
Requires Xcode signing and App Store Connect credentials via environment variables
(from `.env`, not committed).

## Current status

**F-001:** Flutter skeleton, ARB localization, build-time config, Supabase client,
observability interfaces, CI checks, TestFlight upload script.
