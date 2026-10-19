# IEOS P0 Implementation Report

Date: 12 October 2026, Asia/Kuala_Lumpur. **Outcome: tested local P0 release candidate; release awaits Director approval.** No hosted database, Vercel configuration or production data was accessed or changed during implementation. No commit, merge, push, deployment, dependency installation or P1–P4 implementation was performed.

## Authority and release baseline

The Director authorised local development and disposable testing, with D1/D4/D8 approved in principle. The historical four audit reports remain unchanged. Current authority is recorded in AGENTS.md, IEOS_MASTER_PLAN.md, EXECUTION_GUARDRAILS.md and TASKS.md; this does not authorise production activation or release.

| Baseline | Verified value |
|---|---|
| Latest worktree | `C:/Users/USER/Documents/Codex/2026-09-07/why-x20/work/ieos-stage5-marketing-leads` |
| Branch | `codex-ieos-stage5-marketing-leads` |
| HEAD before and after implementation | `4431a6564ad3bce58778695e752adf9362952042` |
| Accepted Stage 4 ancestor | `9cdd4ab0fb7e5db9f504dae29d35cc1fc7a9d01c` |
| Local main, origin/main and freshly queried GitHub main | `a353df594e740cf423fda2ee1031b8ae0754e9ab` |
| Branch relationship | 50 commits ahead of origin/main; zero commits behind |
| GitHub reconciliation | Read-only remote-tip comparison; no pull, fetch, reset, rebase, merge or push |
| Push guard | Existing disabled push URL retained |
| Tested source identity | HEAD plus 228-file SHA256 manifest, including dirty/untracked candidate files |
| Test-manifest SHA256 | `744EEB6D830083D00C37ECE252362C95AAEDF55FC4C5225A0514FAAC1CE99424` |

HEAD alone does not identify this candidate: the implementation remains uncommitted. The final harness verified its file manifest had not changed during testing. Only four authority documents and the four requested reports were changed/added after that check; executable source, migrations and tests remained frozen. A local candidate archive and final manifest are retained under the current audit workspace's `work/p0-release-candidate-20261012/`.

## Preservation

Before editing, 218 tracked/untracked source files were copied into `work/p0-preservation-20261012-022102/source/` in the audit workspace. Its source ZIP, SHA256 manifest, Git refs, status, HEAD and tracked patch preserve the existing dirty Stage 5 work. Ignored credentials, runtime environment files, dependencies and build output were excluded. This is a source recovery snapshot, not a production database backup.

Every preserved source path still exists. The pre-existing dirty error boundary and navigation shell remain byte-for-byte unchanged. Existing unfinished lead/campaign work was completed in place. No historical application migrations, recovered staging scripts 001–008 or accepted Stage 1–4 implementation were rewritten. No employee, lead, task, knowledge or other hosted record was deleted, migrated or imported.

## Issues resolved

| Issue | Local change and evidence |
|---|---|
| Unfinished Stage 5 configuration | Completed preserved Lead Campaigns page, form/action and guarded campaign RPC. Company/department consistency is enforced; campaign choices appear in Add/Edit Lead. Dependent department selection resets on company change and successful submission. |
| Accidental four-company activation | Removed activation from the unapplied pending configuration migration. Four active units exist only in disposable synthetic fixtures; the preserved pre-edit snapshot retains the original pending file. |
| Lead time conversion and display | Added strict MYT datetime parsing/formatting in `lib/business-time.ts`; lead forms/actions and date display use Asia/Kuala_Lumpur. Invalid calendar/time values are rejected. DUE TODAY uses the business timezone. No historical timestamps were backfilled. |
| Public app missing recovered approval/edit objects | Added public compatibility migration derived from retained staging 006–008. Restored categories, submission/review/comment RPCs, approval history, edit history and guards in the app's public schema. Public and staging each pass the 35-case approval suite. |
| Multiple application roles | Added one-role-per-profile unique index and atomic Super Admin-only `assign_application_role` RPC. Admin role action validates the enum and uses the RPC. Conflicting pre-existing roles abort preflight; no arbitrary role choice or record deletion occurs. |
| Inactive identities | `getCurrentUser` rejects inactive/missing profiles and missing role assignments before module rendering. Active identity is enforced in legacy database helpers/policies and readiness. Tests also use an inactive account with a valid Auth JWT. |
| Legacy permissive/anonymous RLS | Replaced policies on 20 legacy tables with active, authenticated policies; removed anonymous table access. Profile/grant rows are self-or-Super-Admin only. Scoped task, SOP, campaign, content and linked histories retain permitted access. |
| Unclassified legacy knowledge | Every `knowledge_items` row remains, but access is Super Admin-only because the table lacks company/confidentiality classification. List/create UI explains or enforces this restriction. Classification and broader knowledge permissions require P1 approval. |
| Unscoped SOP/task exposure | Null-department SOPs, legacy tasks and teams default to Super Admin only. Known departments use explicit department grants or the permitted management business-unit grant. |
| Cross-company content leak found in UI | Blank-department content now requires an explicit management grant to its non-null business unit; completely unscoped content is Super Admin-only. SELECT and edit/approval helpers share this rule. Added read/edit negative tests and real HTTP checks. |
| RPC/definer weaknesses | Changed helper/RPC implementations bind subject identity to `auth.uid()`, check activity and use qualified objects with empty search paths. Trigger functions cannot be called directly by app roles. Workflow mutation requires the guarded RPC owner context, not merely a user-set session flag. |
| Workflow races and fabricated approval | Submit/review RPCs lock the content row before checking state. Direct pre-approved inserts and direct workflow transitions are denied. Legacy task submission needs evidence; staff cannot approve/amend; posting needs approval. Activity/work-file actor attribution is enforced in the database. |
| Application access history | Added append-only `application_access_events` with authenticated actor and before/after role/activity values, readable only by Super Admin. No general client insert/update/delete privilege. |
| Liveness mistaken for readiness | Added authenticated `/api/ready` and database readiness RPC. Success means active identity plus key candidate dependencies; unknown/failed dependencies return 503, anonymous/inactive sessions 401. `/api/health` remains liveness. |
| Dormant privileged API entry points | Added active application-user gates to existing Stripe checkout/portal routes. No external calls or configuration changes were made. Missing billing dependencies are still a release limitation. |
| Unsafe/ambiguous test replay | Harness uses explicit forward migrations, excludes legacy rollback files, isolates ports/project, clears hosted variables, refuses runtime .env files and supports an uncommitted candidate through hashes rather than requiring a commit. |
| Recovery verification absent | Added transactional P0 rollback comparison, logical restore with ownership into a separate disposable database, all-table data fingerprints, and security tests on the restored database. |

