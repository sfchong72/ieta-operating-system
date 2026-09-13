# IEOS Authoritative Staged Product Plan

Status: Stages 0 through 4 accepted; Stage 5 Restricted Marketing Lead Register
is authorised for local implementation and validation only. Stage 6 is not
authorised.

This plan supersedes the repository's earlier demo-first product plan wherever
they conflict. Historical documents remain available for recovery and context.

## Product boundary

IEOS is the internal workforce execution and management system for Inter-Excel.
It will organise work assignments, daily outputs, evidence, review, files,
marketing operations, selected administrative workflows, and management
visibility.

Operations Hub remains the transactional system of record for student,
enrolment, attendance, assessment, fee, finance, Career & Placement, and
related operational data. Product consolidation is a separate future programme.

## Build principles

- Build one controlled stage at a time and stop for acceptance between stages.
- Keep daily use simple for staff and interns.
- A task is not complete without a final output/evidence artifact, unless an
  authorised supervisor records an approved no-artifact reason.
- Do not add KPI scoring in Stage 1.
- Generic task updates must not contain sensitive personal data. P&C matters
  may reference only restricted record IDs or restricted file links.
- Actual passwords are never stored in IEOS.
- Preserve the existing content planner and recovered approval/edit work; do
  not overwrite them with the generic task model.

## Frontend sequence for Stages 1–3

The user-facing foundation has only four destinations:

1. Task Tracker
2. Task Detail
3. Daily Update
4. Manager Dashboard

Stage 1 implements Task Tracker and Task Detail. Stage 2 activates Daily Update.
Stage 3 activates Manager Dashboard. No additional KPI interface is included.

## Approved attention rules

### STUCK

A task is `STUCK` only when all conditions are true:

- daily updates exist on three or more separate working days;
- status is neither `completed` nor `cancelled`; and
- no final output/evidence artifact exists.

Calendar-day age and multiple updates on one day do not satisfy the rule.

### NO UPDATE PREVIOUS WORKDAY

Apply only when status is `in_progress` or `waiting_feedback` and there was no
daily update on the previous working day. Exclude `backlog`, `not_started`,
`blocked`, `on_hold`, `completed`, and `cancelled`.

Working-day calculation must use the configured Inter-Excel business calendar;
until a holiday calendar exists, weekends are excluded and holiday treatment is
recorded as a known limitation.

## Artifact sensitivity

Every task artifact must have `artifact_sensitivity` with one of these values:

- `operational`
- `appointed_personnel`
- `full_time_only`
- `management_only`
- `pc_restricted`

Artifact visibility must be enforced by database policy as well as UI filtering.

## Revised staged roadmap

0. Discovery and technical audit — accepted.
0.5. Governance, preservation, isolation, and controlled workspace — current.
1. Staff & Intern Task Tracker and Task Detail.
2. Daily Output Log.
3. Manager Dashboard.
4. Master File Register.
5. Restricted Marketing Lead Register.
6. Social Media / Content Planner.
7. Design & Artwork Tracker.
8. Admin / Student Affairs.
9. Government / Licensing Tracker.
10. HR Work & Recruitment.
11. SOP Library.
12. Project Register.
13. Restricted P&C Register.
14. Import / Migration Tools.
15. Future enhancements only after the foundation is stable.

## Stage 5 approved technical scope

Stage 5 adds canonical restricted `marketing_leads`, configurable sources,
append-only `lead_interactions`, explicit appointed access, follow-up attention,
duplicate warnings without automatic merge, restricted task references,
immutable audit events, and a simple security-preserving manager summary.
Existing source sheets remain historical/intake references and are not bulk
imported. Lead contact data must never be copied into generic task text.

Minimum role behaviour:

- Director: full operational visibility and management actions.
- Manager: assigned operational scope, task assignment, and review.
- Training Manager/Executive/Staff: capability- and scope-based access.
- Intern: assigned tasks and permitted updates only.
- Viewer: explicitly granted read-only scope.

Role labels alone must not grant access to P&C data. Sensitive access requires
an explicit capability/scope check.

## Definition of done for each implementation stage

- additive database migration;
- RLS/grants and behavioural identity tests;
- bounded UI and form validation;
- filters/search where required;
- synthetic seed/test data only;
- clean disposable replay;
- typecheck, lint, build, regression, and manual UAT checklist;
- known limitations and rollback notes;
- no production deployment or hosted migration without separate approval.

