# IEOS P0 Release Readiness

Date: 12 October 2026, Asia/Kuala_Lumpur. **Local P0 release candidate: PASS, ready for Director review. Hosted release: NOT AUTHORISED and not yet verified.** Stop after these reports; no commit, push, merge, hosted migration or deployment has been performed.

## Candidate identity and acceptance

The candidate is the uncommitted state of `codex-ieos-stage5-marketing-leads` in `C:/Users/USER/Documents/Codex/2026-09-07/why-x20/work/ieos-stage5-marketing-leads`, based on unchanged HEAD `4431a6564ad3bce58778695e752adf9362952042`. Stage 4 ancestor `9cdd4ab0fb7e5db9f504dae29d35cc1fc7a9d01c` remains preserved. GitHub/main was checked read-only at `a353df594e740cf423fda2ee1031b8ae0754e9ab`; this branch is 50 commits ahead and none behind. No branch was reconciled through mutation.

Final run 06 tested 228 files, including uncommitted files, and verified their hashes remained unchanged. Its manifest SHA256 is `744EEB6D830083D00C37ECE252362C95AAEDF55FC4C5225A0514FAAC1CE99424`. The four authority-document updates and these reports were added after testing; executable source/migrations/tests were not changed. The final source snapshot/manifest is retained under `C:/Users/USER/Documents/Codex/2026-10-12/codex-task-ieos-system-audit-knowledge/work/p0-release-candidate-20261012/`; the original dirty work snapshot remains separately recoverable.

| Local gate | Status |
|---|---|
| Source preservation / unchanged Git HEAD | PASS |
| TypeScript / zero-warning lint / production build | PASS |
| Stage 1–5 regression and public/staging approval | PASS — 383 assertions |
| P0 security matrix | PASS — 66 assertions |
| Restored security matrix | PASS — 66 assertions |
| MYT utility / HTTP / recorded UI checks | PASS — 17 / 20 / 22 |
| Forward migration replay / transactional rollback | PASS |
| Logical restore / all-table checksum / ownership | PASS in owned disposable environment |
| Cleanup / no residual owned stack | PASS |
| Production state, readiness, restore and deployment | NOT VERIFIED; outside local authorisation |

See `IEOS_P0_TEST_RESULTS.md` for exact evidence and earlier failures corrected before acceptance. The local release candidate contains the existing workforce, marketing, master-file and recovered content workflows. It intentionally withholds unclassified legacy knowledge from non-Super-Admin users and unscoped SOP/task/team records from ordinary management/staff. Director acceptance must include these visible access changes.

## Architecture retained

D1/D4/D8 are approved in principle. Retain one Inter Excel organisation, with IETA, IEA, PLC and KALER as business units and their departments. Existing explicit business-unit/department and module capability/record grants determine access; a management role does not grant every company automatically. There is one application role per provisioned user, separate from business job responsibilities. No training/job-role module was added.

Existing Stage 1–5 confidentiality classes and appointed permissions are retained. Unknown legacy knowledge is not automatically classified as operational. Known scoped SOPs remain accessible under department permissions; unscoped SOPs are withheld. Four-unit activation occurs only in synthetic fixtures. This candidate does not activate all four companies in production.

## Forward migration readiness

The verified **clean local replay manifest** is explicit:

1. Legacy forward baseline: `0001_init.sql`, `0002_org_business_unit_team.sql`, `0003_auth_access_rls.sql`, `0004_content_core.sql`.
2. `20260908113917_work_management_foundation.sql`.
3. `20260910101811_stage2_daily_output_log.sql`.
4. `20260910142301_stage3_manager_dashboard.sql`.
5. `20260913053937_stage4_master_file_register.sql`.
6. `20260913073400_stage5_restricted_marketing_leads.sql`.
7. `20260913142730_stage5_lead_form_configuration.sql` — completed pending configuration; no company activation.
8. `20261011182326_p0_public_workflow_compatibility.sql`.
9. `20261011182327_p0_legacy_security.sql`.

Historical staging 001–009 replay separately for local validation only. Do not apply them to a hosted project or point the deployed app at the historical staging mirror. Public is the candidate runtime schema.

The migration directory also contains old rollback scripts among baseline files. **Do not use a wildcard replay or an automatic migration push without a reviewed adoption manifest.** Clean replay order does not establish that a hosted migration ledger represents the same state.

Before any separately authorised hosted change, establish:

- Exact project/environment identity, current database/schema and migration ledger, deployed commit, schema configuration and function/table owners; record metadata without copying credentials or personal records into reports.
- Presence/absence and definitions of approval_categories, approval_action, record_edit_log and related columns/triggers. The compatibility migration assumes these additions are absent. Partial recovery or manually applied changes require a reviewed adoption migration; do not drop real objects or alter ledgers to force replay.
- Every existing profile's intended single application role. Duplicate role rows abort preflight. Preserve/export role history and obtain authorised reconciliation; do not arbitrarily choose or delete records.
- Existing null-scope SOPs/tasks/teams/content and unclassified knowledge. Identify an accountable steward and legitimate access before rollout. Denial is the safe default; restoring old broad access is not an acceptable workaround.
- Function owner and table-owner compatibility for the workflow guard, allowed function signatures/grants/search paths, and absence of leftover permissive policies after adoption. Local owner preservation does not establish hosted ownership equivalence.
- Candidate dependencies and grants in public, active profile/role provisioning, scoped campaign and task/evidence behaviour. `/api/ready` should succeed for active users and deny inactive/anonymous identities; it is not a complete security inventory.
- Separate backups, change window, write pause if needed, expected schema/data checks, application compatibility and a written restore/forward-fix decision. No new business-unit activation or historical bulk lead import is part of this manifest.

