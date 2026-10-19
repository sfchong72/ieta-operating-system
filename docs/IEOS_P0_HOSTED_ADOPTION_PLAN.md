# IEOS P0 Hosted Adoption Plan

Date: 12 October 2026, Asia/Kuala_Lumpur. Status: PREPARED LOCALLY; HOSTED RELEASE BLOCKED. This is a reviewable plan, not authorisation to execute it. No hosted access/change, production export, deployment, Git commit or integration change was performed.

## 1. Exact target and recorded baseline

Use only the IEOS project ieta-operating-system, Supabase reference fjtrpoqnheodhfgokrdf, PostgreSQL 17.6, region ap-southeast-1. It was ACTIVE_HEALTHY at the previous read-only inspection. Do not reactivate it if its status changes without Director approval.

The Vercel target is ieta-operating-system, project prj_Gwl3Y0JVg75v4HTbLhEUaxJMgiHv. Recorded current production deployment: dpl_8ca4wWSHHgD66wvaDX5tdTSrCg1m, Ready; commit a353df594e740cf423fda2ee1031b8ae0754e9ab on main, linked to sfchong72/ieta-operating-system. The local candidate HEAD is 4431a6564ad3bce58778695e752adf9362952042 plus preserved uncommitted work. It is not the hosted release.

The previous hosted report verified 17 public tables, 20 historical staging tables, six legacy helpers in each schema, no non-internal application triggers, no public profiles.is_active, and PostgREST exposure of public and staging. Only IETA is active among the four business units. No other project, especially Finance/Expenses, is a valid migration/preview/recovery destination.

## 2. Baseline reconciliation â€” never replay 0001â€“0004 blindly

| Recorded hosted ledger | Local conceptual equivalent | Adoption treatment |
|---|---|---|
| No initial-schema entry in the returned ledger; initial objects already exist | 0001_init.sql | Structural equivalence must be verified. Do not execute seed/initial schema against hosted data or invent an applied entry |
| 20260817144740 / org_business_unit_team | 0002_org_business_unit_team.sql | Preserve hosted entry and existing hierarchy; do not replay company/dept seeds |
| 20260828004042 / auth_access_rls | 0003_auth_access_rls.sql | Preserve entry; compare helpers/RLS/roles and replace only through approved incremental changes |
| 20260828044543 / content_core | 0004_content_core.sql | Preserve entry/content/publication records; do not recreate tables or repeat transforms |

Version mismatch is not evidence that those baselines are unapplied. No migration repair, delete or marking-as-applied is authorised now. The adoption runner must use an explicit nine-file manifest outside a wildcard migration push. If a future CLI workflow needs ledger reconciliation, it requires a reviewed equivalence record and separately approved exact ledger operation; do not let it infer this from filenames.

The local synthetic adoption drill constructs an empty hosted-shape model using historical local definitions. That construction is fixture setup only. Its actual adoption loop excludes the four baseline files, preserves the three recorded versions and appends only the nine forward versions atomically with their SQL in the model.

## 3. Incremental public migration manifest

| Order | Forward file | Dependencies / expected addition |
|---|---|---|
| 1 | 20260908113917_work_management_foundation.sql | Existing hierarchy/Auth/roles; active profile field, single-role enforcement, work tasks/evidence/history/grants |
| 2 | 20260910101811_stage2_daily_output_log.sql | Stage 1; daily output/review history and evidence rules |
| 3 | 20260910142301_stage3_manager_dashboard.sql | Stages 1â€“2; dashboard grants/settings and scoped views/RPCs |
| 4 | 20260913053937_stage4_master_file_register.sql | Work/access helpers; governed master files, relationships/history |
| 5 | 20260913073400_stage5_restricted_marketing_leads.sql | Existing company/department access + work helpers; restricted leads, capability grants, history, safe follow-up tasks |
| 6 | 20260913142730_stage5_lead_form_configuration.sql | Stage 5; approved campaign/assignee form configuration; no four-company activation |
| 7 | 20261011182326_p0_public_workflow_compatibility.sql | Existing public content core; approval categories/actions/edit log, compatibility guards and RPCs |
| 8 | 20261011182327_p0_legacy_security.sql | Stages 1â€“5 plus public compatibility; active/caller-bound legacy policies, role/activity audit, workflow guards |
| 9 | 20261012015213_p0_final_legacy_privilege_lockdown.sql | All preceding objects; exact grants/functions/defaults and fail-closed owner/effective-privilege checks |

