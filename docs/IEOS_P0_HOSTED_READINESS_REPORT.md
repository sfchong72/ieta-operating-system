# IEOS P0 Hosted Readiness Report

Inspection date: 12 October 2026, Asia/Kuala_Lumpur. Mode: strictly read-only, except creation of this local report. Inspection completed against the actual IEOS Supabase project and Vercel project. The four existing P0 reports and tested candidate were retained unchanged.

## 1. Executive verdict — BLOCKED

**The existing hosted Content Core release is available, but the tested local P0 candidate is not ready for production adoption.** Supabase is now ACTIVE_HEALTHY, and the current Vercel production deployment is Ready with a successful liveness response. These facts do not establish P0 schema compatibility or operational acceptance.

The release blockers are:

1. **Verified:** none of the eight Stage 1–5/configuration/P0 forward migrations is recorded in the hosted ledger; their 29 new public tables and corresponding operational RPCs are absent.
2. **Verified:** the PostgREST authenticator is configured to expose both public and staging. Hosted staging contains older permissions and audit objects without the tested guards/RPCs. Public-only P0 adoption would leave this second configured API surface unchanged.
3. **Verified:** hosted access has no inactive-profile field, allows broad null-scope content access, exposes caller-unbound definer helpers and retains excessive table privileges. **Verified source limitation:** the candidate legacy migration revokes anon privileges but does not explicitly reset all existing authenticated table privileges. A reviewed grant diff and further local adoption tests are needed.
4. **Blocked:** actual backup/PITR availability, recovery window and a hosted restore rehearsal cannot be verified through the available connector/dashboard session. No backup, export or restore was attempted.
5. **Verified configuration / unverified isolation:** core public Supabase variables apply to All Environments. An isolated preview database/configuration has not been established; a preview must be treated as potentially production-connected.
6. **Blocked pending separate approval:** incremental migration adoption, maintenance window, record/access stewardship, Git release baseline and deployment authority remain unresolved. The local candidate is uncommitted and is not the version deployed by Vercel.

Deploying the P0 frontend against today's hosted schema would deny application access: its getCurrentUser requires profiles.is_active and newer capability dependencies that are absent. Do not push or deploy it first and try to repair the database afterwards.

Classification used throughout:

- **Verified:** directly observed hosted metadata, read-only aggregates, dashboard configuration or identified source.
- **Unverified:** not established by the inspection; no assumption of success or failure.
- **Blocked:** necessary verification/action cannot be completed safely within this authorisation/access.

No database writes, migrations, restore/reactivation, Vercel build/deployment/configuration change, Git mutation, permission/secret/account change, email or notification was performed. No individual record contents, identities or credentials were exported. Only aggregate counts and technical metadata were inspected. No separate Finance/Expenses project was inspected.

## 2. Verified hosted configurations

### Supabase identity and database

| Finding | Classification | Evidence |
|---|---|---|
| Project name / reference | Verified | ieta-operating-system / `fjtrpoqnheodhfgokrdf`; connected list/get-project metadata |
| Current project status | Verified | ACTIVE_HEALTHY. The earlier audit's INACTIVE result is historical; no reactivation was performed by this inspection. |
| Region / engine | Verified | ap-southeast-1; PostgreSQL 17.6; platform release 17.6.1.155 |
| Public schema | Verified | 17 base tables, all with RLS enabled; owner postgres; no forced RLS |
| Hosted staging schema | Verified | 20 base tables, all with RLS enabled; owner postgres; retained recovery/test-era objects |
| Configured Data API schemas | Verified | pg_db_role_setting for authenticator: `pgrst.db_schemas=public, staging` |
| Application roles | Verified | super_admin, management, staff, intern permitted by CHECK; two public assignments, one management and one super_admin; no current multi-role profiles |
| Single-role enforcement | Verified missing | UNIQUE(profile_id, role), not UNIQUE(profile_id); candidate one-role index/RPC absent |
| Inactive-user enforcement | Verified missing | public.profiles has id/email/full_name/created_at only; no is_active. Legacy helpers do not inspect profile activity. |
| Public RPC/helper inventory | Verified | Six legacy functions only; names listed in section 5 |
| Workflow/audit triggers | Verified missing | No non-internal triggers on public or staging application tables |
| Extensions | Verified | pgcrypto 1.3, uuid-ossp 1.1, pg_stat_statements 1.11, plpgsql 1.0, supabase_vault 0.3.1. No Vault contents were inspected. |
| Storage / Edge Functions | Verified | Zero Storage buckets and zero deployed Edge Functions; external source-link assets are separate. |
| Backup/PITR/plan | Blocked / unverified | Connector lacks backup metadata tools; dashboard redirected to sign-in. No plan, backup date, retention or restore entitlement is presumed. |

