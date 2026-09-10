# IEOS — Authoritative Agent Instructions

These instructions supersede the repository's earlier demo-first PRD,
architecture, security, test, deployment, and kickoff instructions wherever
they conflict.

## Current authority and scope

- Work only on the controlled IEOS development branch for
  `ieta-operating-system`.
- Do not modify `expenses-tracker-bankrecon` or Operations Hub.
- The approved product authority is `docs/IEOS_MASTER_PLAN.md`.
- The execution authority is `docs/EXECUTION_GUARDRAILS.md`.
- The current permitted phase is recorded in `docs/TASKS.md`.
- Stages 0, 0.5, and 1 are complete and accepted. Current permitted phase:
  Stage 2 Daily Output Log only, on `codex-ieos-stage2-daily-output`.
- Stop after the Stage 2 completion/UAT report. Stage 3 is not authorised.

## Safety gates

- Never push, merge, deploy, or create a pull request without Claire's
  explicit approval.
- Never run Vercel deployment commands or change Vercel ownership,
  integration, domains, or environment variables.
- Never apply migrations or SQL to hosted Supabase without a separate
  production-change approval.
- Never link a disposable environment to a hosted project.
- Never pull, print, copy, or expose production secret values.
- Never change GitHub ownership/authentication, Supabase ownership, Vercel
  ownership, DNS, or Hermes Telegram.
- Do not reset, discard, delete, or bulk-commit recovered work.

## Development workflow

1. Record branch, HEAD, and working tree before each stage.
2. Preserve unique local work before restructuring it.
3. Work in one bounded stage at a time.
4. Use additive migrations; do not edit an applied baseline migration.
5. Replay migrations in a fresh disposable local Supabase/Postgres environment.
6. Test RLS and actions as authorised, cross-scope, unauthorised, inactive,
   and anonymous identities.
7. Run TypeScript, ESLint, build, and applicable behavioural/regression suites.
8. Produce acceptance and rollback evidence.
9. Stop for Claire's approval before production review or the next stage.

## Product boundaries

- IEOS is the workforce execution and management system: tasks, daily outputs,
  evidence links, manager review, files, content, SOPs, and later bounded
  operational modules.
- Operations Hub remains the transactional system for students, enrolments,
  attendance, assessments, fees, finance, Career & Placement, and related
  records.
- Generic task updates must not contain sensitive personal data. P&C work may
  reference only authorised restricted record IDs or restricted file links.
- Actual passwords must never be stored in IEOS.

## Approved Stage 2 scope

The frontend remains limited to Task Tracker, Task Detail, Daily Update, and
Manager Dashboard across Stages 1–3. Stage 2 activates the deliberately simple,
mobile-first Daily Update workflow only. Stage 3 Manager Dashboard and KPI
scoring remain prohibited.

The generic `work_tasks` domain must not overwrite the existing
marketing-specific `content_tasks` or `content_items` models. Existing work is
preserved until a tested migration or retirement decision is approved.

Daily staff submissions and supervisor review events are append-only. Evidence
for a declared completed deliverable must create or reference a permitted task
artifact. Authenticated identity, not typed names, owns every submission.

