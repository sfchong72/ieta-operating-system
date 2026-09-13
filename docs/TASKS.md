# IEOS Controlled Build Tasks

This checklist records phase authority. A checked discovery item is not an
approval to begin the next phase.

## Stage 0 — accepted

- [x] Recover and preserve the original 41-entry working tree.
- [x] Stabilise the recovered approval/edit candidate locally.
- [x] Pass application typecheck, lint, and build.
- [x] Pass disposable staging replay, database lint, and behavioural matrix
  35/35.
- [x] Produce the recovery/stability report.
- [x] Produce the Stage 0 discovery and Stage 1 technical plan.
- [x] Incorporate Claire's sequencing, UI, flag, P&C, and
  artifact-sensitivity amendments.

## Stage 0.5 — complete and accepted

- [x] Preserve the post-stabilisation state: 50 expanded working files, ZIP,
  file tree, Git bundle, and manifest.
- [x] Create controlled local branch `codex-ieos-stage0-5-governance`.
- [x] Install authoritative `AGENTS.md`.
- [x] Add execution guardrails and authoritative roadmap.
- [x] Mark legacy demo-first documents superseded.
- [x] Enable and verify local push protection.
- [x] Verify disposable harness rejects hosted Supabase linkage/connections.
- [x] Split recovered work into reviewable local commits without pushing.
- [x] Re-run existing application and disposable acceptance gates.
- [x] Produce Stage 0.5 completion report.

## Stage 1 — complete and accepted

- [x] Generate an additive local migration for the generic work-management
  foundation.
- [x] Implement RLS/capabilities and behavioural identity matrix.
- [x] Implement Task Tracker and Task Detail only.
- [x] Implement task updates, comments, artifacts, and events foundation.
- [x] Enforce completion evidence or an approved waiver.
- [x] Implement the approved attention flags.
- [x] Run disposable replay, security matrix, regression, typecheck, lint,
  build, and manual UAT.
- [x] Produce Stage 1 acceptance and rollback report.

## Stage 2 — complete and accepted

- [x] Add immutable `daily_work_updates` and append-only
  `daily_update_reviews`.
- [x] Link updates to `work_tasks` and evidence to `task_artifacts`.
- [x] Add atomic `work_tasks.last_activity_at` maintenance.
- [x] Support distinct working-day activity for STUCK detection.
- [x] Implement the simple mobile-first Daily Update UI and supervisor review.
- [x] Run disposable replay, security matrix, regression, typecheck, lint,
  build, desktop/mobile UAT, and cleanup.
- [x] Produce Stage 2 completion/UAT and rollback report.

## Stage 3 — complete and accepted

- [x] Add server-side canonical attention and supervisor-bottleneck summaries.
- [x] Add security-preserving team workload and daily-output summaries.
- [x] Implement Manager Dashboard and enhanced Needs Attention only.
- [x] Add business-unit, department, assignee, project, status, flag, and date filters.
- [x] Verify scoped aggregates reveal no inaccessible rows or counts.
- [x] Run Stage 1/2 regressions, Stage 3 matrix, typecheck, lint, build,
  desktop/mobile UAT, and cleanup.
- [x] Produce Stage 3 completion/UAT and rollback report.

## Stage 4 — complete; awaiting acceptance

- [x] Add canonical `master_files`, configurable categories, scoped access,
  relationships, and immutable audit events.
- [x] Add audited create/edit/supersede/duplicate/verify/archive actions.
- [x] Implement File Register, File Detail, Add File, Edit Metadata, and File
  Review/Cleanup only.
- [x] Add server-side search, filters, current-first ordering, and bounded results.
- [x] Verify restricted metadata and link values cannot leak through rows,
  relationships, search, or aggregates.
- [x] Run Stage 1–3 and approval regressions, Stage 4 behavioural tests,
  typecheck, lint, build, desktop/mobile UAT, and cleanup.
- [x] Produce Stage 4 completion/UAT and rollback report.

