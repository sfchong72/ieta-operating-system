# IEOS P0 Test Results

Date: 12 October 2026, Asia/Kuala_Lumpur. **Final local result: PASS.** The final disposable run completed with exit code 0, including cleanup. No mandatory local test remained failed or blocked. Hosted release verification remains outside this authorisation.

## Candidate and environment

- Branch: `codex-ieos-stage5-marketing-leads`; HEAD: `4431a6564ad3bce58778695e752adf9362952042`, unchanged.
- Candidate: 228 tracked/untracked file hashes, checked unchanged at harness completion. Manifest SHA256: `744EEB6D830083D00C37ECE252362C95AAEDF55FC4C5225A0514FAAC1CE99424`.
- Evidence root: `C:/Users/USER/Documents/Codex/2026-10-12/codex-task-ieos-system-audit-knowledge/work/`.
- Final database run: `p0-test-run-06/`; disposable project `ieos-stage5-87ff5a904379`.
- Existing Docker Desktop engine: 29.7.2, Linux; installed Supabase CLI: 2.116.0. No upgrade or package installation.
- Local API/database ports: 55431/55432; UI port 3201. Separate from the unrelated FinanceOps database on 54322.
- Synthetic identities and source-controlled demo fixtures only. No production credentials/data, hosted linkage or service calls. The local Next UAT server used `TZ=UTC`.
- Only documentation/authority files changed after the sealed run; executable source, migrations and tests stayed unchanged.

## Executed gates

| Test | Result | Evidence / coverage |
|---|---|---|
| TypeScript, `npm run typecheck` | PASS | `p0-typecheck-final.log`; tsc --noEmit, exit 0 |
| ESLint, `npm run lint` | PASS | `p0-lint-final.log`; --max-warnings=0, exit 0 |
| Production build, `npm run build` | PASS | `p0-build-final.log`; Next.js 15.5.23 production compilation/prerender/type validation, exit 0 |
| Stage 1 regression | PASS 60/60 | `stage1-behavioural-matrix-60.log`: identity, scope, evidence, completion, audit, attention |
| Stage 2 regression | PASS 35/35 | `stage2-behavioural-matrix-35.log`: immutable daily output, evidence, review, identity and activity |
| Stage 3 regression | PASS 60/60 | `stage3-dashboard-matrix-60.log`: canonical attention, working days, workload, review and aggregate leakage |
| Stage 4 regression | PASS 92/92 | `stage4-master-file-matrix-92.log`: RLS, P&C metadata/link denial, scoped search, relationships, lifecycle and audit |
| Stage 5 acceptance | PASS 66/66 | `stage5-marketing-lead-matrix-66.log`: capability/scope/PII, duplicate warnings, dated history, task privacy, attention and scoped campaign choices |
| Recovered staging approval/edit regression | PASS 35/35 | `behavioural-matrix-35.log`: submit, approve, revision/comment, editing and cross-scope negatives |
| Public approval/edit regression | PASS 35/35 | `public-approval-matrix-35.log`: same recovered workflow against the actual app schema |
| P0 legacy/security negatives | PASS 66/66 | `p0-legacy-security.log`: 20 inactive legacy tables, Stage 1–5 inactive access, role escalation, caller binding, null scope, evidence, workflow/audit forgery, explicit cross-company grant and anonymous denial |
| Public forward replay | PASS | Explicit baseline 0001–0004 plus Stage 1–5, pending campaign configuration and both P0 migrations |
| Staging forward replay | PASS | 001–009 in exact order; no hosted staging |
| Database lint | PASS | `database-lint.log`: error threshold; no schema errors found |
| Transactional P0 rollback | PASS | `p0-transaction-rollback.log`, `rollback-schema-compare.log`: compatibility/security changes rolled back; before/after public schema dumps identical |
| Ownership-preserving logical restore | PASS | `recovery-backup.log`, `recovery-restore.log`: isolated `p0_recovery` database; restore completed with exit-on-error |
| All-table recovery data comparison | PASS | `recovery-original-checksum.log`, `recovery-restored-checksum.log`: both `b353cf36ad62c9288b93c3e554b26be6` |
| Restored database security | PASS 66/66 | `recovery-restored-security.log`; same negative-access matrix against restored data/permissions |
| MYT conversion/display tests | PASS 17/17 | `p0-business-time-final.log`, `tests/p0-business-time.mjs`: UTC boundaries, leap/calendar validation, optional values, edit roundtrip, explicit MYT display under UTC |
| Real authentication/API tests | PASS 20/20 | `http-results.json`: anonymous/active/inactive JWT, readiness, REST filtering, escalation, dormant API denial and persisted UI data |
| Desktop/mobile UI acceptance | PASS 22/22 recorded scenarios | `ui-results.json`; Chromium 1440×1000 and 390×844; scenarios below |
| Candidate unchanged during run | PASS | Harness verifies every manifest file hash before accepting success |
| Cleanup and exit-code contract | PASS | `cleanup-stop.log`, `ieos-disposable-test-report.md`; owned stack stopped without backup, temp lab removed, exit 0. Harness SelfTest also passed. |

The primary SQL suites contain **449 assertions**; the restored repeat adds **66**, for **515 executed SQL assertions**. HTTP, utility and UI scenario counts are separate coverage measures, not additional SQL assertions.

## HTTP checks and UI evidence

