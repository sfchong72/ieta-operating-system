# IEOS P0 Security Remediation Report

Date: 12 October 2026, Asia/Kuala_Lumpur. Scope: local implementation and disposable testing only. **Local acceptance: PASS.** Final run 06 passed 1,075 SQL assertions, 27 browser checks and 25 HTTP assertions; build, typecheck, lint, utility, rollback, recovery and cleanup passed. Evidence is recorded in IEOS_P0_FINAL_TEST_RESULTS.md. Production adoption remains BLOCKED pending the gates in IEOS_P0_HOSTED_ADOPTION_PLAN.md.

## 1. Evidence and authority

Reviewed the hosted readiness report and all four previous P0 reports. Hosted facts below are the recorded read-only observations from 12 October, not a fresh inspection during this task. No hosted connection, database write/export, account/configuration change, Vercel action, Git commit/push/merge or Finance/Expenses access was used for this remediation.

The hosted inspection identified anonymous and authenticated TRUNCATE, REFERENCES and TRIGGER grants on all 17 legacy public tables, anonymous execution of six public and six staging definer helpers, no activity column, and exposure of both public and staging. Earlier P0 security SQL added authenticated CRUD grants without first removing all historical authenticated grants. Earlier local row-access tests therefore did not prove this privilege boundary.

## 2. Preservation and candidate identity

Repository: C:/Users/USER/Documents/Codex/2026-09-07/why-x20/work/ieos-stage5-marketing-leads.

Branch: codex-ieos-stage5-marketing-leads. HEAD remains 4431a6564ad3bce58778695e752adf9362952042. The earlier tested candidate, original dirty work and previous reports remain separately preserved. No dependency version was changed or installed.

Before editing, retained 233 tracked/untracked source files, ZIP, SHA256 manifest, HEAD, Git status and tracked patch under work/p0-final-preservation-20261012 in the audit workspace. Manifest SHA256: 85250C4EC276899C2C8B5D3C81C8647389018B38B2784EAB5181F2744F1A2139. Ignored runtime/build/dependency directories and credentials are excluded. The pre-existing release snapshot at work/p0-release-candidate-20261012 is untouched. Comparing the 233 preserved files confirms only the harness and two approval regression tests changed in this follow-up; all application files and earlier migrations remain byte-for-byte identical.

## 3. Changes made

| Component | Change | Data/functionality impact |
|---|---|---|
| 20261012015213_p0_final_legacy_privilege_lockdown.sql | New forward migration after all eight existing incremental files | Earlier migration files retained; no row rewrite, deletion, table drop or company activation |
| Public relation grants | Explicitly reset PUBLIC, anon and authenticated privileges; regrant the reviewed DML contract for 46 tables and four existing views | Removes TRUNCATE, REFERENCES, TRIGGER and PostgreSQL 17 MAINTAIN; existing RLS remains active |
| Legacy audit histories | approval_action and record_edit_log grant SELECT only; activities SELECT/INSERT | Existing history reads, owner-trigger writes and approved workflow RPCs retained; client history mutation blocked |
| Sequences | Revoke direct API-role sequence access | Reviewed owner-executed RPCs continue to allocate numbers/history IDs; clients cannot setval or advance internal sequences |
| Public routines | Reset application routine EXECUTE and explicitly regrant 72 existing reviewed RPC/helper signatures | Anonymous API execution denied; trigger bodies and low-level subject lookups not directly callable; extension routines excluded |
| Schema creation | Revoke API-role/PUBLIC CREATE in public | Keeps signed-in schema USAGE; no creation of shadow application objects |
| Default ACLs | Revoke automatic API privileges for future postgres-created tables/sequences/functions globally and in public | Future exposure requires explicit grants; effect on other schemas is an adoption decision described below |
| Owner/preflight/postflight | Abort on unexpected relation/routine owner or relation inventory; check effective inherited structural/anonymous privileges | Stops adoption rather than assuming REVOKE warnings or inherited grants are harmless |
| Local staging 010 | Mirror grant reset, existing 13 callable signatures and defaults after local staging 009 | Local regression fixture only; never part of the hosted public adoption manifest |
| p0_final_privilege_behavioural.sql | Effective ACL and actual negative-operation suite | Disposable probes/DDL and attempted writes roll back |
| Approval regression tests | Preserve original 35 assertions per schema; history check accepts zero affected rows or SQLSTATE 42501 and confirms unchanged history | Stronger object denial no longer fails a test written only for RLS filtering; other errors still fail |
| Disposable harness | Add security, grant-aware rollback, restored security, hosted-shape adoption and staging quarantine gates | Loopback/owned-container only; manifests detect source changes; no linked/project push/repair commands |

Existing authentication gates, role assignment, company/department grants, confidentiality classes, work tasks, daily outputs, dashboard, master files, restricted leads, MYT dates, campaigns, SOP/KB routes, planner/publications, evidence and approvals are retained. This adds no P1â€“P4 capability and changes no external integration.

## 4. Permission contract

Anonymous users receive no application table/column privileges, sequence privileges or executable application routines. PUBLIC inheritance is included in effective privilege checks. Authenticated users retain only explicitly necessary DML; RLS and RPC checks then enforce the actual identity, active status, application role, company/department and confidentiality permissions. The Director's application identity has no structural privileges either.

