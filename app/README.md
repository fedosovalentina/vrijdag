# app — Vrijdag Flutter client

iOS first, Android-ready, web later.

**The Flutter project has not been created yet.** This directory holds the agreed folder
structure so that the first `flutter create` lands in the right shape.

## Structure

```text
lib/
  core/         infrastructure — no feature knows why it exists
  shared/       reusable widgets, theme, formatters, extensions
  features/     one folder per feature, each with data / domain / presentation
test/
  unit/         domain logic
  widget/       screen states (loading, empty, quiet, stale, error)
  golden/       visual regression
integration_test/
```

## Layer rules

1. `domain` imports nothing from `data`, `presentation`, or Flutter itself.
2. A feature may not import another feature's `data` or `presentation`.
3. No user-visible string is hardcoded — every string is a localization key with `nl` and `en`.
4. No platform branching outside `core/platform`.

## Getting started (once the project exists)

```bash
supabase start          # from the repository root
supabase db reset       # migrations + seed
flutter pub get
flutter run
```
