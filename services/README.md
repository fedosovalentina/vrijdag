# services — deliberately empty

This directory holds background workers (Render, Cloudflare) **if and when a named problem
requires one**. It is empty on purpose.

The stack starts as:

```text
Flutter → Supabase → Edge Functions
```

Nothing else until a concrete need appears.

## When something belongs here

| Trigger | Likely answer |
| --- | --- |
| An importer exceeds Edge Function execution limits | Render background worker or cron job |
| A scraping pipeline needs a real browser or long-lived state | Render worker |
| We need to cache or shield a public endpoint at the edge | Cloudflare Worker |
| Scheduled work needs finer control than Supabase provides | Cloudflare Cron Triggers |

Before adding a service: confirm the problem is real, document the decision, and keep importer
logic behind the existing interface so deployment changes do not become rewrites.
