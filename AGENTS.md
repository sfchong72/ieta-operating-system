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
- Stages 0 through 4 are complete and accepted. Current permitted phase:
  Stage 5 Restricted Marketing Lead Register only, on
  `codex-ieos-stage5-marketing-leads`.
- Stop after the Stage 5 completion/UAT report. Stage 6 is not authorised.

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

## Approved Stage 5 scope

Stage 5 adds only the Restricted Marketing Lead Register, My Leads, Follow-Up
Due, Lead Detail, simple Manager Summary, append-only interactions, duplicate
warnings, restricted task references, and supporting configuration/audit.
Lead PII, private source URLs, and aggregate counts must remain inaccessible
without explicit Marketing Lead capability and organisational scope.

The generic `work_tasks` domain must not overwrite the existing
marketing-specific `content_tasks` or `content_items` models. Existing work is
preserved until a tested migration or retirement decision is approved.

Existing source sheets remain historical/intake references. Do not bulk-import
historical leads, silently merge duplicates, overwrite interaction history, or
copy contact information into generic work tasks. Stage 6 Social Media / Content
Planner and all later modules remain prohibited.

