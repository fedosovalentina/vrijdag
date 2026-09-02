# app — Vrijdag Flutter client

iOS first, Android buildable but unreleased.

## Run locally

```bash
cd app
flutter pub get
flutter run
```

Requires Flutter stable (see `flutter --version`). Local Supabase comes in a later F-001 phase
(`supabase start` from the repo root).

## Structure

```text
lib/
  main.dart           entry — ProviderScope
  app.dart            root widget
  core/               infrastructure
  shared/             theme, widgets, formatters
  features/           feature-first: data / domain / presentation
test/
  unit/
  widget/
  golden/
```

State management: **Riverpod** only.

## Rules

1. `domain` imports nothing from `data`, `presentation`, or Flutter.
2. A feature may not import another feature's `data` or `presentation`.
3. No user-visible string literals once ARB lands (F-090) — use localization keys.
4. Platform branching only in `core/platform`.
5. Secrets never in the client bundle.

## Current status

**F-001 Phase 1:** project skeleton + Riverpod + bootstrap screen. Auth, Supabase client,
Sentry, PostHog, ARB, and TestFlight upload follow in later F-001 phases.