The live public tables are: activities, business_units, campaigns, content_ideas, content_items, content_tasks, departments, knowledge_items, organisations, platform_publications, profiles, sops, teams, user_business_unit_access, user_department_access, user_role_assignment and work_files.

Hosted staging has those same 17 names plus approval_categories, approval_action and record_edit_log. These additional tables are not equivalent to the tested public approval workflow: the required review/edit RPCs and non-internal guards are absent.

The actual migration ledger contains only:

| Version | Name |
|---|---|
| 20260817144740 | org_business_unit_team |
| 20260828004042 | auth_access_rls |
| 20260828044543 | content_core |

Initial schema objects exist, but an initial-schema entry is not present in this returned ledger. The local 0001–0004 filenames differ from these hosted version identifiers. Do not blindly replay baseline files, run a wildcard migration push or repair the ledger to force a match. An explicit adoption mapping must establish which definitions are already present.

One Inter Excel organisation and four business units exist. **Only IETA is active**, with four departments. IEA, PLC and KALER are inactive and have no departments. This matches a bounded IETA rollout, not approval to activate all four companies.

### Vercel identity and current deployment

| Finding | Classification | Evidence |
|---|---|---|
| Project | Verified | ieta-operating-system; dashboard General confirms `prj_Gwl3Y0JVg75v4HTbLhEUaxJMgiHv` |
| Current production deployment | Verified | `dpl_8ca4wWSHHgD66wvaDX5tdTSrCg1m`; dashboard marks Ready, Production, Current and Latest |
| Deployment time / build duration | Verified | 28 August 2026, 12:48:52 MYT; 32 seconds |
| Deployed commit | Verified | `a353df594e740cf423fda2ee1031b8ae0754e9ab` |
| Repository / production branch | Verified | sfchong72/ieta-operating-system; main; Git connection and Production environment inspected |
| Latest visible deployment | Verified within inspected view | Same Aug 28 deployment; two older visible production deployments also Ready. Deleted/non-visible history and every runtime request were not inspected. |
| Production alias / liveness | Verified | `https://ieta-operating-system.vercel.app`; anonymous GET /api/health returned 200, application/json, status=ok |
| Framework / build settings | Verified | Next.js preset; root directory empty/default root; build/install/output overrides disabled; automatic ignored-build behaviour |
| Current Node setting | Verified | 24.x. Local tested toolchain is Node 24.19.0 / npm 11.17.0. This does not establish the exact historical deployment's Node minor. |
| Lockfile compatibility | Verified source | Both deployed-commit and candidate package-lock.json pin Next 15.5.23. Candidate build passed locally; no hosted candidate build was triggered. |
| Deployment checks / retention | Verified | No deployment checks configured; displayed production/pre-production retention 30 days. Do not assume an old rollback artifact remains indefinitely. |
| Preview boundary | Verified configuration | Preview tracks all unassigned Git branches; no preview custom domain. Production tracks main. |
| CLI access | Blocked for this project | Existing CLI session can see a different team scope; correct IEOS scope was inaccessible. Browser dashboard access succeeded. No login/scope/account/ownership change was made. |

