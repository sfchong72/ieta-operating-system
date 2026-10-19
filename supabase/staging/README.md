# ⚠️ STAGING SCHEMA — TEMPORARY VALIDATION ONLY

Everything in this directory is retained as historical recovery/test material.
Under the current guardrails it may run **only in a fresh disposable local
Supabase/Postgres environment**. It must never be executed in a hosted project.

- These scripts are run by the repository's local disposable harness, **not**
  through hosted SQL tools and **not** through a hosted migration ledger.
- Every table here lives under `staging.*` (e.g. `staging.content_tasks`),
  never `public.*`. Postgres schema-qualification is the isolation boundary.
- Test users are fake accounts on the `@staging.ieos.test` domain (`.test` is
  an IANA-reserved, non-routable TLD — these addresses cannot receive real
  mail and cannot collide with anyone's real account).
- All seed data is synthetic and prefixed `TEST —` so it can never be mistaken
  for real IETA content.
- The validated earlier design was re-expressed in additive public migrations.
  Nothing in this directory ships to production as-is.

Do not point any Vercel deployment at this schema. The app defaults to
`public`; `staging` is now local-test-only.
