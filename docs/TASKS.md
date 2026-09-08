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

## Stage 1 — approved; local implementation only

- [x] Generate an additive local migration for the generic work-management
  foundation.
- [x] Implement RLS/capabilities and behavioural identity matrix.
- [x] Implement Task Tracker and Task Detail only.
- [x] Implement task updates, comments, artifacts, and events foundation.
- [x] Enforce completion evidence or an approved waiver.
- [x] Implement the approved attention flags.
- [ ] Run disposable replay, security matrix, regression, typecheck, lint,
  build, and manual UAT.
- [ ] Produce Stage 1 acceptance and rollback report.