Do not run SQL against a real environment as part of this report. Any hosted preflight, rehearsal or application has to be separately authorised with an exact target and recoverable plan.

## Rollback and recovery requirements

### Verified locally

The two P0 compatibility/security migrations were trialled in a transaction and rolled back. A complete public schema dump before/after matched exactly using deterministic dump markers. This proves rollback **before commit** for those additive changes; it is not an authorised post-release down migration.

After full replay and synthetic fixture loading, public/staging/auth/extensions plus a test-helper schema were logically backed up and restored into the separate disposable `p0_recovery` database. Restore preserved owners using the existing local administrator. The original/restored data fingerprints matched at `b353cf36ad62c9288b93c3e554b26be6`, and 66 restored security assertions passed. The restore destination and cleanup belonged exclusively to the test run.

The fingerprint compares table data, not storage binaries or every platform setting. The drill restored the **candidate** database; it did not simulate recovery to a real pre-P0 production point. A pre-change backup and environment-specific recovery rehearsal remain release gates.

### Required operational procedure for an approved release

1. Select an approved restore point and retain the pre-change application/source version, schema/ledger inventory and external asset/configuration inventory. Define who can initiate recovery, acceptable data loss (RPO) and recovery time (RTO).
2. Rehearse recovery in an approved separate target with compatible PostgreSQL/Supabase versions and known ownership. Record duration, permission/identity outcomes and record counts/checksums without disclosing personal data.
3. Freeze or control writes during cutover; confirm the backup covers the latest accepted writes. Capture any subsequent writes needed for reviewed reconciliation.
4. If an application change fails, prefer a tested forward fix or compatible application rollback. Reverting only the app does not undo database changes. If security/data integrity fails, stop affected writes/access and follow the approved platform restore path.
5. Verify restored profiles/roles/inactive users, scope grants, restricted metadata, task/evidence and approval histories, storage/source links and runtime readiness before reopening access. Rotate/reissue credentials only through separately authorised provider procedures.

**Never use the retained `0003_auth_access_rls_rollback.sql` to reopen legacy permissive policies, or `0004_content_core_rollback.sql` to drop live content tables.** Their presence is historical recovery evidence, not a safe P0 rollback plan. There is no authorised destructive down migration in this candidate.

## Hosted Supabase considerations

The local test used an administrator available inside its owned container. Hosted customer credentials may not have that role or permission to restore managed owners. Auth/Storage ownership is significant to platform maintenance; do not change managed object owners to get around restore errors. [Supabase permissions documentation](https://supabase.com/docs/guides/platform/permissions)

A platform database backup includes Storage metadata, not the stored file binaries. A new-project restoration also requires separate handling of service configuration such as Auth settings, keys, Realtime and Edge Functions. Include company-controlled Drive/other provider assets and ACLs in the recovery inventory where those remain the actual source. [Supabase dashboard restore documentation](https://supabase.com/docs/guides/platform/migrating-within-supabase/dashboard-restore)

Raw local pg_dump/restore success is not sufficient evidence for a hosted migration. Supabase's documented tooling handles managed schemas differently, and version compatibility matters. Select and rehearse the supported platform procedure appropriate to the approved target; do not assume the disposable command can be copied to production. [Supabase platform restore guidance](https://supabase.com/docs/guides/self-hosting/restore-from-platform)

Backup/PITR availability, project status, storage backups and recovery entitlements for the actual hosted project were not checked. No recovery capability is presumed purchased, enabled or tested.

## Remaining Director approval gates

| Decision / authorisation | Recommendation and boundary |
|---|---|
| Accept the bounded local P0 candidate | Review the implementation/tests and intentional KB/null-scope access restrictions. Keep existing operations; no rebuild. |
| Detailed D1/D4 access and activation matrix | Name authorised administrators, company/department grants, appointed restricted access and offboarding owner. Approve business-unit activation individually; do not infer all four companies are live. |
| Legacy record stewardship | Nominate a reviewer for unknown scope/classification and role conflicts. Retain records while resolving access. Broad KB publication remains P1 under D2/D3. |
| Hosted readiness/recovery investigation and rehearsal | If proceeding, separately approve exact project, read-only inventory, backup method, rehearsal target, retention/RPO/RTO, change window and accountable release/recovery owners. |
| Release mechanics | Separately authorise any commit, reviewed branch reconciliation/push, hosted migration and Vercel release. Existing 50-commit local history must be reviewed as part of the release baseline. No merge/push/PR is implicit. |
| Dormant billing routes | Decide whether they belong in the approved release surface. Retain the new active-user gate; do not enable unverified billing dependencies or external calls through P0. Any integration change needs separate scope. |
| Next phase | D2/D3 and a bounded P1 brief before KB 2.0; D5/D6/D7 remain prerequisites for their later phases. D8 in principle is not implementation authority for P1–P4. |

Physical-device/multi-browser checks, real email/OAuth delivery and production-like adoption remain explicit limitations. Director approval of this local candidate does not by itself supply missing hosted evidence or authorise release.

**Current disposition: preserve the tested local candidate, retain reports, and await Director approval.**