Legacy mutable business tables keep their existing guarded CRUD where supported. Immutable histories receive SELECT, or SELECT/INSERT for the legacy activities log. Stage 1â€“5 tables/views preserve their existing read contract and approved RPC mutation paths. No API-role grant option is provided. Service-role/managed owner privileges are not broadened or rewritten.

Existing low-level fn_wm_role_of and fn_wm_is_active were already internal, not caller-bound public APIs; their EXECUTE remains revoked from authenticated. Public caller-facing helpers remain scoped/caller-bound. The completion-evidence helper already checks task visibility; the new test supplies real restricted evidence before testing inactive/staff denial, avoiding a vacuous nonexistent-task test.

SECURITY DEFINER remains necessary for reviewed atomic mutations/internal lookups. Grant reset does not make every authenticated user entitled to the operation: existing function bodies must enforce active identity/scope and their negative tests remain required. Existing trigger invocation works without granting clients direct EXECUTE on trigger routines. Extension-owned routines are excluded from this application's blanket routine reset.

## 5. Defaults and limits

PostgreSQL schema defaults add to global defaults. A schema-only revoke cannot remove globally inherited default function EXECUTE. This candidate therefore revokes future postgres-created automatic API grants globally and then removes schema-specific additions. The change affects future postgres-created objects in other schemas of this IEOS database too, without changing existing objects there. Other object creators, including managed Supabase roles, have separate defaults; their defaults are not claimed hardened by this migration.

Before hosted adoption, verify the actual creator/default-ACL inventory and approve this effect. If an IEOS component requires public API access for a new object, its migration must explicitly enable RLS/policies and grant the minimum table/function permissions. Never compensate with GRANT ALL, a permissive role membership or a public function default. Current database API roles remain platform roles; business job responsibilities do not become extra application roles.

References: [PostgreSQL 17 default privileges](https://www.postgresql.org/docs/17/sql-alterdefaultprivileges.html), [Supabase Data API security](https://supabase.com/docs/guides/api/securing-your-api). RLS does not cover whole-table structural permissions: [PostgreSQL row security](https://www.postgresql.org/docs/17/ddl-rowsecurity.html).

## 6. Validation and issues corrected during testing

The final results report distinguishes completed checks, failed exploratory runs and blocked hosted gates. The first run's staging-history immutability assertion failed because the stronger ACL returned insufficient_privilege instead of zero affected rows. The application migration was retained; the test was corrected to recognise only valid denial outcomes and still verify the original record. Further runs corrected isolated pgTAP/scratch-ownership setup. A restored future-function test then exposed omitted global default ACLs in schema-filtered pg_dump; the recovery procedure now backs up/restores the exact postgres global default-ACL SQL separately and compares the affected global/public/staging defaults. No generic migration replay is used to conceal the recovery difference.

One complete database run subsequently timed out awaiting interactive confirmation during a chat/browser interruption; its owned resources cleaned up. Final run 06 repeated every SQL/adoption/recovery gate and completed fresh browser/HTTP acceptance with exit 0. Transient browser debugger timeouts were recovered through a fresh tab on the same local environment; they were not marked as passed without visible/API evidence.

The incremental model is built entirely from local definitions and synthetic records. It reproduces the recorded 17-public/20-staging table counts, twelve legacy helpers, missing activity column/workflow triggers, three exact legacy ledger versions and excess table/column grants. Only nine missing public forward migrations are then adopted; existing columns/records and original ledger entries are compared. This is useful bounded evidence, not proof of full hosted constraint/owner/configuration equivalence or a backup of hosted data.

## 7. Remaining hosted release gates

| Finding | Classification | Required next authority/action |
|---|---|---|
| Hosted grants/policies/functions still legacy | Verified in prior inspection; unchanged here | Separate approval to adopt the reviewed public migration set |
| Historical staging still configured for Data API | Verified in prior inspection; unchanged here | Consumer inventory, Director decision, staged exposure withdrawal and approved privilege quarantine |
| Backup/PITR entitlement and restore window | Blocked/unverified | Authorised read-only verification, backup/recovery method and independent restore rehearsal |
| Preview uses All-Environments public Supabase variables | Verified configuration; isolated destination unverified | Approved separate database, preview-scoped URL/keys/origin/redirects; no production service-role key |
| Password leak protection warning | Verified prior advisor warning; no Auth change here | Decide provider policy/risk treatment under separate approval |
| New-schema/old-frontend coexistence | Unverified | Rehearse compatibility or approve a maintenance/write-control window |
| Actual baseline definition/default-owner equivalence | Partially modelled; not fully verified | Fresh read-only preflight before adoption; stop on drift |
| Role/activity and unclassified/unscoped stewardship | Director decision | Preserve identities/history; determine intended active access, no automatic account provisioning |
| Release source and deployment | Uncommitted local candidate only | Approved Git baseline and separate release authority; no commit/push/deploy now |

No insecure rollback, historical staging deletion, blind baseline replay or hosted reactivation is recommended. Stop after local tests and these reports; Director approval is required before release.

## Final local evidence

Final accepted run: work/p0-final-test-run-06 in the audit workspace. Tested source manifest: 86609D4718C53F41DE3285FA845DF4C5321F59AFB802D3E7AE0B21676F3734AF (240 files, verified unchanged at completion). The three new reports were added after testing; application/migration/test code was not changed. A separate final source snapshot and verification metadata are retained under work/p0-final-release-candidate-20261012. Earlier snapshots and reports are unchanged.
