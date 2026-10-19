# IEOS P0 Final Test Results

Date: 12 October 2026, Asia/Kuala_Lumpur. **Local final P0 candidate: PASS. Hosted release: BLOCKED / not authorised.**

All acceptance below ran against new, disposable local resources and synthetic records. No hosted Supabase/Vercel action, production export, package installation, Git commit/push/merge or Finance/Expenses access occurred.

## 1. Candidate and evidence identity

Repository: C:/Users/USER/Documents/Codex/2026-09-07/why-x20/work/ieos-stage5-marketing-leads.

Branch: codex-ieos-stage5-marketing-leads; unchanged HEAD 4431a6564ad3bce58778695e752adf9362952042; preserved Stage 4 ancestor 9cdd4ab0fb7e5db9f504dae29d35cc1fc7a9d01c. No branch/ref mutation was used.

Final accepted run: work/p0-final-test-run-06 in C:/Users/USER/Documents/Codex/2026-10-12/codex-task-ieos-system-audit-knowledge. Owned project: ieos-stage5-1a81e79e68b7. Harness process exit: **0**. Candidate manifest: 240 files; SHA256 **86609D4718C53F41DE3285FA845DF4C5321F59AFB802D3E7AE0B21676F3734AF**. The harness verified every file hash unchanged after acceptance. The three new documentation deliverables were written after the test; executable sources were not changed.

Toolchain: existing Node 24.19.0/npm 11.17.0; Next.js 15.5.23; Supabase CLI 2.116.0; Docker 29.7.2 in Linux-container mode; disposable Supabase PostgreSQL 17.6. No upgrades/installs. Application/API/DB ports were loopback/local isolated; no linked-project markers or hosted URL were permitted.

## 2. Executed gates

| Gate | Status | Evidence / result |
|---|---|---|
| Preserve previous candidate and dirty work | PASS | 233-file pre-edit snapshot, ZIP, patch/ref/status/manifest; older snapshots retained |
| Preserved source comparison | PASS | Only harness and two existing approval tests differ from pre-edit snapshot; no missing files; previous application/migration files byte-identical |
| TypeScript | PASS | npm.cmd run typecheck; exit 0; work/p0-final-typecheck.log |
| ESLint | PASS | npm.cmd run lint; exit 0; zero-warning gate; work/p0-final-lint.log |
| Production build | PASS | npm.cmd run build; exit 0; all 37 static pages; work/p0-final-build.log; only loopback placeholder configuration, no deployment |
| MYT date/time utility | PASS | 17 internal assertions; work/p0-final-business-time.log |
| Harness failure/cleanup exit contract | PASS | Self-test of all four exit-code outcomes; work/p0-final-harness-selftest-02 |
| Public clean replay | PASS | Explicit 0001–0004 fixture baseline + nine forward files; no wildcard/rollback files |
| Stage 1 work/evidence/security | PASS | 60/60; stage1-behavioural-matrix-60.log |
| Stage 2 daily output/review | PASS | 35/35; stage2-behavioural-matrix-35.log |
| Stage 3 dashboard | PASS | 60/60; stage3-dashboard-matrix-60.log |
| Stage 4 master-file lifecycle/security | PASS | 92/92; stage4-master-file-matrix-92.log |
| Stage 5 restricted leads | PASS | 66/66; stage5-marketing-lead-matrix-66.log |
| Local staging replay | PASS | Explicit 001–010; local fixture only, not a hosted adoption manifest |
| Staging approval/edit | PASS | 35/35; behavioural-matrix-35.log |
| Public approval/edit | PASS | 35/35; public-approval-matrix-35.log |
| Earlier P0 legacy negative access | PASS | 66/66; p0-legacy-security.log |
| Final effective grants/negative SQL | PASS | 270/270; p0-final-privilege-security.log |
| Migration transaction rollback | PASS | Three P0 migrations trialled/rolled back; public/staging dumps including owners/ACLs match; separate global/schema default-ACL before/after hash match |
| Logical recovery | PASS | Separate owned p0_recovery DB; owner-preserving restore, matching application/Auth data and affected default ACLs |
| Restored security | PASS | 66/66 legacy + 270/270 final privilege assertions; recovery-restored-security.log / recovery-restored-final-security.log |
| Hosted-shape baseline model | PASS | 7/7; reproduces recorded selected schema/ledger/legacy grant metadata with synthetic data |
| Incremental adoption/preservation | PASS | 9/9; only nine forward versions appended atomically, all original columns/records and three ledger entries retained |
| Historical staging quarantine | PASS | 4/4; ordinary API-role access withdrawn without deleting 20 historical tables or any original record/field |
| Supabase database lint | PASS | No schema errors; database-lint.log |
| Local security advisor | PASS | No issues returned; local-security-advisors.log; not a hosted Auth/settings certification |
| HTTP/API/Auth/record acceptance | PASS | 25/25; http-results.json |
| Browser desktop/mobile acceptance | PASS | 27/27; ui-results.json; responsive viewport 390x844 and normal desktop |
| Frozen candidate and cleanup | PASS | Manifest verified; owned Next process stopped, exact disposable stack stopped without backup, validated temporary lab removed |