HTTP verified anonymous readiness/SOP denial; active manager readiness; cross-company lead filtering; blank-department foreign content filtering; legacy KB default denial; manager role-escalation denial; inactive valid-JWT task/SOP denial; inactive readiness and protected page rejection; checkout/portal denial before any external call; four synthetic units for Director versus scoped IETA for manager. After UI testing, HTTP also confirmed exact stored UTC instants, both retained interactions, no lead contact/name in the generic task, evidenced daily output with supervisor approval, and all three public content history events.

The 22 UI scenarios recorded in `ui-results.json` cover:

1. Inactive login rejection and active manager login.
2. Scoped campaign creation and clearing dependent company/department selections after success.
3. Manager legacy KB restriction and absence of foreign blank-department planner content.
4. Scoped content creation and pending submission with attributed history.
5. Lead creation, controlled campaign linkage and MYT display with the server in UTC.
6. Two separately dated contacts, retaining actor, result, next action and follow-up date.
7. Related task containing the restricted lead ID without contact data.
8. Mobile metadata editing preserving the 11:00 MYT follow-up and both contact entries.
9. Lead detail/edit without horizontal page overflow at 390×844.
10. Sign-out denying the next protected navigation.
11. Assigned staff login and task detail, followed by an evidence link and daily submission.
12. Completed daily deliverable rejected without evidence, then accepted with evidence.
13. Intern login with only the explicitly assigned synthetic lead.
14. Manager supervisor approval retaining staff output, evidence and attributed review.
15. Director retaining legacy knowledge and SOP lists.
16. Desktop dashboard, file register, attention, ideas, legacy tasks and approvals smoke checks.
17. Routine content queue comment/approval retaining submission and reviewer history.
18. Mobile daily evidence/review layout, menu navigation and manager dashboard.

Related steps are grouped above; the JSON records 22 individual scenarios. Screenshots are retained in the audit workspace's outputs directory as `IEOS_P0_DESKTOP_ACCEPTANCE.jpg` and `IEOS_P0_MOBILE_ACCEPTANCE.jpg`. All displayed contact information is synthetic test data. External evidence URLs use example.invalid and were not opened.

## Failures found and corrected before final acceptance

| Earlier attempt | Result and corrective action |
|---|---|
| Run 01 | FAIL: random pg_dump restrict markers made an otherwise identical rollback dump differ. Used a deterministic restrict key; did not weaken the schema comparison. |
| Run 02 | FAIL: Stage 5 expected all four units for a scoped manager, and DUE TODAY fixture depended on a fragile UTC clock time. Corrected the expected scoped result, added Director four-unit coverage, and made the synthetic date relative to the remaining MYT business day. |
| Run 03 | FAIL: logical restore as postgres could not restore a managed Supabase owner. Used the existing local supabase_admin in the disposable database to preserve owners. No hosted privileges or ownership were changed. |
| Run 04 | FAIL: restoring into a newly created database encountered its existing public schema. Added --clean --if-exists only for this newly created disposable recovery database. |
| Run 05 | FAIL: manual UI exposed foreign-company content with no department and stale campaign form reset state. Sent FAIL to the harness, hardened read/edit helpers, restricted unclassified KB/unscoped legacy records and added six security assertions; fixed the form state. |
| Run 06 | PASS: full fresh replay, 449 primary assertions, restore/checksums, 66 restored assertions, HTTP and UI completed; cleanup passed. |

The original Windows-sandbox production build could not canonicalise a local path. The unchanged build command succeeded outside that filesystem sandbox under approved local-only execution; no dependency or code workaround bypassed compilation. Webpack cache serialization advisories were non-failing build messages; ESLint passed with zero warnings.

## Reproduction

Use the preserved Stage 5 worktree and installed pinned toolchain; keep production environment files absent. Do not substitute a hosted URL or run legacy rollback files.

```powershell
npm.cmd run typecheck
npm.cmd run lint
npm.cmd run build
$env:TZ = 'UTC'
node.exe tests/p0-business-time.mjs
./run-ieos-disposable-test.ps1 -AllowUncommittedCandidate -InteractiveUat -OutputDirectory <new-local-evidence-directory>
```

The harness rejects the wrong branch/ancestor, hosted linkage and unsafe commands. It records a candidate manifest, uses isolated local ports, checks approval/evidence/security matrices and waits for actual UI acceptance. Write its PASS signal only after completing browser checks; a FAIL signal or timeout fails the run. If Docker or the installed CLI is unavailable, the harness fails rather than substituting hosted testing or installing a package.

## Outstanding verification beyond the local gate

| Verification | Status | Reason / required next action |
|---|---|---|
| Hosted schema adoption, ledger and deployed/runtime comparison | BLOCKED by current authorisation | No hosted access/change authorised. Obtain bounded read-only inventory and reviewed adoption plan before a separate release. |
| Hosted backup/PITR/restore and storage-binary recovery | BLOCKED by current authorisation | Local logical drill is not a platform restore. Rehearse the selected recovery procedure in an approved separate environment. |
| Real email invitations, production magic-link/OAuth delivery and provider session revocation | BLOCKED by current authorisation | No production credentials or real messaging permitted; synthetic password session and inactive valid-JWT path passed. |
| Physical mobile devices and other browser engines | BLOCKED by unavailable test surfaces | Responsive Chromium acceptance passed; physical-device/multi-browser results are not claimed. |
| External CRM/finance/accounting/Drive/AI calls | BLOCKED by scope | Integrations were not changed or invoked. Dormant billing dependencies remain unverified. |

These are release considerations, not missing executed local SQL/build gates. Do not label the candidate deployed, production-ready or Director-accepted from this report.
