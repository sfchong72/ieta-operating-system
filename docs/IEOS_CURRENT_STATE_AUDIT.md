# IEOS Current State Audit

**Audit date:** 12 October 2026, Asia/Kuala_Lumpur  
**Mode:** Read-only investigation; documentation only. No implementation authorised.  
**Conclusion:** Extend IEOS. Its local workforce and file-governance foundations are reusable. Its controlled Knowledge Base, SOP publication, training/succession and employee AI capabilities are not yet complete.

## 1. Scope and evidence standard

This audit inspected application source, SQL definitions, local branches/worktrees, commit history, existing test artifacts, non-secret deployment-link metadata and read-only connected-service results. It did not run application builds, SQL tests, migration replay or user workflows: those can write files/data and were outside this audit's strict allowance. Historical test results are identified as historical, not rerun here.

The primary repository is `C:/Users/USER/dev/ieta-operating-system`. Its checked-out governance branch is older than the latest development worktree. The most advanced discovered local checkout, and the location of these four reports, is:

`C:/Users/USER/Documents/Codex/2026-09-07/why-x20/work/ieos-stage5-marketing-leads`

Evidence references below are paths relative to that latest checkout unless prefixed with **T**. **T** means `C:/Users/USER/Documents/Codex/2026-09-07/why-x20/outputs`. This distinction matters: the September-named directory contains commits from 13 September; directory dates are not release dates.

| Status | Meaning used in this audit |
|---|---|
| Implemented and tested | Source exists and an identifiable historical local test artifact demonstrates the bounded capability. Does not mean deployed, production-tested or that the current dirty checkout passed. |
| Implemented but not fully tested | Source exists; end-to-end acceptance, current-version coverage or operational verification is incomplete. |
| Partially implemented | Some required components exist, but the intended functional capability remains incomplete. |
| Designed only | Plans exist without the required implementation. |
| Not implemented | No relevant implementation found in the inspected source/schema. |
| Cannot verify | Required live evidence is unavailable. |

Every local capability below has **current hosted availability: Cannot verify**. No feature is labelled deployed on the basis of source code.

## 2. Git, local and deployment differences

| Surface | Verified state | Implication |
|---|---|---|
| GitHub `main` | `a353df594e740cf423fda2ee1031b8ae0754e9ab`, 28 August 2026, Content Core/auth fixes. GitHub branch listing returned only `main`, unprotected. | The later local branches were not present in the returned remote branch list. No branch-protection policy should be assumed. |
| Primary local checkout | Clean before audit; `codex-ieos-stage0-5-governance`, `5f1bc43506d0e8f72af2c1d684ae7a819d4d72cc`. | Opening the primary folder alone misses later work. |
| Stage 1 | `codex-ieos-stage1-task-tracker`, `fe20311f059b0e3f06223420147f9f81f9741daf`. | Generic task execution foundation. |
| Stage 2 | `codex-ieos-stage2-daily-output`, `8bd11bd24b9637c762ce5a24f39d51405abe32e4`. | Daily output and reviews. |
| Stage 3 | `codex-ieos-stage3-manager-dashboard`, `0364539201cce7756d30e0fded23349d276a2f17`. | Scoped operational summaries. |
| Stage 4 | `codex-ieos-stage4-master-files`, `9cdd4ab0fb7e5db9f504dae29d35cc1fc7a9d01c`. | Governed external-link register. |
| Latest Stage 5 | `codex-ieos-stage5-marketing-leads`, `4431a6564ad3bce58778695e752adf9362952042`, 13 September 2026. | 50 commits ahead of local `main`; committed difference: 153 files, 12,188 insertions, 412 deletions. |
| Latest working tree | Seven modified tracked files and three untracked entries before audit. | Uncommitted lead forms/actions, error/navigation changes, test changes, campaign UI and a migration are additional to HEAD. |
| Historical Vercel status | GitHub reports successful Vercel deployment for remote `main`; zero GitHub check runs returned for that commit. | Evidence of a completed historical deployment, not current runtime/database health or feature acceptance. |
| Local Vercel link | Primary checkout has ignored `.vercel/project.json` naming `ieta-operating-system`. | Historical linkage only. No deployment command or live configuration change was made. |
| Hosted Supabase | Connector lists `ieta-operating-system` as `INACTIVE`; migration listing failed with connection timeout. Security advisor returned an empty lint list. | Live schema, grants, RLS, storage, backups and runtime cannot be verified. Empty advisors on an unavailable database do not establish security. |

