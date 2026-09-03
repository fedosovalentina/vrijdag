#!/usr/bin/env bash
#
# Database safety checks (DEC-009, F-001 AC-6 / AC-7).
#
#   1. Every table in `app` has row-level security enabled.
#   2. `vrijdag_importer` holds no grants on `app`.
#   3. `vrijdag_importer` cannot read or write `app` tables.
#
# Runs against a throwaway local database with all migrations applied.
# Requires: Docker, Supabase CLI. Uses psql inside the db container
# (no host PostgreSQL client required).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "check-rls.sh: Supabase CLI is required."
  echo "Install: https://supabase.com/docs/guides/cli/getting-started"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "check-rls.sh: Docker is required for the local database."
  exit 1
fi

echo "check-rls.sh: applying migrations to local database…"
supabase db reset --local --yes >/dev/null

DB_CONTAINER="supabase_db_vrijdag"
if ! docker inspect "$DB_CONTAINER" >/dev/null 2>&1; then
  echo "check-rls.sh: container $DB_CONTAINER not found. Run supabase start first."
  exit 1
fi

psql_check() {
  docker exec -i "$DB_CONTAINER" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -At "$@"
}

echo "check-rls.sh: (1/3) app tables without RLS…"
UNRLS="$(psql_check -c "
  select c.relname
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'app'
    and c.relkind = 'r'
    and not c.relrowsecurity;
")"

if [[ -n "$UNRLS" ]]; then
  echo "FAIL: app tables without row-level security:"
  echo "$UNRLS"
  exit 1
fi

echo "check-rls.sh: (2/3) importer grants on app schema…"
APP_GRANTS="$(psql_check -c "
  select count(*)
  from information_schema.role_table_grants g
  where g.grantee = 'vrijdag_importer'
    and g.table_schema = 'app';
")"

if [[ "$APP_GRANTS" != "0" ]]; then
  echo "FAIL: vrijdag_importer has grants on app tables ($APP_GRANTS)."
  exit 1
fi

SCHEMA_PRIV="$(psql_check -c "
  select count(*)
  from information_schema.usage_privileges
  where grantee = 'vrijdag_importer'
    and object_schema = 'app';
")"

if [[ "$SCHEMA_PRIV" != "0" ]]; then
  echo "FAIL: vrijdag_importer has usage on app schema."
  exit 1
fi

echo "check-rls.sh: (3/3) importer cannot access app.schema_version…"
if psql_check -c "set role vrijdag_importer; select 1 from app.schema_version;" >/dev/null 2>&1; then
  echo "FAIL: vrijdag_importer can read app.schema_version."
  exit 1
fi

echo "check-rls.sh: all checks passed."