## Added database changes

The forward public sequence after the preserved Stage 5 migration is:

1. `20260913142730_stage5_lead_form_configuration.sql` — previously uncommitted configuration, completed locally; creates the campaign RPC without activating companies.
2. `20261011182326_p0_public_workflow_compatibility.sql` — public approval/edit compatibility, new approval categories/actions/edit logs and existing workflow guards.
3. `20261011182327_p0_legacy_security.sql` — role uniqueness, access history, active/scoped RLS, guarded legacy workflows and readiness.

`supabase/staging/009_p0_legacy_security.sql` mirrors legacy hardening for disposable regression only. It is not a hosted migration. The app uses public; the historical staging mirror is not a complete Stage 1–5 runtime.

P0 does not replace `work_tasks`, `content_tasks`, `content_items`, daily output, master-file or marketing-lead domains. Existing keys and relationships are retained. New access history adds accountability without rewriting existing attribution.

## Features preserved and verified

Stages 1–5 pass their original behavioural matrices with the completed Stage 5 acceptance extensions: tasks/assignments, sensitivity and evidence, daily outputs and manager review, attention/workload dashboards, master-file lifecycle and restricted metadata, lead scope/PII/duplicates/history/task privacy. Recovered content submission/review/comment/edit flows pass in both schemas. UI checks exercised lead creation/editing, campaign selection, two dated interactions, privacy-safe task creation, staff evidence, supervisor review and routine content approval. Director still sees legacy KB/SOP records; reduced unauthorised access is an intentional P0 security change.

Detailed results and reproducible commands are in `IEOS_P0_TEST_RESULTS.md`. Final disposable harness exit code is 0; 449 primary SQL assertions and 66 restored assertions passed. TypeScript, zero-warning ESLint and production build passed; 17 time tests, 20 HTTP checks and 22 recorded UI scenarios passed. The owned stack and temporary lab were removed. The unrelated FinanceOps container remained running and untouched.

## Remaining limitations

- Hosted schema, migration ledger, data anomalies, owners and deployed version remain unverified in this local-only implementation. A successful clean replay is not proof of safe adoption into a partially migrated hosted database.
- Legacy KB has no classification or immutable approved revision. Super Admin-only access is a containment measure; P1 is needed for staff knowledge retrieval. SOP version text is not an approval/publication system.
- `content_ideas` retains an active management/Super Admin organisation-level workspace because it has no company/confidentiality fields. It must not hold restricted material or be treated as a group-wide scoped repository. Group expansion needs a reviewed classification decision.
- Existing sensitivities and explicit restricted grants in governed Stage 1–5 modules are preserved. The Director must still approve the operational access matrix and appointed personnel before hosted use.
- Inactivation denies IEOS access even with an Auth JWT. Provider bans, global session revocation, Google Drive sharing and wider offboarding require approved operational procedures; no provider configuration was changed.
- Lead time fixes affect new input/display. Historical intended local times cannot be inferred safely and require reviewed data reconciliation if anomalies exist. Other recovered UI timestamps retain their historical display behaviour.
- Readiness checks important dependencies, not every permission or external service. Admin email invitation/magic-link delivery and hosted OAuth were not exercised; no real invitation was sent.
- Dormant billing routes still depend on unverified/missing billing schema/configuration. No finance/CRM/accounting/Drive/AI integration was introduced or activated.
- Legacy task status and its client activity write are not all one transactional RPC. P0 secures actors and transitions; existing atomic task/daily/lead and recovered content RPC workflows remain intact.
- Responsive UAT used Chromium desktop/mobile viewports, not physical-device or multi-browser certification. Local owner-preserving recovery is not a verified hosted Supabase restore procedure.

**Stop condition:** local candidate and reports complete. Await Director acceptance and separately bounded release authorisation. No P1 work has begun.