SQL total: **1,075 assertions** = 719 primary regression/security + 336 restored security + 20 model/adoption/quarantine. Rollback, checksum/default-ACL equality, advisor/lint, HTTP, UI and utility checks are separate; they are not inflated into that SQL count.

## 3. Negative security coverage

The 270-assertion suite checks all 50 public table/view relations and 21 local staging tables, exact necessary authenticated DML, anonymous table/column denial, structural privileges (TRUNCATE, REFERENCES, TRIGGER, MAINTAIN), column REFERENCES, no grant delegation, sequence access, callable application-routine allowlists, revoked trigger/low-level helpers and new-object defaults.

Actual SQL attempts require SQLSTATE 42501 for anonymous, inactive, staff and Director application identities: TRUNCATE/trigger creation, authenticated creation of FKs referencing protected tables, low-level role/activity probing, sequence reset and execution of a newly created default-denied function. The REFERENCES probe table is owned by authenticated in a disposable scratch schema; failure therefore tests protected-table REFERENCES, not lack of ownership. The scratch grant/probes roll back in full.

Restricted evidence actually exists before helper-denial assertions. Inactive/staff callers cannot use the completion-evidence helper to disclose an inaccessible P&C task, or assign themselves Super Admin. Existing suites add valid-JWT inactive/role-less identity checks, cross-company/department denial, explicit grants, P&C history leakage, actor binding, forged approvals, evidence enforcement, immutable reviews/histories and appropriate positive paths.

RLS tests alone are not used to certify structural privilege denial. No destructive test was run against existing hosted or development data; even successful probe DDL/operations are bounded to disposable resources/transactions.

## 4. Recovery and adoption evidence

All-candidate application/Auth/extension table-data fingerprint, original and restored: **7766f23550f08931d221e3cb11cb7835**.

Affected postgres global/public/staging default-ACL fingerprint, original and restored: **1d8e3e5d484e0923bdfad416bed4f855**.

Schema-filtered pg_dump omitted global default function permissions in an earlier attempt. The final drill captures the exact postgres global default-ACL statements from a full **local schema metadata** dump into a separate auxiliary SQL file, restores them under the existing local administrator after the filtered archive, compares defaults and re-runs actual future-function denial. It does not hide a bad restore by replaying application migrations.

Recovery scope: public/staging/auth/extensions/ieos_stage1_test plus affected postgres global defaults. Test helpers are local-only. No Storage binary/hosted platform settings or database-wide owner privileges outside this scope are claimed restored. Local administrator recovery rights do not establish hosted customer rights.

The hosted-shape model reproduces selected recorded metadata: 17 public and 20 staging tables, six legacy helpers per schema, no activity column/workflow triggers, three precise legacy versions and broad grants. Its Auth/profile populations and managed defaults are synthetic/local; it is not a full hosted clone. Old baseline scripts construct the empty model only; the adoption phase explicitly skips them. Original-column digests include public, staging and Auth records; additive columns/reference settings are separately checked. Historical staging is not replayed, merged or deleted during adoption.

## 5. HTTP and browser acceptance

HTTP checks use fresh synthetic sign-ins and a guarded exact loopback URL. They confirm inactive valid-JWT row filtering, protected-page/readiness denial, anonymous SOP/RPC denial, role escalation denial, cross-company/null-department filtering, local public-only schema exposure, and unavailable low-level role helpers. The inactive checkout/portal routes reject before any external call; no billing integration was activated.

API queries also independently verify UI-created records: exact UTC instants for MYT lead inputs; both dated contacts retained after mobile metadata editing; related task without the lead's name/contact details; immutable approved daily evidence; and content submission/comment/approval history.

Browser checks performed:

1. Manager authentication and scoped navigation.
2. Scoped campaign creation and dependent-field reset.
3. Manager register retains IETA-only company choices.
4. Lead creation retains scoped campaign/assignee and exact MYT dates.
5. Two dated contacts retained with actor and MYT follow-up.
6. Related task created with restricted lead reference.
7. Mobile lead detail/edit fit 390x844.
8. Mobile metadata edit preserves both contacts and MYT follow-up.
9. Mobile sign-out denies protected route.
10. Staff authentication and assigned-work scope.
11. Staff evidence link saves with attribution.
12. Completed daily output without evidence is rejected inline and preserves values.
13. Staff daily submission retains output and required evidence.
14. Intern sees exactly one explicitly assigned lead.
15. Manager supervisor approval retains staff output/evidence and actor history.
16. Mobile daily evidence and review fit 390x844.
17. Scoped public content creation preserves existing planner workflow.
18. Content submission creates pending state and immutable submitted history.
19. Routine content comment/approval preserve submitted/comment/approved history.
20. Management knowledge page enforces intentional unclassified-record restriction.
21. Manager dashboard loads scoped workload, output and review metrics.
22. Master-file register and scoped search load under final grants.
23. Director retains all three legacy knowledge records.
24. Director SOP listing preserves scoped records and original versions.
25. Legacy content ideas retain original pipeline records.
26. Legacy content task list retains existing statuses and scope.
27. Task attention view remains available with permitted scope filters.

