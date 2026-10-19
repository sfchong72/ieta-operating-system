# Stage 4 Master File Register Completion / UAT Report

Date: 13 September 2026  
Branch: `codex-ieos-stage4-master-files`  
Tested application HEAD: `f69229d074cc171456ed7bc6e7dddd4a14fa8eac`

Stage 4 is complete in the controlled local worktree and is awaiting review.
No Stage 5 functionality was started.

## Delivered scope

- Searchable File Register with current-first ordering and authorised historical
  records.
- File Detail with governed links, metadata, task/artifact relationships,
  replacement/duplicate relationships, and immutable audit history.
- Simple Add File and authorised Edit Metadata workflows.
- File Review / Cleanup view for missing master links, duplicate candidates,
  unresolved replacement anomalies, and stale verification.
- Audited verify, status, supersede, duplicate, access-grant, task-link, and
  task-artifact-link actions.
- Responsive register/detail experience, including a 390 px mobile card layout.

IEOS stores metadata and external links only. It does not copy Google Drive,
Canva, Notion, or other provider content and does not change provider permissions.

## Canonical backend

- `master_file_categories` contains the controlled, configurable category set.
- `master_file_settings` contains the bounded stale-verification threshold.
- `master_files` is the canonical governed register, with human-readable file
  numbers, organisational scope, ownership, access level, lifecycle status,
  provider metadata, relationships, verification timestamps, and indexed search.
- `master_file_access_grants` provides explicit appointed/P&C access.
- `master_file_task_links` and `master_file_artifact_links` preserve the boundary
  between reusable company assets and task-specific evidence.
- `master_file_events` is immutable client-facing audit history whose actor is
  derived from authenticated identity.
- Security-invoker review/search surfaces and authorised RPCs enforce visibility
  before returning filenames, links, relationships, or exception counts.
- Indexes cover business unit, department, category, status, owner, project,
  access level, current records, relationships, and full-text search.

## Security verification

- Director global permitted operational visibility: PASS.
- Scoped Manager business-unit and department visibility: PASS.
- Full-time staff department-scoped visibility: PASS.
- Intern restricted to department-scoped operational records: PASS.
- Intern denial for `full_time_only`, `management_only`, `pc_restricted`, and
  ungranted `appointed_personnel` records: PASS.
- Explicit appointed-personnel grant behaviour: PASS.
- P&C filename, metadata, link, relationship, search, and aggregate leakage
  protection: PASS.
- Cross-department and cross-business-unit denial: PASS.
- Anonymous, inactive, and unauthorised mutation denial: PASS.
- Ownership/access/status changes restricted to authorised actions: PASS.
- Supersede and duplicate actions preserve history and append audit events: PASS.
- Password-reference validation and confirmation controls: PASS.

## Automated acceptance

The clean disposable run exited `0`:

- Public migration replay: PASS, legacy 0001–0004 plus additive Stages 1–4.
- Stage 1 behavioural matrix: PASS, 60/60.
- Stage 2 behavioural matrix: PASS, 35/35.
- Stage 3 dashboard matrix: PASS, 60/60.
- Stage 4 master-file matrix: PASS, 92/92.
- Staging replay 001–008: PASS.
- Supabase database lint at error threshold: PASS.
- Existing approval/edit regression: PASS, 35/35.
- TypeScript: PASS.
- ESLint: PASS with zero warnings.
- Next.js production build: PASS.
- Disposable-stack cleanup without backup: PASS.

The generated harness report is
`outputs/ieos-stage4-uat/ieos-disposable-test-report.md`.

## Manual UAT

- Director File Register, Add File, File Detail, Review / Cleanup, audit history,
  task linkage, provider inference, and verification action: PASS.
- A synthetic local-only current record was created as `MF-000010`; it linked to
  the selected task and recorded the authenticated Director in audit history.
- Verification updated `last_verified_at`, incremented the row version, appended
  a Director audit event, and removed the stale-verification exception: PASS.
- Scoped Manager saw 11 authorised IETA records, including permitted
  full-time/management/appointed records, while the P&C record and foreign-
  business-unit record were absent: PASS.
- Intern 390 px File Register rendered as readable cards and supported opening a
  permitted file detail: PASS.
- Intern UI omitted Add File and Review / Cleanup and showed none of the
  full-time, management, P&C, appointed, or cross-business-unit records: PASS.
- Intern direct access to a P&C file returned the generic Not Found response
  without exposing its filename; direct `/files/new` and `/files/review` access
  redirected to the permitted register: PASS.
- Browser console warnings/errors during final responsive checks: none.

## Known limitations

- External provider availability and sharing permissions are not verified or
  changed by IEOS; source-system access remains independently governed.
- No bulk spreadsheet/CSV import is included. Stage 4 intentionally starts with
  controlled manual registration.
- `project_reference` remains a text reference until a future approved canonical
  Project Register exists.
- Duplicate candidates use governed metadata/link signals, not content hashing or
  semantic comparison of external documents.
- Search is server-side and capped for this initial register; cursor pagination is
  not yet exposed in the UI.
- Categories and stale-verification thresholds are database-configurable, but no
  settings administration screen is included.
- Link health checks and verification remain manual.
- Password-pattern validation is a secondary safeguard, not a substitute for the
  approved password manager and access policy.
- Production rollout, real-user UAT, data migration, training, and monitoring need
  separate approval.

## Safety boundary

- No hosted or production Supabase migration was run.
- No Vercel deployment was run.
- No production environment or secrets were retrieved.
- No infrastructure, DNS, GitHub ownership, or Hermes change was made.
- No Stage 5 or excluded module was started.

See `docs/STAGE4_MASTER_FILE_REGISTER_ROLLBACK.md` for rollback guidance.

