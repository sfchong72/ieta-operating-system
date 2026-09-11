# Stage 3 Manager Dashboard Completion / UAT Report

Date: 11 September 2026  
Branch: `codex-ieos-stage3-manager-dashboard`  
Tested HEAD: `d1d3c52851561bb00fc2807e03f03981948def4b`

Stage 3 is complete in the controlled local worktree and is awaiting review.
No Stage 4 functionality was started.

## Delivered scope

- Manager Dashboard with exception-first summary cards.
- Needs Attention ordered by the canonical Stage 1/2 attention rules.
- Team Workload summaries without productivity scores or rankings.
- Daily Output Review with pending-review, completed-deliverable, blocker, and
  missing-update visibility.
- Business-unit, department, staff/intern, project, status, attention-flag, and
  date-range filters.
- Direct navigation from dashboard exceptions to Task Detail and from daily
  summaries to the immutable Daily Update detail/review workflow.
- Responsive Needs Attention cards for narrow/mobile widths.

## Canonical backend

- `work_tasks.status_changed_at` records the start of the current status.
- `work_dashboard_settings` holds the supervisor-review and workload-display
  thresholds in one bounded configuration row.
- `work_dashboard_access_grants` permits explicit dashboard access without
  changing the core role model.
- `work_task_attention` remains the canonical attention source and now provides
  ordered flags, distinct meaningful working-day activity, artifact indicators,
  and supervisor wait duration.
- Security-invoker dashboard views and security-invoker aggregate functions
  perform filtering in Postgres. The browser does not load all history to
  calculate attention states.
- Dashboard indexes cover common status, status-change, completion-artifact,
  work-date, and task filters.

## Security verification

- Director global operational visibility: PASS.
- Scoped manager visibility: PASS.
- Explicitly appointed full-time scoped visibility: PASS.
- Intern dashboard denial and direct-route redirect: PASS.
- Anonymous, inactive, unassigned, cross-department, and cross-business-unit
  denial: PASS.
- Restricted artifact links and identifiers omitted from dashboard summaries:
  PASS.
- P&C task metadata and inaccessible aggregate counts remain hidden: PASS.
- Dashboard-grant inspection remains Director-only, while a grantee may inspect
  only their own grant: PASS.
- Existing Stage 1/2 RLS and append-only audit/review behaviour: PASS.

## Automated acceptance

The final disposable run exited `0`:

- Public migration replay: PASS.
- Stage 1 behavioural matrix: PASS, 60/60.
- Stage 2 behavioural matrix: PASS, 35/35.
- Stage 3 dashboard matrix: PASS, 60/60.
- Staging replay 001–008: PASS.
- Supabase database lint at error threshold: PASS, no schema errors.
- Existing approval/edit regression: PASS, 35/35.
- TypeScript: PASS.
- ESLint with zero warnings: PASS.
- Next.js production build: PASS.
- Disposable-stack cleanup without backup: PASS.

The generated run report is:
`outputs/ieos-stage3-uat/ieos-disposable-test-report.md`.

## Manual UAT

- Manager dashboard loaded with all requested summary sections and scoped
  synthetic data.
- Exception ordering, multi-flag display, activity days, last activity, artifact
  indicator, and Task Detail navigation were verified.
- The STUCK filter returned only matching visible tasks.
- Team workload showed neutral load descriptors and no employee score/ranking.
- Daily Output Review opened an immutable staff submission.
- A synthetic supervisor review was appended successfully; the original staff
  submission remained unchanged.
- Intern navigation omitted Dashboard, Team Tasks, Create Task, and Needs
  Attention. Direct access to `/dashboard` redirected to My Work.
- Needs Attention rendered as readable cards in the narrow responsive browser
  surface (473 CSS px, exercising the same mobile breakpoint used at
  approximately 390 px).

## Known limitations

- Working days currently mean Monday–Friday; Malaysian public holidays and
  company closure days are not yet modelled.
- Supervisor-review and workload thresholds are database-configurable, but no
  Settings UI is included in Stage 3.
- “Missing today” is an exception signal for users with `in_progress` tasks; it
  is not attendance tracking and does not grade staff.
- Workload signals describe active task volume only. They deliberately do not
  measure complexity, hours, quality, productivity, or performance.
- Project filtering uses the Stage 1 free-text project reference until the
  approved Project Register stage introduces canonical project records.
- Dashboard summaries show only artifacts visible under the caller's existing
  artifact RLS. Restricted URLs are never surfaced by the aggregate view.
- Stage 3 remains local and synthetic; production rollout, real-user UAT,
  deployment, monitoring, and operational training require separate approval.

## Safety boundary

- No hosted or production Supabase migration was run.
- No Vercel deployment was run.
- No production secrets or environment were retrieved.
- No DNS, infrastructure, GitHub ownership, or Hermes change was made.
- Stage 4 Master File Register was not started.

See `docs/STAGE3_MANAGER_DASHBOARD_ROLLBACK.md` for rollback guidance.

