# ⚠️ STAGING SCHEMA — TEMPORARY VALIDATION ONLY

Everything in this directory targets the **`staging` Postgres schema** inside the
**same** Supabase project as production (`fjtrpoqnheodhfgokrdf` /
`ieta-operating-system`) — it does **not** touch the `public` schema that the
live app reads from.

- These scripts are run ad-hoc via the Supabase MCP `execute_sql` tool, **not**
  through `supabase/migrations/` and **not** through `apply_migration`'s
  migration ledger. They are intentionally excluded from the normal migration
  history because they are disposable.
- Every table here lives under `staging.*` (e.g. `staging.content_tasks`),
  never `public.*`. Postgres schema-qualification is the isolation boundary.
- Test users are fake accounts on the `@staging.ieos.test` domain (`.test` is
  an IANA-reserved, non-routable TLD — these addresses cannot receive real
  mail and cannot collide with anyone's real account).
- All seed data is synthetic and prefixed `TEST —` so it can never be mistaken
  for real IETA content.
- **Once Milestone 2 is approved**, the validated design gets re-expressed as
  a normal `supabase/migrations/0003_*.sql` file targeting `public`, and this
  entire `staging` schema is dropped. Nothing in this directory ships to
  production as-is.

Do not point any Vercel deployment (production or preview) at this schema
without explicitly setting `NEXT_PUBLIC_SUPABASE_SCHEMA=staging` for that
environment only — the app defaults to `public`.