Expected public base-table count becomes 46 (29 additions); four existing candidate views have explicit read grants and invoker semantics. No hosted staging 001â€“010 script or test fixture belongs in this manifest. No P1â€“P4 migration or company activation is included.

Capture each file's SHA256 from the final preserved candidate and approve that exact set. Immediately before execution, repeat metadata-only preflight against the precise target: table/column/type/default/constraint/index definitions, table/routine/sequence owners, RLS policy definitions, trigger/function signatures and bodies, column/object ACLs, role inheritance, default ACLs by creator, extensions, ledger and exposed schemas. Verify no forward version is already applied and no same-name partial additions exist.

The model uses synthetic Auth/profile populations and local engine/platform defaults; it is not an exact clone of all hosted cardinalities or metadata. This task has not verified every hosted constraint/default against source. If preflight finds drift or partially created approval/access objects, stop and prepare a bounded reconciliation migration under further authority. Do not drop real objects, overwrite record IDs, grant broad access or repair the ledger to force this set.

## 4. Public and staging record preservation

| Record family | Preservation rule |
|---|---|
| Public organisation/units/departments/teams | Keep IDs, relationships and existing active flags. One organisation/four units remains; only IETA active |
| SOPs and knowledge | Keep all three SOPs/three KB items and source links. No bulk classification, AI rewriting, version conversion or reassignment |
| Legacy ideas/tasks/files/activities | Keep IDs, evidence URLs, historical status/actor/timestamp values; new guards apply prospectively |
| Content/publications | Keep eight content items/five publications; three completely unscoped items remain retained and Director-visible under default denial |
| Auth/public/staging profiles | Preserve identities, attribution and grants. Five Auth users without public profiles are not auto-provisioned/deleted; four currently have staging profiles |
| Staging history | Keep all 20 tables and retained profiles/categories/approval actions/edit logs/SOP/content, even after exposure withdrawal |
| New operational tables | Start as approved empty structures/reference settings; never import synthetic fixture records or claim a historical backfill was completed |

Counts above are prior aggregate observations, not a production export. Before cutover, an authorised operator must retain protected inventory/counts and integrity checks for every original column, PK/FK relationship and history, including Auth/staging. Existing owner/modification attribution must not change merely to satisfy a new guard.

The local drill computes original-column digests before and after the additive migration; newly added columns are intentionally excluded from the old-column comparison and checked separately. Logical recovery compares all candidate table data. No hosted personal data is present in either drill. Production-sized runtime, lock contention, real unsupported values and operator recovery rights remain separate gates.

Adding is_active defaults existing provisioned public profiles to true. Director must confirm intended active access before cutover; do not silently treat every retained Auth/staging identity as an active employee. One-role conflicts abort; resolve any future conflict through an approved record-preserving mapping, never arbitrary deletion. Unclassified legacy KB remains Super Admin-only until approved classification work in a later phase.

## 5. Withdraw historical staging from Data API

Recommended destination: public is the sole IEOS application schema exposed to Data API; retain staging as historical, inaccessible to ordinary API identities. First inventory application config, client schema headers, scripts, RPCs, jobs and privileged consumers. The current candidate uses public. Do not infer that no other staging consumer exists.

After approval:

1. Retain verified recovery coverage and metadata/data integrity inventory for staging and Auth.
2. Coordinate any consumer transition; approve the window and treatment of retained identities.
3. Use the supported IEOS Data API settings to remove staging from the exposed-schema list while preserving any required platform schema entries. Do not disable all Data API access or edit an unrelated project's settings.
4. Verify the effective authenticator/PostgREST configuration and cache reload using the supported control plane. Requests with Accept-Profile/Content-Profile staging must be rejected; public active-user operations must still work.
5. As a separately approved database privilege step, withdraw PUBLIC/anon/authenticated staging USAGE/CREATE and table/sequence/routine privileges, and remove postgres staging automatic API defaults. Keep owner/approved operator recovery access. Do not drop the schema, truncate tables or copy histories into public.
6. Verify no alternate privileged API route/service-role routine exposes staging, and check original records/digests/relationships unchanged. Treat service-role credentials as privileged server-only access regardless of the exposure list.

