# Edge Functions

| Function | Auth | Elevated | Purpose |
| --- | --- | --- | --- |
| `delete-account` | user JWT | service role for `auth.admin.deleteUser` only | F-002 account deletion; cascades `app` rows; no `world` writes |

Serve locally:

```bash
supabase functions serve delete-account --env-file .env
```

Deploy when staging exists:

```bash
supabase functions deploy delete-account
```
