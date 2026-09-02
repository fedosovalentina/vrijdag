#!/usr/bin/env bash
#
# Database safety checks. These are the mechanism that keeps DEC-009 true after everyone
# has stopped thinking about it.
#
#   1. Every table in the `app` schema has row-level security enabled.
#   2. The `vrijdag_importer` role holds no grants on the `app` schema.
#
# Runs against a throwaway local database with all migrations applied.
# Implemented as part of F-001 (docs/backlog/features/F-001-project-setup.md).
#
# Reference query for check 1:
#
#   select c.relname
#   from pg_class c
#   join pg_namespace n on n.oid = c.relnamespace
#   where n.nspname = 'app' and c.relkind = 'r' and not c.relrowsecurity;
#
# Any row returned is a failure.

set -euo pipefail

echo "check-rls.sh is not implemented yet."
echo "It is part of F-001 — project and environment setup."
echo "See docs/backlog/features/F-001-project-setup.md"
exit 1