The local p0_staging_quarantine_drill.sql demonstrates record-preserving privilege withdrawal in the disposable hosted-shape model. It refuses a database other than p0_hosted_adoption and is not a production-ready control-plane script. The actual hosted exposure setting was not changed or exercised here.

Alternative: keep staging exposed only if Director approves a documented ongoing application purpose, full independent hardening and both-schema testing. Local staging 009/010 assumes recovered workflow triggers/RPCs absent on the hosted staging baseline, so it cannot simply be copied there.

## 6. Backup and hosted recovery requirements

Backup/PITR availability, plan entitlement, retained dates and restore range are BLOCKED/unverified. First obtain separately authorised read-only verification. A local successful pg_restore is not proof that the hosted customer role can restore managed ownership or that a usable hosted checkpoint exists.

Director must approve backup/recovery owner, exact method/destination, protected retention/access, RPO/RTO, any costs and a write-control window. Production data export, an independent restore destination or project creation/restore needs separate explicit authority. None is included in this task.

The approved recovery scope must cover public, historical staging, Auth identities and application records, constraints/indexes/functions/triggers/views/RLS, table/column/routine/sequence/default ACLs, owners, extensions and the ledger. Retain compatible app artifact/commit, non-secret settings inventory and secure configuration references. Roles/platform settings and API/Auth redirect/provider configuration need an environment-specific restore procedure; avoid importing inappropriate local managed grants into hosted service roles.

A schema-filtered logical dump can omit global default ACLs and test helper schemas. The local rollback gate therefore also compares pg_default_acl separately. The recovery drill captures exact postgres global default-ACL statements from a full local schema metadata dump, restores that auxiliary SQL after the filtered archive, compares an order-independent default-ACL fingerprint and creates temporary future objects to test actual denial. This limitation was observed as a real restored-security failure before correction. Hosted recovery acceptance must do equivalent privilege/default checks, not just compare row counts.

Verify the chosen checkpoint is complete/recoverable before migration; rehearse recovery to an approved isolated target with compatible engine/extensions/owners and re-run negative access checks. Reconcile any writes after the recovery point against the approved RPO. Confirm external Drive/Canva/master-file source assets and their sharing separately; database backup is not a copy of linked documents. There were no Supabase Storage buckets at the prior inspection; if that changes, include binary asset recovery separately.