Dashboard sources: [current deployment](https://vercel.com/fongmirandah-5014s-projects/ieta-operating-system/8ca4wWSHHgD66wvaDX5tdTSrCg1m), [project settings](https://vercel.com/fongmirandah-5014s-projects/ieta-operating-system/settings), [Git linkage](https://vercel.com/fongmirandah-5014s-projects/ieta-operating-system/settings/git), [build settings](https://vercel.com/fongmirandah-5014s-projects/ieta-operating-system/settings/build-and-deployment), [environments](https://vercel.com/fongmirandah-5014s-projects/ieta-operating-system/settings/environments). GitHub's current branch/commit/status queries confirm main at the same SHA and the Vercel success link; only main was returned in the branch listing.

### Environment names and completeness

The [project environment-variable view](https://vercel.com/fongmirandah-5014s-projects/ieta-operating-system/settings/environment-variables) shows these four core variables. Secret values and key contents were not revealed. Only the two non-secret URL configurations were compared with the inspected project/production origin, then re-hidden.

| Name | Observed scope/type | Classification / completeness |
|---|---|---|
| NEXT_PUBLIC_SUPABASE_URL | All Environments; Config | Verified present; non-secret URL matches the inspected IEOS project. |
| NEXT_PUBLIC_SUPABASE_ANON_KEY | All Environments; Config | Verified name/scope; contents, validity and project-key pairing unverified. |
| NEXT_PUBLIC_APP_URL | All Environments; Config | Verified present; non-secret URL matches the production origin. Preview callback isolation unverified. |
| SUPABASE_SERVICE_ROLE_KEY | Production only; Secret | Verified name/scope; contents/validity unverified. Server-only Admin invitation use exists in candidate source. Do not copy it to preview. |
| NEXT_PUBLIC_SUPABASE_SCHEMA | Not shown; optional | Verified source defaults to public when absent. Do not configure the historical staging mirror as the P0 runtime. |
| IEOS_LOCAL_UAT | Not shown; local test control | Candidate source additionally rejects local UAT sign-in in production and against non-loopback endpoints. Do not enable hosted synthetic UAT. |
| Stripe variables | Not shown in inspected Project view | Core workforce P0 does not require billing activation. Shared/integration-supplied billing configuration was not established. |

Names alone do not prove correct secret values or Auth redirect/SMTP/provider configuration. These remain unverified; no real magic-link, invitation, OAuth flow or secret validation was attempted.

Conditional billing names in source/.env.example include STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY, NEXT_PUBLIC_STRIPE_PRICE_MONTHLY, NEXT_PUBLIC_STRIPE_PRICE_YEARLY, and optional STRIPE_CONNECT_ACCOUNT_ID / STRIPE_PLATFORM_FEE_PERCENT. Hosted profiles.stripe_customer_id and purchases/subscriptions dependencies are absent from the inspected public schema. Existing checkout/portal/webhook routes are therefore not verified operational capabilities. The build-only Stripe placeholder is not runtime configuration. No billing endpoint or external integration was invoked.

## 3. Local-versus-hosted differences

The tested local candidate remains on codex-ieos-stage5-marketing-leads at HEAD `4431a6564ad3bce58778695e752adf9362952042`, plus preserved uncommitted changes. Its test manifest SHA256 is `744EEB6D830083D00C37ECE252362C95AAEDF55FC4C5225A0514FAAC1CE99424`. The recorded local result is 515 executed SQL assertions, 17 time tests, 20 HTTP checks, 22 UI scenarios, typecheck/lint/build and disposable recovery PASS. Those are local results, not hosted tests.

| Capability | Existing hosted state | Tested local P0 difference | Classification |
|---|---|---|---|
| Organisation/units/departments | One organisation, four units, only IETA active | Reuses hierarchy; explicit grants and one-role model | Verified metadata/source |
| Auth/access | Legacy role/scope helpers; no is_active | Active identity, caller binding, role uniqueness, access history | Verified discrepancy |
| Legacy tasks/SOPs/KB/ideas/files | Tables and old application routes exist | Preserved; hardened access and actor/workflow checks; unclassified KB restricted | Verified structure; hosted functional workflows unverified |
| Content planner/campaign/publications | Eight content items, five publication records; no campaigns | Public recovered approval/edit workflow and scoped campaign management | Verified discrepancy |
| Generic work / evidence | Missing | Stage 1 tasks, updates/comments/artifacts/events/grants | Verified missing |
| Daily outputs / supervisor review | Missing | Stage 2 immutable updates and review history | Verified missing |
| Management operational dashboard | New operational dependencies missing | Stage 3 scoped dashboard/attention RPCs and settings/grants | Verified missing |
| Governed master-file register | Missing | Stage 4 lifecycle, confidentiality, relationships and audit | Verified missing |
| Restricted leads / interactions | Missing | Stage 5 lead capability/scope, history, duplicate warnings, privacy-safe tasks | Verified missing |
| Readiness | Only liveness endpoint observed | Authenticated readiness route/RPC and dependency checks | Verified source/schema difference; no hosted candidate readiness test |
| Training, successor tracking, governed KB revisions, Employee AI | Not established as hosted capabilities | Still outside P0; reuse notes only | No expansion implementation performed |

The eight missing forward files are:

1. 20260908113917_work_management_foundation.sql
2. 20260910101811_stage2_daily_output_log.sql
3. 20260910142301_stage3_manager_dashboard.sql
4. 20260913053937_stage4_master_file_register.sql
5. 20260913073400_stage5_restricted_marketing_leads.sql
6. 20260913142730_stage5_lead_form_configuration.sql
7. 20261011182326_p0_public_workflow_compatibility.sql
8. 20261011182327_p0_legacy_security.sql

Their 29 new public tables are grouped as follows:

- Stage 1: work_tasks, work_task_updates, work_task_comments, work_task_artifacts, work_task_events, work_task_access_grants.
- Stage 2: daily_work_updates, daily_update_reviews.
- Stage 3: work_dashboard_settings, work_dashboard_access_grants.
- Stage 4: master_files, master_file_categories, master_file_settings, master_file_access_grants, master_file_tasks, master_file_artifacts, master_file_events.
- Stage 5: marketing_leads, lead_interactions, marketing_lead_sources, marketing_lead_settings, marketing_lead_access_grants, marketing_lead_access_events, marketing_lead_events, marketing_lead_task_links.
- P0: approval_categories, approval_action, record_edit_log, application_access_events.

New public capability, task/daily/dashboard/file/lead, approval, campaign, role-assignment and readiness RPC families are absent. Important candidate entry points include fn_wm_can_view_dashboard, fn_ml_can_access_module, create_marketing_campaign, assign_application_role, submit_content_item_for_review, review_content_item and ieos_readiness. Their existence in local SQL is not hosted deployment evidence.

Public approval_categories/approval_action/record_edit_log and content_items.approval_category_id are absent, so no same-name public object conflict was observed for that compatibility addition. Staging has objects with those names and different maturity; never merge/copy them into public automatically. Incremental adoption and ownership/constraint/privilege equivalence have not been rehearsed against a hosted-state baseline.

## 4. Database preservation and recovery risks

### Records observed without retrieving their contents

| Public domain | Aggregate count |
|---|---:|
| SOPs / knowledge items | 3 / 3 |
| Legacy ideas / tasks | 5 / 5 |
| Content items / platform publications | 8 / 5 |
| Work files / activities | 4 / 11 |
| Campaigns | 0 |
| Public profiles / Auth users | 2 / 7 |

Existing public IDs, foreign keys, histories and provider links can be retained by an additive adoption design; **preservation is feasible, but not yet proven by a real pre-change backup and incremental restore/migration rehearsal**. No P0 release requires deleting these rows or rebuilding IEOS.

Read-only aggregate checks found:

- No public or staging multi-role profile conflict currently.
- No public profile without an Auth user or without a role.
- Five Auth users lack a public profile: four have staging profiles, one has neither application profile. Their purpose/eligibility was not inspected. Do not auto-provision, merge or delete them.
- No public content/campaign company-department mismatch observed.
- Three public content items are completely unscoped; zero public null-department SOPs/tasks. The P0 default-deny change would withhold those three content items from ordinary management until reviewed, while retaining Director access and every row.
- Hosted staging contains six profiles, eight approval categories, four approval actions, one edit-log entry, three SOPs and eight content items. Its purpose is not proven disposable. Preserve it even if API exposure is later removed.

### Concrete preservation/downtime risks

| Risk | Assessment / release requirement |
|---|---|
| Replaying the existing baseline | Different hosted/local migration versions can cause duplicate objects, repeated data transformations or permissive policy reinstatement. Map existing state before adopting forward changes. |
| Frontend before schema | Candidate activity/capability checks deny users or fail on missing dependencies. Coordinate database and application adoption in a rehearsed window. |
| Old frontend during hardening | Old direct actions/role assignment may conflict with new guards/uniqueness. Rehearse old-app/new-schema compatibility; otherwise approve maintenance/write control for the transition. |
| Staging mistaken for a disposable lab | Removing records or applying local staging fixtures would destroy or overwrite retained hosted history/identities. Neither is authorised or recommended. |
| Preview shares production configuration | A preview with All-Environments production Supabase config can touch live data. Establish an approved isolated target before any preview build/test. |
| Role/activity defaults | Adding is_active defaults existing profiles to true; confirm intended access instead of assuming every retained identity is current staff. Preserve Auth and profile attribution. |
| Locks / partial cutover | New indexes, triggers and constraints require a bounded migration plan, transaction boundaries and maintenance expectations. Duration was not measured on hosted data. |
| Restoring an old point | Writes after the selected recovery point can be lost. Approve write control, RPO/RTO and post-cutover reconciliation before release. |
| Application-only rollback | Does not restore schema/data/security. Do not use legacy permissive RLS rollback or content-table-drop rollback scripts. |
| Deployment retention / operator scope | Confirm a retained compatible rollback target and the correct project/operator access; the current CLI context cannot operate this project. |

### Backup/recovery steps requiring later approval

1. Obtain an authorised read-only view of this project's plan, backup dates/status and PITR earliest/latest restore points. Availability remains unverified, not assumed absent.
2. Approve the backup method, protected retention location, recovery owner, RPO/RTO, write-control window and any cost. A production-data export is separately authorised work; none was created here.
3. Retain the pre-change schema/ledger/grants/functions/owners, application version and external-asset inventory. Preserve public, Auth and hosted staging records; do not copy employee data into ordinary reports.
4. Rehearse supported recovery in an approved separate destination before cutover, checking compatible PostgreSQL/extension/managed ownership and restored permissions/identities/history. Do not recreate another project or restore in place during inspection.
5. Include source documents/provider sharing and configuration outside the database. At inspection there are no Supabase Storage buckets, but Drive/Canva/other source-link assets are not database backup contents.
6. Take/verify the approved pre-change checkpoint and control concurrent writes before the eventual migration. Validate recovery readiness, then proceed only under the separately approved release plan.

Supabase documents daily backups for eligible paid plans, plan-dependent retention, and PITR as an additional recovery option. Database backups exclude Storage binaries; restoring in place makes the project temporarily inaccessible. These are general options, not verification of this project's entitlement. [Database backup documentation](https://supabase.com/docs/guides/platform/backups)

A restored/new project may also need Auth/API/Realtime/Edge Function configuration handled separately. The previous local owner-preserving pg_restore drill does not prove that a hosted customer session can restore managed owners or recover this actual project. [Dashboard restore documentation](https://supabase.com/docs/guides/platform/migrating-within-supabase/dashboard-restore)

The project is active today; no reactivation is needed for this inspection. If it becomes inactive again, stop and obtain Director approval for a specific recovery/resume procedure before taking that action.

## 5. Outstanding security issues

| Issue | Classification / evidence | Required resolution before release |
|---|---|---|
| Staging configured for API exposure | Verified: authenticator db_schemas includes public, staging; anon/authenticated have staging USAGE and table grants | Preferred: retain data and remove staging from API exposure after consumer review and Director approval. Alternative: explicitly harden and test both schemas with a reviewed adoption plan. Do not assume local staging scripts can be applied as-is. |
| Inactive identities not enforced | Verified: is_active absent; helpers do not query profiles | Adopt tested active-identity controls plus reviewed offboarding/provisioning. No account changes now. |
| Arbitrary-subject definer lookup | Verified: six public and six staging helpers allow anon/authenticated EXECUTE; uid/task arguments are not bound to auth.uid | Adopt qualified/caller-bound checks and reviewed grants. Anonymous probing is a metadata/privacy risk; this report does not claim an executed privilege-escalation exploit. |
| Legacy definer search path | Verified: functions are owned by postgres with search_path=public or staging, rather than qualified empty paths | Preserve necessary definer semantics while hardening context and grants; do not bypass security to resolve compatibility errors. |
| Null-scope content / SOP / tasks | Verified: public content SELECT allows any signed-in caller when department_id is null; SOP/task null-scope SELECT lacks authentication guard | Adopt default-deny scoped policies. Current public null SOP/task counts are zero; three unscoped content rows exist and need stewardship. |
| Broad KB / management writes | Verified: knowledge_items allows management/Super Admin without classification; several legacy write/delete policies lack scope | Adopt reviewed scope controls and intentional unclassified-KB restriction. P1 publication/classification is not implemented by this inspection. |
| Unguarded workflow/audit | Verified: no non-internal public/staging triggers; staging approval/edit rows exist without tested RPC/trigger guards | Public compatibility/security plus staging-surface decision; no fake approvals or destructive tests on hosted records. |
| Excess table privileges | Verified: anon and authenticated each have TRUNCATE on all 17 public tables; grants also include REFERENCES/TRIGGER | Reconcile all privileges, not only RLS. No TRUNCATE or other write was attempted. These grants alone do not prove REST offers arbitrary SQL/TRUNCATE. |
| Candidate residual authenticated ACL gap | Verified source: legacy security file lines 152–171 revokes anon but only adds SELECT/INSERT/UPDATE/DELETE to authenticated | Adding grants does not remove pre-existing TRUNCATE/other privileges. Authorise a bounded local follow-up/adoption grant diff and negative privilege tests before accepting hosted application. Published local REST/TAP passes do not certify this additional ACL case. |
| One-role guarantee missing | Verified: UNIQUE(profile_id,role), fn_role uses LIMIT 1 | Adopt one-role index/RPC after reviewed role inventory; zero current conflicts is not enforcement. |
| Password leak protection off | Verified: live Security Advisor warning | Confirm whether password authentication is used; approve an appropriate provider policy or bounded risk treatment. No Auth configuration was changed. |
| Preview/callback isolation | Verified All-Environments public config; isolated target unverified | Preview must use its own approved database/keys/origin and allowed redirects. Never copy the production service-role key to preview. |

Public function names: fn_role, fn_is_super_admin, fn_is_management, fn_has_business_unit_access, fn_has_department_access and fn_task_department. Identically named older helpers also exist in staging. Function metadata shows caller-unbound bodies and no activity checks. App roles cannot CREATE in public, and anon/authenticated cannot log in directly as database roles; those constraints were observed but do not remove the unnecessary grants/callable definer surface.

The live Security Advisor reports six anonymous-callable public definer warnings, six signed-in-callable definer warnings, and disabled leaked-password protection. [Anonymous definer remediation](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable), [signed-in definer guidance](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), [password protection guidance](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

PostgreSQL RLS governs row operations, not whole-table TRUNCATE/REFERENCES privileges; owner/BYPASSRLS execution also needs separate controls. [PostgreSQL 17 row-security documentation](https://www.postgresql.org/docs/17/ddl-rowsecurity.html)

## 6. Proposed release sequence — recommendation only

No step below was executed. Each state-changing stage needs separately bounded authorisation.

1. **Resolve the additional local/adoption gaps:** explicitly reconcile legacy authenticated ACLs; decide hosted staging exposure; prepare an incremental hosted-baseline adoption manifest. Preserve the tested source and all records. No rebuild or P1 features.
2. **Approve identity/access stewardship:** retain IETA-only activation unless separately changed; review two public application profiles, unused/test Auth identities and three unscoped content items. Do not auto-delete/provision/classify records.
3. **Verify backup and rehearsal authority:** establish actual recovery options and approve an isolated destination, protected data handling and rollback/write-control plan. Synthetic-schema rehearsal can remain the starting point; any real-data copy needs explicit approval.
4. **Rehearse adoption and compatibility:** replay a faithful hosted-schema/ledger baseline, apply only the reviewed missing changes, verify preservation and all grants/RLS/RPC/trigger/inactive/approval/evidence paths. Test old-app/new-schema compatibility or confirm maintenance isolation. Repeat affected local gates after any candidate change.
5. **Seal the release baseline under approval:** record exact commit/manifest, review the 50 local commits and uncommitted candidate, and identify the correct existing Vercel project/operator. A commit, push or merge is not authorised by this report. Main is configured for production deployment, so coordinate any later push with the database/release window.
6. **Prepare isolated preview under separate approval:** distinct Supabase target/keys/callback origin and synthetic users; add no production secret to preview. Only then allow a candidate preview build and acceptance. No preview was triggered here.
7. **Approve and execute production cutover:** verify checkpoint/write control, apply the incremental approved database adoption and staging-surface treatment, then release the exact accepted application. Do not replay 0001–0004 blindly or use historical staging fixtures/rollback scripts.
8. **Accept or recover:** verify readiness, real-user permissions, inactive denial and business workflows under approved test arrangements; check retained records/history. Reopen writes only after acceptance. If rollback is needed, follow the approved compatible application/database recovery plan, preserving post-checkpoint writes where required.

Core compatibility metadata is encouraging: existing IDs/hierarchy are reusable, needed public compatibility objects are absent rather than conflicting, current multi-role/scope-mismatch counts are zero, pgcrypto is present, and Next/Node settings align with the local toolchain. These facts reduce adoption uncertainty but do not replace the missing recovery, ACL and incremental compatibility evidence.

## 7. Exact Director decisions and authorisations required

| Decision | Recommended choice / alternative | Approval boundary |
|---|---|---|
| Hosted staging API surface | Retain all rows and remove staging exposure after confirming legitimate consumers. Alternative: retain exposure only with tested complete hardening. | Explicit permission/configuration change; never delete the schema or records. |
| Additional P0 local follow-up and hosted adoption scope | Approve bounded legacy ACL reconciliation, faithful-baseline rehearsal and missing Stage 1–5/P0 adoption planning. | No new features, external integration activation or hosted write implied. |
| Backup/recovery method and accountability | Verify existing plan/restore points, then approve checkpoint method, protected retention, recovery owner, RPO/RTO and rehearsal target. | Separate permission for any production export, new target, restore or paid service. |
| Detailed D1/D4 access and record treatment | Keep only IETA active; nominate stewards for unscoped records and unclassified knowledge; retain identity/history and default denial. | No automatic four-company activation or account/grant changes. |
| Isolated preview and authentication configuration | Approve separate preview database/keys/origin and synthetic verification; review password-policy warning and Auth redirects/SMTP under bounded scope. | Environment/provider changes and preview build need explicit approval. |
| Release identity/operator and Git mechanics | Retain the verified existing IEOS project; appoint an operator with correct project access, accept exact candidate hash/commit and reviewed branch reconciliation. | Commit, push, merge and deployment each require separately clear authority; no ownership transfer is assumed. |
| Cutover and recovery window | Approve migration sequence, maintenance/write control, acceptance owner, abort thresholds and compatible rollback plan. | Exact hosted project and application release must be named; no state-changing inspection step. |
| Dormant billing surface | Keep billing outside this workforce release unless a separate integration scope is approved; decide whether unconfigured routes need containment. | Do not enable Stripe, add finance data/configuration or change the separate Finance system through P0. |

D1/D4/D8 approval in principle does not grant these operational changes. P1–P4 remain outside scope. No project reactivation approval is currently needed because IEOS is active; any later recovery request must be separately assessed.

## Supporting evidence and inspection limits

- Connected Supabase get-project/list-migrations/list-edge-functions/security-advisors responses; all SQL used `BEGIN TRANSACTION READ ONLY`, catalog/aggregate SELECT and COMMIT.
- Catalog inspection: pg_class/pg_namespace, information_schema.columns/role_table_grants, pg_policies, pg_proc, pg_constraint/pg_indexes, pg_trigger, pg_roles, pg_db_role_setting and pg_extension. No secret settings, Vault entries, user identities, document contents or transaction records were selected.
- Vercel browser inspected deployment, General, Git, Build and Deployment, Environments, environment names/scopes and deployment list. No Save, deployment action, build, upgrade, secret reveal or connection-change control was used. Only non-secret URLs were validated; key values remained hidden.
- Production /api/health was inspected anonymously using GET only. It is process liveness and does not test database readiness or permissions.
- Local source/reports/lockfiles and Git refs were read; builds/tests/migrations were not rerun during this inspection. The prior local candidate remains evidence for its own bounded test run.
- Backup/PITR, actual restore entitlement, Auth provider/SMTP/allowlist, key validity, shared/integration-supplied variables, external ACLs and hosted functional write workflows remain Unverified or Blocked as stated above.

**Stop:** report complete. Preserve the current systems and await Director approval before any hosted change or further implementation.