Remote evidence: [GitHub branches](https://github.com/sfchong72/ieta-operating-system/branches), [remote main commit](https://github.com/sfchong72/ieta-operating-system/commit/a353df594e740cf423fda2ee1031b8ae0754e9ab), [historical Vercel deployment](https://vercel.com/fongmirandah-5014s-projects/ieta-operating-system/8ca4wWSHHgD66wvaDX5tdTSrCg1m). Status and branch information were read through the connected GitHub API; no fetch/pull altered local refs.

Pre-existing uncommitted paths:

- `app/(app)/error.tsx`
- `components/marketing-leads/lead-actions.tsx`
- `components/marketing-leads/lead-form.tsx`
- `components/nav-shell.tsx`
- `lib/actions/marketing-leads.ts`
- `supabase/tests/stage5_marketing_lead_behavioural.sql`
- `supabase/tests/support/stage5_marketing_lead_fixtures.sql`
- `app/(app)/leads/campaigns/` (untracked entry)
- `components/marketing-leads/campaign-manager.tsx` (untracked)
- `supabase/migrations/20260913142730_stage5_lead_form_configuration.sql` (untracked)

The untracked migration activates IETA, IEA, PLC and KALER business units and adds a scoped campaign-creation RPC. It is **not** listed in the disposable harness's `$PublicScripts` replay list. Its presence is not evidence that company-wide activation or campaign configuration has been applied or tested.

## 3. Feature maturity

| Requested feature | Local status | Verified implementation and technical evidence | Limitations / deployment distinction |
|---|---|---|---|
| 1. Organisation, business units, departments | Partially implemented | `0002_org_business_unit_team.sql:5` defines organisation → business unit → department → team. Seed defines IETA, IEA, PLC, KALER; Stages 1–4 test cross-scope denial. | Original seed activates only IETA and backfills existing departments to IETA. Group-wide organisation maintenance, cross-company job roles and operational rollout not demonstrated. |
| 2. Authentication, roles, permissions | Implemented but not fully tested | Supabase SSR sessions, `auth.getUser()`, authenticated app layout, admin invitation action and scoped grants; `lib/data/access.ts`, `lib/actions/admin.ts`, `0003_auth_access_rls.sql`. New domains have historical negative-identity tests. | One-role assumption conflicts with database allowing multiple roles; inactive-user handling differs between legacy/new domains. Hosted auth, invitations, redirect settings and real-user access unverified. |
| 3. Task management and assignment | Implemented and tested | Generic `work_tasks`, assignee UUIDs, status/progress, blockers, comments, artifacts, supervisor actions, waivers and task events. `20260908113917_work_management_foundation.sql:14`; `app/(app)/work`; Stage 1 60/60 plus local UI acceptance. | Independent from legacy `content_tasks`. Free-text project reference; no pinned SOP revision or required evidence checklist. Current dirty build not retested. |
| 4. Daily output logging | Implemented and tested | Immutable `daily_work_updates`, append-only `daily_update_reviews`, evidence validation, activity updates; `20260910101811_stage2_daily_output_log.sql:9`; `lib/actions/daily-output.ts`; Stage 2 35/35 and local UI evidence. | Operational output, not attendance/payroll, training or competency. No live operational validation. |
| 5. Management dashboards | Implemented and tested | Exception flags, team workload, daily-output review, scoped aggregate RPCs/security-invoker views; `20260910142301_stage3_manager_dashboard.sql`; `app/(app)/dashboard/page.tsx`; Stage 3 60/60 and local UI evidence. | Weekdays only, no holiday calendar; workload is task volume, not performance scoring. No succession-risk dashboard. |
| 6. Task approval and evidence review | Partially implemented | Generic task supervision/final approval and evidence-or-waiver controls tested in Stage 1. Content review RPCs, approval actions and edit guards tested in local `staging` regression. | Evidence is primarily links; completion is not automatically proof that a supervisor assessed competency. Content review backend exists in staging scripts, without corresponding public release migration. No SOP publication workflow. |
| 7. Recurring task management | Not implemented | Search of app/lib/schema found no recurring schedules, occurrence generation or scheduler integration. | Manual repeated tasks are possible; not equivalent to recurrence. Future design must handle missed runs, timezone and duplicates. |
| 8. Marketing/content management | Implemented but not fully tested | Legacy ideas/tasks, campaigns, content items, platform publications and planner; local restricted leads/interactions/follow-up and scoped summaries in Stage 5. `0004_content_core.sql`, `20260913073400_stage5_restricted_marketing_leads.sql`, `app/(app)/planner`, `app/(app)/leads`. | Lead matrix passed on an earlier revision; UI acceptance timed out. Latest forms/campaign migration are dirty and not covered. No verified CRM sync or social auto-publishing. |
| 9. Knowledge Base | Partially implemented | `knowledge_items` title/category/body/tags; list/create/edit/delete forms and actions, detail page requests edit history. `0001_init.sql:67`; `components/knowledge-form.tsx`; `lib/data/knowledge-items.ts`. | Management-only RLS in baseline; no company/department scope, owner/reviewer, approval, effective dates or immutable revision. Detail history table exists only in staging definitions. |
| 10. SOP module | Partially implemented | `sops` title/department/Drive link/free-text version/content/creator; CRUD and detail UI. `0001_init.sql:9`; `components/sop-form.tsx`; `lib/actions/sops.ts`. | Mutable version label; no controlled publication, retained content revisions, backup owner, training or SOP-task requirement. Scoped staff can edit; null-department access needs hardening. |
| 11. Audit trails/activity history | Partially implemented | New task/file/lead domains have authenticated, append-only event mechanisms; daily reviews retained. Staging `approval_action` and `record_edit_log` with tamper guards. | Legacy history differs in maturity; generic edit log records changed field names, not prior content. It cannot reconstruct approved revisions. Public/staging parity and system-wide access-change/retention policy unresolved. |
| 12. File/document storage and access | Partially implemented | Stage 4 `master_files` metadata/link governance, owners, confidentiality, lifecycle, replacements, task/evidence relations, search and audit; 92/92 plus local UI acceptance. | This is a link register, not document binary storage or a Drive ACL synchroniser. No storage bucket/policy implementation found. External sharing, deleted links and exact source content versions remain independent. |
| 13. Supabase security/RLS | Partially implemented | Baseline replaces permissive policies; new domains use active-user/scope/capability checks, guarded RPCs, least-privilege grants and security-invoker views. Historical local security matrices exist. | Legacy gaps and schema split remain; hosted policies/grants/exposed schemas/storage configuration cannot be verified. No production security certification follows from local tests. |
| 14. Existing AI-agent integration | Partially implemented | `lib/ai/rules.ts` contains URL classification, platform keyword matching, priority/tag suggestions. Comment explicitly says no external AI calls. Agent/intelligence plans exist. | Rule-based assistance only. No LLM SDK, retrieval pipeline, approved-source citations, AI chat endpoint, embedding index or verified external agent connection found. Employee AI assistant is designed only at the roadmap level. |

## 4. Existing schema inventory

This is an inventory of **local DDL**, not a live database inventory. Tables in public migrations are intended for `public`; their hosted existence is unverified. Staging mirror copies of the first 17 tables are not additional business domains.

| Domain | Existing local tables | Definition / purpose |
|---|---|---|
| Initial operational/knowledge | `departments`, `sops`, `content_ideas`, `content_tasks`, `work_files`, `knowledge_items`, `activities` | `0001_init.sql`: legacy workflow, knowledge and external task links. |
| Organisation | `organisations`, `business_units`, `teams` | `0002_org_business_unit_team.sql`; adds department business-unit FK. |
| Identity/access | `profiles`, `user_role_assignment`, `user_business_unit_access`, `user_department_access` | `0003_auth_access_rls.sql`; Stage 1 adds profile `is_active`. |
| Content core | `campaigns`, `content_items`, `platform_publications` | `0004_content_core.sql`; separate from generic work tasks. |
| Generic work | `work_tasks`, `work_task_updates`, `work_task_comments`, `work_task_artifacts`, `work_task_access_grants`, `work_task_events` | Stage 1 additive migration. |
| Daily outputs | `daily_work_updates`, `daily_update_reviews` | Stage 2 additive migration. |
| Dashboard configuration | `work_dashboard_settings`, `work_dashboard_access_grants` | Stage 3 additive migration; summaries also use views/functions. |
| Master files | `master_file_categories`, `master_file_settings`, `master_files`, `master_file_access_grants`, `master_file_tasks`, `master_file_artifacts`, `master_file_events` | Stage 4 additive migration. Actual join-table names end in `tasks`/`artifacts`; earlier prose sometimes calls them “links.” |
| Restricted leads | `marketing_lead_sources`, `marketing_lead_settings`, `marketing_lead_access_grants`, `marketing_leads`, `lead_interactions`, `marketing_lead_task_links`, `marketing_lead_events`, `marketing_lead_access_events` | Stage 5 additive migration. |
| Staging-only extensions | `staging.approval_categories`, `staging.approval_action`, `staging.record_edit_log` | `supabase/staging/006_approval_workflow.sql`, `007_edit_support.sql`, `008_approval_security_hardening.sql`. |

**42 public table definitions plus three staging-only extension tables** were identified. Managed `auth`/`storage` internals are not counted. No training/competency/succession/knowledge-revision/recurrence tables were found.

Migration set: four legacy forward scripts `0001`–`0004`; five committed additive Stage 1–5 migrations; one untracked lead-configuration migration. Rollback scripts sit alongside forward scripts. Staging has scripts `001`–`008`. The harness explicitly selects scripts; its successful replay does not validate a standard CLI deployment that discovers files differently. No checked-in `supabase/config.toml`, `vercel.json` or GitHub workflow was found in the inspected source inventory.

## 5. Knowledge Base/SOP functional details

**Knowledge Base:** category and tags are free text. List queries return all permitted rows ordered by creation time; no approved/effective filter exists. Creation input does not include `user_id`, so the existing creator column is not reliable ownership attribution for new knowledge entries. Baseline `knowledge_items_all` restricts all operations to Management/Super Admin, preventing ordinary employees from using it as their knowledge library.

**SOP:** department provides indirect business-unit classification. `user_id` identifies drafter/creator, not an accountable process owner/reviewer. `version` is editable text, defaulting to `v1`; editing overwrites the same content row. Optional Drive URL validation accepts a URL generally and does not verify Drive ownership, content, availability or safe scheme. Forms have no trained backup, effective date, review cycle, authority, approval or evidence requirement configuration.

Both modules have direct delete actions. Their current detail pages unconditionally query `record_edit_log`. That table and generic edit triggers are defined in the staging extension, while `lib/supabase/server.ts` defaults to `public`. A public-only replay therefore does not supply all dependencies used by those pages. Selecting staging globally is not a general fix: new workforce/file/lead migrations are explicitly public. This is a source-level compatibility finding; the inactive hosted system was not exercised.

`master_files` is substantially stronger: business-unit/department scope, owner, access level, lifecycle states, verification dates, supersession/duplicate relations, search and audit already exist. However, `current` and `last_verified_at` signify file-register governance, not a reviewed SOP content release. `row_version` is a concurrency counter, not an approved document revision.

## 6. Priority technical findings

| ID | Severity / stage | Evidence and finding | Required future treatment |
|---|---|---|---|
| F01 | High / P0 | Hosted project inactive; migration request timed out. Historical Vercel success does not show current application health. `app/api/health/route.ts` returns “ok” without checking database/auth/schema. | Establish authorised operational recovery and release baseline; add meaningful readiness checks in a separately approved implementation. |
| F02 | High / P0 | Public/staging compatibility split: review/edit-history dependencies are staging-only, while new workforce domains are public and session lookup requires new RPCs. | Produce one forward release plan for the selected application version, preserving legacy records; test all routes against its target schema. |
| F03 | High / P0 | `0003_auth_access_rls.sql:122` allows SOP reads when `department_id is null` without an explicit signed-in predicate or `TO authenticated`. Legacy functions are security-definer with public search path and no baseline EXECUTE revocations found. | Verify effective grants first; test anon/direct API reads and RPC probing. Harden legacy policies/functions consistently. Potential exposure is conditional on grants/schema exposure; live exploitation was not verified. |
| F04 | High / P0 | `user_role_assignment` allows multiple roles per profile; baseline `fn_role` selects an arbitrary first row, app `maybeSingle()` expects one, new `fn_wm_role_of` accepts exactly one. Admin upsert can add another role rather than replace it. | Decide/enforce one application authorization role per person, with explicit scope/capability grants. Audit existing assignments before any constraint change. |
| F05 | High / P0 | New domains check active profiles; legacy SOP/knowledge policies do not. `getCurrentUser()` obtains profile without rejecting `is_active=false`. | Make offboarding effective across every module, sessions and linked provider access; add negative tests for inactive identities on legacy routes. |
| F06 | High / P1 | Direct edits/deletes and no immutable approved revisions in KB/SOP. `record_edit_log` stores changed field names, not old bodies. | Add approval/revision lifecycle, retirement and task-pinned revision links. Existing edit history is useful audit context, not version recovery. |
| F07 | High / P1 | File register controls metadata/link visibility; Drive access remains independent. | Align provider ACLs, retain exact approved content snapshots, test access revocation and avoid mutable source links as the sole evidence of a historical release. |
| F08 | Medium / P0 | Dirty Stage 5 work and missing harness replay of `20260913142730...`; earlier UI acceptance timed out. | Review all pending changes, cover intended migration set and complete current-version UI/security acceptance before release. |
| F09 | Medium / P0 | Mixed migration naming/rollback scripts; app release depends on matching RPCs. Header comments and older docs are inconsistent with SQL/current phase. | Use a reviewed release manifest and migration ledger; document rollback/restore. Do not apply every SQL file blindly. |
| F10 | Medium / P0–P2 | Holiday calendar, admin configuration UI, pagination and canonical project references remain incomplete. | Address operational needs incrementally; use a controlled calendar and simple role/job requirements, without staff scoring. |
| F11 | Medium / P0 | Starter Stripe routes use profile fields such as `stripe_customer_id` absent from inspected profile DDL; business-purpose/operation unverified. | Inventory dormant API surface and its owners; explicitly retain or disable after approval. It is not evidence of Finance/SQL Accounting integration. |

Positive controls worth preserving: server-only admin client; invitation action independently checks Super Admin; ordinary data calls use user-session/RLS; new workflow mutations use guarded RPCs; new aggregate views use security-invoker; new domains revoke direct writes and retain event history.

Security conclusions are based on actual SQL, not comments alone. Supabase documents that table grants and row policies are separate controls, and storage access has its own policies: [RLS guidance](https://supabase.com/docs/guides/database/postgres/row-level-security), [Storage access control](https://supabase.com/docs/guides/storage/security/access-control). These principles inform the proposed checks; no configuration was changed.

## 7. Historical test evidence and its limits

| Artifact | Recorded tested revision / result | Audit interpretation |
|---|---|---|
| **T** `ieos-stage1-uat/ieos-disposable-test-report.md` | `fe20311...`; exit 0; task matrix 60/60, staging regression 35/35, desktop/mobile PASS. | Bounded synthetic local task acceptance. |
| **T** `ieos-stage2-uat/ieos-disposable-test-report.md` | `463d69a...`; exit 0; Stage 1 60/60, Stage 2 35/35, regression 35/35, UI PASS. | Evidence predates current Stage 2 branch tip; no claim of identical-version acceptance. |
| **T** `ieos-stage3-uat/ieos-disposable-test-report.md` | `d1d3c52...`; exit 0; Stages 1/2/3 = 60/35/60; UI PASS. | Stage 3 feature evidence; completion-report commit differs from tested code revision. |
| **T** `ieos-stage4-uat/ieos-disposable-test-report.md` | `f69229d...`; exit 0; Stage 4 92/92; prior matrices and UI PASS. | Strongest file-register evidence. `docs/STAGE4_MASTER_FILE_REGISTER_UAT.md` also records typecheck/lint/build PASS. |
| **T** `ieos-stage5-automated/ieos-disposable-test-report.md` | `ca24f05...`; exit 1 at Docker setup; suites NOT RUN. | Failed run; cannot count as acceptance. |
| **T** `ieos-stage5-uat/ieos-disposable-test-report.md` | `714b025...`; Stage 5 60/60 and prior matrices passed; overall exit 1 because UI PASS was not confirmed before timeout. | Database evidence exists; full Stage 5 acceptance incomplete, and later commits/dirty changes uncovered. |

Checked items in `docs/TASKS.md` are workflow records, not independently verified Director approvals. Stage 1/2 UAT files are checklists; the generated **T** results establish completion. Stage 3/4 reports provide additional outcomes. No fresh test or live-user acceptance was performed here.

## 8. External integration boundaries

| System | Current evidence/status | Future boundary |
|---|---|---|
| GoHighLevel CRM | Not implemented in inspected IEOS source. Restricted lead register is internal, not CRM sync. | CRM owns contact/pipeline records; IEOS uses scoped external IDs, follow-up tasks and approved operational summaries. Verify duplicate ownership and field mapping before sync. |
| Existing Finance/Vercel App | Cannot verify external application's contracts; no IEOS connector found. Separate local Finance directories exist and were not modified or audited as IEOS. | Finance retains financial transactions/reconciliation. IEOS references authorised status/record IDs; no duplicate accounting ledger. |
| SQL Accounting | No IEOS connector found; vendor edition/API/access unverified. | Accounting owns postings; begin with validated read-only reports or controlled exports, subject to licensing/technical discovery. Never assume direct database write integration. |
| Google Drive | External URLs/provider detection implemented; API content ingestion, ACL sync and exact revision capture not found. | Source authoring/storage plus IEOS register, approved snapshots and permission-aware retrieval. |
| ChatGPT Plugins/Custom GPTs | No IEOS plugin/MCP/action endpoint or content ingestion found. | Future authenticated connector to the same IEOS knowledge service. Review approved source files/instructions before import. |
| Existing AI agents | Keyword rules implemented locally. External agents not inventoried or connected in inspected IEOS. | Bounded authenticated tools, separate service identity and human approval for writes; no authority to modify published knowledge. |

These are boundaries for future work, not claims that the external systems have been technically certified.

## 9. What to preserve and what remains unknown

Reuse the Next.js/Supabase application, organisation/access model, generic tasks, daily outputs, supervisor actions, scoped dashboards and Stage 4 file register. Preserve the independent content domain and existing data. Add governance/training/retrieval incrementally; a rebuild is not recommended.

Unknowns requiring later authorised verification include hosted migration ledger/effective grants, current deployed commit and domain, real user roles, production data quality, Drive sharing/ownership, storage buckets, MFA/session policy, backups and restore success, operational monitoring, external contracts and the approved document corpus. No personal records or credentials were copied into these reports.

Only the four requested Markdown reports were created. No code, application data, dependencies, configuration, branches or commits were changed. Implementation must await Director approval.