[Supabase backups](https://supabase.com/docs/guides/platform/backups) describes plan-dependent options and restore downtime. [Dashboard project restore](https://supabase.com/docs/guides/platform/migrating-within-supabase/dashboard-restore) covers supported restoration/configuration considerations. Neither establishes this project's current entitlement.

## 7. Preview and rehearsal isolation

Existing All-Environments NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY can connect previews to production. No preview may be built/tested until an approved independent IEOS database target and preview-scoped configuration are verified.

Use synthetic data by default. Any approved production-like recovery rehearsal must have separately authorised data handling. Require exact project URL/reference allowlist, own anon/publishable key, own server-only key only if actually required, preview APP_URL, matching allowed Auth redirects and no production sessions/cookies. Preserve the production-only service-role secret boundary; never copy it to preview. Do not use Finance/Expenses as a convenient test destination.

Verify NEXT_PUBLIC_SUPABASE_SCHEMA defaults to public or is explicitly public; no local-UAT bypass variable in production/hosted preview. Use isolated callbacks/origins and disable external email/webhooks/payment/AI/CRM side effects during rehearsal. No integration setting was changed here. Ordinary health is liveness; authenticated /api/ready plus full security/regression checks is required.

## 8. Proposed eventual release sequence

1. Director approves the decisions below and exact candidate manifest; separately authorises Git baseline and hosted operations.
2. Authorised read-only preflight re-verifies IEOS identities, deployment/ledger/schema/default ACLs and backup entitlement. Stop on drift/inactive project.
3. Establish approved isolated preview/recovery target and scoped configuration; rehearse the explicit incremental set with preservation and negative access tests.
4. Verify backups and recovery rehearsal, retained app rollback artifact, migration transaction/ledger runner and expected lock duration. Validate old frontend with new schema, or choose an approved maintenance/write-control window.
5. Take/verify the approved pre-change recovery checkpoint and control writes. Execute only the nine reviewed public forward files. Wrap each migration body and its ledger insertion in the same reviewed transaction; normalise existing top-level BEGIN/COMMIT deliberately, never nest an unreviewed outer transaction around COMMIT-bearing files. The disposable model tests this approach.
6. Verify version/owner/constraint/grant/default inventory, preserved records/relationships, inactive/anonymous/cross-company denial, approvals/evidence/history and Director-only unclassified records. Abort before reopening writes if any check fails.
7. Withdraw staging exposure/privileges under the approved separate step and validate preserved history/required consumers.
8. Deploy the approved application artifact only after schema/dependency acceptance. Verify correct project/environment/commit, secret boundary, active-user readiness and desktop/mobile workflows. No uncontrolled preview may touch production.
9. Reopen writes only after acceptance and record the release checkpoint; follow the approved recovery/forward-fix decision if a failure occurs.

Do not use a wildcard db push, local staging fixtures, baseline replay, automatic migration repair, unreviewed direct ACL restoration or the old permissive/content-dropping rollback SQL.

## 9. Rollback and failure handling

Before commit, roll back the current migration transaction, including its ledger insertion. The local gate checks all three P0 migrations in an outer trial after normalising transaction wrappers; before/after public/staging schema dumps retain ownership/ACLs and a separate default-ACL hash.

After one migration is committed, stop on failure. Do not replay completed non-idempotent files. Retain exact applied versions, do not conceal partial adoption by deleting ledger rows, and follow the approved resume/forward-fix or checkpoint-restore procedure. Application rollback alone cannot undo schema/data/security changes. Returning to the old frontend may require the approved write pause.

After release writes begin, a checkpoint restore can lose subsequent writes. Prefer a tested bounded forward fix when preservation permits; otherwise restore under approved RPO/RTO and reconcile. Do not re-enable anonymous grants or remove guards simply to make the old app work. No general destructive down migration is included.

## 10. Decisions requiring Director approval

| Decision | Recommendation | Alternative / condition |
|---|---|---|
| Exact release baseline and authority | Approve the preserved final candidate/hash set, then separately permit commit/push/release on the intended branch/project | Keep local candidate pending further review |
| Baseline equivalence and adoption runner | Preserve three hosted versions; approve nine incremental files and atomic per-file ledger process after fresh metadata preflight | Prepare bounded reconciliation if definitions/partial objects differ; no blind repair |
| Future-object default ACL policy | Approve postgres opt-in API grants, including the database-wide future-function effect | Use an approved separate migration owner/private API design later; no P1 redesign in this task |
| Historical staging disposition | Remove exposure and ordinary API privileges, preserve all records/approved recovery access | Keep exposed only after purpose and complete independent security acceptance |
| Backup/recovery and RPO/RTO | Verify entitlement, approve checkpoint/isolated rehearsal/access/retention/cost/write window | Defer release until recoverability is proven |
| Preview destination/configuration | Separate approved IEOS database and preview-only keys/origin/redirects; synthetic data | No preview/release testing until isolation is established |
| Cutover downtime and old-app coexistence | Rehearse coexistence; approve maintenance/write control if compatibility cannot be established | Defer release; do not weaken controls |
| Active identities and record stewardship | Confirm intended active profiles, preserve unmapped Auth/staging users, nominate steward for unscoped content/KB | Leave default denial and restrict rollout; no automatic account/role changes |
| Hosted password policy warning | Approve provider-appropriate leaked-password treatment after Auth method review | Explicit bounded risk acceptance; no setting change now |
| Company activation | Retain only IETA active for P0 | Any additional unit activation is separate authority, not implied by D1/D4 |

Stop after local preparation and reports. All hosted execution, recovery actions, account/configuration changes and release remain outside this task.

## Final local evidence

Final accepted run: work/p0-final-test-run-06 in the audit workspace. Tested source manifest: 86609D4718C53F41DE3285FA845DF4C5321F59AFB802D3E7AE0B21676F3734AF (240 files, verified unchanged at completion). The three new reports were added after testing; application/migration/test code was not changed. A separate final source snapshot and verification metadata are retained under work/p0-final-release-candidate-20261012. Earlier snapshots and reports are unchanged.
