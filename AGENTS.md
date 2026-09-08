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
- Current permitted phase: Stage 0.5 only until its completion report is
  accepted. Stage 1 implementation must not start early.

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

## Stage 1 scope after separate approval

The frontend remains limited to Task Tracker, Task Detail, Daily Update, and
Manager Dashboard across Stages 1–3. Stage 1 implements Task Tracker and Task
Detail only. No KPI scoring is permitted in Stage 1.

The generic `work_tasks` domain must not overwrite the existing
marketing-specific `content_tasks` or `content_items` models. Existing work is
preserved until a tested migration or retirement decision is approved.

