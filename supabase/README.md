# supabase — database, functions, seed

The authoritative definition of the Vrijdag backend.

## Structure

```text
migrations/   schema changes, applied in filename order
functions/    Edge Functions — everything requiring a secret or a third party
seed/         realistic development data. Never production data.
```

## Migration rules

- Filename: `<utc timestamp>_<verb>_<subject>.sql`, e.g.
  `20260901120000_create_personal_events.sql`.
- One logical change per migration.
- Table creation, indexes, RLS enablement, and policies ship in the same file.
- **Never edit an applied migration.** Add a new one.

## Schema separation

- Personal data lives in the `app` schema. World data lives in `world`. Never mixed.
- Every `app` table has row-level security enabled with policies keyed on `auth.uid()`.
- The `vrijdag_importer` role has grants on `world` only, and none on `app`.
- No foreign keys from `world` into `app`. References from `app` into `world` are plain columns
  that never cascade.

## Edge Functions

Everything that holds a secret. The client never calls a third party directly. Functions pass
the user's JWT through so that RLS still applies.

## Local development

```bash
supabase start      # local Postgres, Auth, Storage, Functions
supabase db reset   # apply all migrations and seed
```

Never point a debug build at production. Never copy production personal data into staging.
