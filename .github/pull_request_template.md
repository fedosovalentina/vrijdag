# What and why

<!-- One or two sentences. The diff says what changed; say why. -->

## How to verify

<!-- What should a reviewer click? Include the unhappy path. -->

## Checklist

- [ ] Format, analyze, and tests pass; tests added for what changed
- [ ] Diff self-reviewed end to end
- [ ] No hardcoded user-visible strings; `nl` and `en` both present
- [ ] Loading, empty, quiet, stale, offline, and error states handled where relevant
- [ ] No secrets in the client
- [ ] New migration file if schema changed; no applied migration edited
- [ ] RLS enabled with policies for any new `app` table
- [ ] No world-data path can write personal data

## Rollback plan

<!-- Required for anything touching data. What happens to rows written between deploy and rollback? -->

## Notes for the reviewer

<!-- Anything that would otherwise have to be rediscovered. -->