Screenshots in the audit outputs directory: IEOS_P0_FINAL_DESKTOP_ACCEPTANCE.png and IEOS_P0_FINAL_MOBILE_ACCEPTANCE.png. All displayed identities/contact data are synthetic. Example.invalid evidence URLs were stored as test references and never opened.

Browser debugger/CDP timing interruptions were recovered by reading the current state and using a fresh tab in the same browser. Some selectors initially timed out during route/response processing; checks were recorded only after successful visible state/API evidence. Temporary tabs closed and viewport override reset.

The stale session during run 05 produced a page failure after its server had been stopped. That was not accepted as missing-evidence validation: run 06 repeated the real validation and displayed the correct inline rejection before successful evidenced submission.

## 6. Earlier attempts — retained failures, not passed retrospectively

| Attempt | Result | Correction / final disposition |
|---|---|---|
| Final run 01 | FAIL | Existing staging immutability test expected zero affected rows; stronger ACL returned permission denial. Test now accepts only zero writes or insufficient_privilege and confirms history unchanged |
| Final run 02 | FAIL | New suite did not initialise pgTAP in its transaction; added explicit disposable extension setup |
| Final run 03 | FAIL | FK probe ownership transfer needed CREATE on its scratch schema; granted only within the rolled-back synthetic test transaction |
| Final run 04 | FAIL | Restored row checksum matched, but five future-function denial assertions failed because global default ACLs were missing; fixed exact ACL recovery |
| Final run 05 | FAIL overall | All database/adoption/recovery gates passed; browser confirmation expired during interruption/chat pause. Owned resources cleaned up; partial UI evidence retained separately |
| Final run 06 | PASS | Fresh complete run, all database gates plus 27 UI/25 HTTP checks and cleanup; exit 0 |

Do not present an earlier failed/partial attempt as release acceptance. The original earlier P0 reports/snapshot remain unchanged historical evidence.

## 7. Outstanding / blocked verification

| Gate | Status | Reason |
|---|---|---|
| Fresh hosted definition/default-ACL/ledger preflight | BLOCKED pending separate authority | Recorded inspection informs the model; no fresh hosted access performed |
| Backup/PITR entitlement and real hosted recovery rehearsal | BLOCKED / unverified | Requires exact project/plan verification, Director-approved method/owner/RPO/RTO/destination; no production export/restore now |
| Isolated hosted preview | BLOCKED | Existing All-Environments config may target production; separate approved DB/keys/origin/redirects required |
| Old hosted app/new schema coexistence and actual lock/downtime duration | BLOCKED / unverified | Synthetic local volume does not establish production timings or compatibility |
| Real email/OAuth/magic-link delivery and provider session revocation | BLOCKED by scope | Synthetic password sessions only; no real external message/provider operation |
| Physical mobile devices / other browser engines | NOT TESTED | Responsive desktop/mobile-size Chromium only |
| Hosted password leak protection warning | UNRESOLVED | Prior hosted warning is not altered or cleared by local SQL advisor |
| External integration behaviour | NOT TESTED / outside scope | No Finance, CRM/accounting, Drive, AI or billing activation/change |
| Production release / company activation | NOT AUTHORISED | Separate Director approvals; only IETA remains active in adoption model |

The absence of local errors does not certify production deployment or complete hosted equivalence. See IEOS_P0_HOSTED_ADOPTION_PLAN.md for exact decisions and sequence.

## 8. Reproduction and stop condition

Use the preserved candidate, existing pinned dependencies and a new disposable evidence directory. Typecheck/lint/build require only local placeholder configuration. Run the 17-assertion business-time utility, harness self-test and run-ieos-disposable-test.ps1 with AllowUncommittedCandidate and InteractiveUat. Never substitute a hosted URL, run rollback/wildcard migration files, install a fallback package or use a different project.

The harness rejects wrong branch/ancestor, .env credential files, hosted linkage/commands and unknown disposable DB names. Its PASS signal is written only after actual UI and HTTP acceptance. If required Docker/CLI/UI capability is unavailable, record FAIL/BLOCKED, not success.

Local testing and reports are complete. **Stop and await Director approval before any hosted change or release.**
