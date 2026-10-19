# IEOS Development Roadmap

**Date:** 12 October 2026, Asia/Kuala_Lumpur  
**Status:** Proposal for Director review. No stage is authorised by this report.  
**Approach:** Extend the existing Next.js/Supabase IEOS. Preserve current operational/content records and reusable functionality. No rebuild.

## 1. Delivery rules and dependencies

This roadmap uses P0–P4 priorities; these are distinct from the repository's historical Stages 0–15. Existing stage checklists and older plans do not approve this expansion. Confirm sequencing with the Director before implementation.

Local Stage 1–4 historical acceptance exists; the hosted project is inactive and current deployment/schema compatibility is unverified. Stage 5 has incomplete UI acceptance and additional uncommitted work. These are release-readiness issues, not reasons to discard the system.

Complexity is relative: **Low** = bounded extension to existing patterns; **Medium** = a new domain/workflow with database/UI/RLS and migration work; **High** = cross-system security, lifecycle or operations. Estimates are not delivery dates; resource/budget commitments need approval.

Dependency chain:

`P0 stable release baseline → P1 governed approved knowledge → P2 training/succession → P3 assistant → P4 integrations`

P3 fundamentally depends on P0/P1, not full completion of P2. Delivering P2 first provides better role/task context and continuity value. Full Drive automation is P4; manually approved snapshots in P1 allow P3 to proceed without it.

At every stage retain additive, reviewable changes and local synthetic testing, show a release candidate with rollback/restore plan, and stop for acceptance. A stage's acceptance is separate from permission to push, apply hosted migrations or deploy.

## 2. P0 — Stabilise existing IEOS

**Outcome:** A known, reproducible application/schema candidate with consistent identity controls and a clear path to an authorised release.

**Dependencies:** Director decision on controlled release scope; access to existing worktrees/artifacts; identification of system owner. Hosted recovery/deployment requires later explicit approval.

**Complexity:** Medium overall; high uncertainty for hosted recovery because current schema/configuration is unavailable.

| Work package | Reuse / change | Complexity |
|---|---|---|
| Establish release baseline | Preserve latest Stage 5 HEAD and pending changes; compare against main/governance; select reviewed candidate. Keep independent work/content domains. | Low |
| Complete Stage 5 acceptance | Review dirty lead forms/actions/campaign UI; include intended configuration migration in replay; finish desktop/mobile and security checks. | Medium |
| Reconcile public/staging | Convert approved content review/edit-history changes into a safe target-schema release plan; verify all current routes/RPCs together. Do not simply select staging globally. | Medium |
| Standardise permissions/offboarding | Enforce one authorization role plus scope/capability grants; align active-user checks across legacy and new modules; harden null-scope policies and legacy helper grants. | Medium |
| Make operation observable | Separate process health from auth/database/schema readiness; inventory dormant Stripe APIs, migration packaging and configuration prerequisites. | Low/Medium |
| Prepare release/recovery runbook | Identify applied migration ledger, real configuration ownership, backup/restore evidence and rollout/rollback sequence when live access is authorised. | Medium/High |

### Acceptance criteria

- Selected commit plus any intended changes is explicitly recorded; no unknown dirty application files enter the candidate.
- Reviewed forward migration manifest excludes rollback scripts and includes every UI/RPC dependency, including approved campaign configuration.
- A clean disposable replay passes public target-schema route dependencies. Legacy approval/edit history and new workforce/file/lead features function in the chosen target configuration.
- Existing local matrices pass at the selected revision: Stage 1 60, Stage 2 35, Stage 3 60, Stage 4 92, Stage 5 60 and approval regression 35, plus meaningful tests for new changes. Historical counts are a regression baseline, not proof of complete coverage.
- Typecheck, lint and build pass for that candidate; desktop/mobile workflows complete and negative direct-route/API tests pass.
- Multiple-role ambiguity is resolved with safe treatment of existing assignments; inactive identities are denied throughout the app and direct data paths.
- Anonymous, cross-company/department, restricted-record and arbitrary-subject RPC probes reveal no unauthorized rows, links, titles, snippets or counts.
- A runbook identifies the environment, deployment commit, required non-secret variable names, schema/migration prerequisites, rollback/restore responsibility and incident contacts.
- **Separate operational gate:** after explicit hosted-change approval, verify real hosted migration/grant state, backup/restore evidence, current runtime/readiness and scoped real-user UAT. Until this gate succeeds, report the candidate as local-only.

### Security considerations

Do not use service-role access for normal employee retrieval. Harden legacy security-definer functions, EXECUTE grants and search paths; retain caller-bound predicates and security-invoker summaries. Coordinate session revocation and provider access removal on departure. Review effective grants as well as RLS. Never put restricted PII into generic tasks or move production credentials into test environments.

## 3. P1 — Knowledge Base and SOP 2.0

**Outcome:** Staff can find and execute a current, approved, appropriately scoped procedure with accountable ownership and exact version history.

**Dependencies:** P0 permission/schema baseline; Director-approved source authority, publication roles, storage model and company applicability. Named owners for pilot documents.

**Complexity:** Medium overall; immutable publication/access controls require careful design.

| Work package | Reuse / change | Complexity |
|---|---|---|
| Master knowledge register | Extend master_files and existing KB/SOP routes; connect source assets, controlled categories and scoped applicability. | Medium |
| Controlled content revisions | Add immutable revisions, authority/provenance, owner/reviewer, effective dates, review deadlines, change reasons and approval events. | Medium |
| Publication/archive workflow | Guard transitions in database; retain history, activate/supersede atomically, prevent direct published edits/deletes. | Medium |
| SOP-task-evidence linkage | Pin assigned tasks to approved revision; specify evidence/template requirements and audited exceptions using existing artifacts/supervisor workflow. | Medium |
| Staff retrieval and suggestions | Add permitted current-content search, approved forms and simple owner-triaged feedback queue. | Low/Medium |
| Curate initial knowledge | Register and review critical SOPs/templates and approved Custom GPT source material. Preserve old IDs/source mapping; no mass auto-publication. | Low technically; significant owner effort |

### Acceptance criteria

- Pilot has 5–10 critical procedures with company/department applicability, owner, reviewer, authority, source provenance, approved revision and review due date.
- Ordinary permitted staff can retrieve appropriate approved material; unpublished/restricted material remains invisible through UI, direct APIs, search, related links and counts.
- A published content edit creates a draft revision; the old approved snapshot remains unchanged and recoverable. Unauthorized actors cannot publish or backdate approvals.
- Only one effective approved revision applies per defined document/scope at a given time. Future-dated revisions do not replace today's instructions early.
- Approval/rejection/supersession/archive events retain actor, timestamp and reason. Published revisions cannot be hard-deleted through ordinary user actions.
- One pilot task pins an SOP revision and template, records required evidence and supervisor verification; changing the SOP later does not silently rewrite task history.
- External source changes do not alter an approved snapshot. Missing/broken links and source-content drift appear for owner review.
- Staff can submit a suggestion, and an owner can accept/reject it with a recorded decision; acceptance creates a separate reviewed revision.
- Existing legacy knowledge is classified as unreviewed on intake until a responsible reviewer approves it. Staff can trace a legacy ID to its controlled record.

### Security considerations

Permission inheritance must cover masters, revision bodies, archived snapshots, chunks, forms and suggestions. Group-wide relevance must be explicit and must not broaden confidential access. Align source-system sharing with IEOS access. Retention/archive is controlled preservation, not removal of legal or personal-data obligations; Director sets policy with appropriate advice. No arbitrary URL fetch in the initial link-register extension.

## 4. P2 — Staff Training and Succession

**Outcome:** A supervisor can see who is ready to perform each critical process and where the company lacks trained cover.

**Dependencies:** P1 approved revision/evidence model; Director-approved job roles, critical process list, assessors, backup expectations and access to personnel assessments.

**Complexity:** Medium. Keep this within IEOS; no separate LMS, HR suite or performance-scoring engine.

| Work package | Reuse / change | Complexity |
|---|---|---|
| Job-role onboarding | Small job-role catalogue and staff-role assignments; role-SOP requirements/checklists. Authorization roles remain separate. | Low/Medium |
| Training assignments | Person/requirement/revision/due date, acknowledgement and linked practice work task. | Medium |
| Practical assessment | Reuse work tasks/artifacts; append attempts with supervisor outcome/evidence and validity. | Medium |
| Competency/refresher view | Derive readiness from mandatory requirements; expiry/change-based refresher exceptions. | Low/Medium |
| Process cover and handover | Primary owner, nominated backup, task-backed handover checklist and verified transfer evidence. | Medium |
| Succession dashboard | Extend scoped exception dashboard with no ready backup, inactive owner, overdue training and incomplete handover. | Low/Medium |

### Acceptance criteria

- Pilot onboarding for one staff role and one intern role generates the correct required SOP assignments without granting additional permissions.
- Acknowledgement, training completion, supervised practice and independent competency remain distinct.
- An authorised assessor records a practical pass/correction with evidence; staff cannot self-certify, and earlier attempts remain unchanged.
- Competency is derived from all mandatory current requirements. “Competent” cannot be manually toggled without the qualifying facts.
- A major SOP revision or expired assessment creates a targeted refresher/reassessment requirement; prior qualifications remain available historically.
- Each pilot critical process has a primary owner and nominated backup. Dashboard distinguishes “nominated” from “ready.”
- Inactivating an owner creates a continuity exception and blocks new unauthorized access; historical assessment/audit attribution remains.
- A sample handover checklist covers open work, approved SOPs/templates, source ownership, permissions and successor verification, with authorised evidence.
- Managers see only personnel/continuity details in scope; restricted assessment notes do not appear in generic task or team views.

### Security considerations

Training/assessment is personnel data. Restrict assessor rights and sensitive notes; log changes to requirements and assignments. Avoid public rankings or automated employment decisions. Transfer provider access using approved identity controls, never passwords in handover notes. Where a task is operational and its assessment is private, link records without duplicating private notes into the task.

## 5. P3 — Employee AI Assistant

**Outcome:** Employees receive source-cited guidance from permitted current approved knowledge and task-specific SOP requirements.

**Dependencies:** P0/P1 stable authorization, snapshots and approval; optional P2 job/training context; Director approval of AI provider, data classes, retention and cost envelope. Approved Custom GPT material is reviewed through P1 before use.

**Complexity:** High for security/evaluation; begin with a small read-oriented assistant and database full-text retrieval.

| Work package | Reuse / change | Complexity |
|---|---|---|
| Permission-aware knowledge service | Retrieve allowed approved/effective revision content and templates; include task-pinned historical revision where appropriate. | Medium |
| Guided assistant interface | Explain SOP steps and task evidence with exact document/revision/section citations, missing-info questions and owner escalation. | Medium |
| Feedback/draft assistance | Confirmed suggestions and SOP drafts using P1 human-review workflow; no autonomous publication. | Medium |
| Retrieval/evaluation | Curated question set, citation checks, no-answer cases, permission tests, conflict and prompt-injection tests. | High |
| Operational controls | Per-user/company permissions, cache invalidation, minimal redacted audit, rate/spend limits and fallback to ordinary SOP pages. | Medium |

### Acceptance criteria

- Every retrieved source is authorized before its content reaches the model; no unrestricted corpus prompt or cross-user cache.
- A Director-approved test set covers staff/intern/manager, different companies/departments, confidential material, inactive users, superseded/future-effective versions and task-pinned revisions.
- Security test cases produce **zero restricted disclosures**, including filenames, source identifiers, snippets and counts. Any failure blocks release.
- Procedural/policy answers cite exact approved source revision and section; no fabricated source IDs or unsupported policy claims pass the evaluation.
- The assistant refuses or escalates when current approved evidence is absent or contradictory. It does not invent policy or claim task completion.
- Revoking access or superseding content prevents it appearing in subsequent new guidance; historical task guidance remains permission-checked and clearly labelled.
- A template answer returns a permitted approved template and its revision; a task answer lists the correct pinned SOP and evidence requirements.
- Malicious source text cannot expand tool permissions, exfiltrate data or modify published knowledge.
- Feedback requires employee confirmation and creates a suggestion only. SOP drafts remain drafts until approved by authorised humans.
- The pilot has an agreed helpfulness target, latency/cost budget and fallback procedure; normal IEOS work continues when AI is unavailable.

### Security considerations

Treat prompts, chat history, extracted source text and embeddings as data governed by the source's confidentiality. Use an approved provider/contract and narrowly scoped tools. Keep credentials server-side; do not forward service-role keys or restricted full records to models. Recheck user activity/access on every request. AI explanations and operational feedback must never become policy through automated ingestion.

Architecture detail and Drive/Supabase trade-offs are in [Knowledge Gap Analysis](IEOS_KNOWLEDGE_GAP_ANALYSIS.md). Optional GPT Action/plugin interfaces should use the same authenticated knowledge service.

## 6. P4 — Integrations and Automation

**Outcome:** Reduce repetitive entry while preserving each source system's authority and human controls.

**Dependencies:** P0–P3 foundations relevant to each integration; Director-approved system ownership, data-sharing boundaries and write permissions; vendor/API/licensing discovery. Existing integrations must be evidenced before reuse is claimed.

**Complexity:** High and variable. Deliver one adapter at a time, beginning with read-only/manual reconciliation.

| System/capability | Recommended first boundary | Complexity / unresolved dependency |
|---|---|---|
| Google Drive | Company-owned source register, authorised change/availability checks, reviewed snapshot candidates and ACL reconciliation | Medium/High; identity/Drive ownership and API permissions not verified |
| GoHighLevel | Restricted external contact/pipeline IDs, follow-up tasks and status summaries; CRM remains contact authority | High; API plan, field mapping, consent/access and duplicate ownership unverified |
| Finance/Vercel App | Authorised status/record references and management summaries; Finance retains transactions/reconciliation | Medium/High; deployed contract and owner unverified |
| SQL Accounting | Read-only report/export ingestion with reconciliation and provenance before any posting capability | High/unknown; edition, licensing, approved access method and vendor support unverified |
| ChatGPT Plugins/Custom GPT interfaces | Authenticated read-oriented connector to governed knowledge/tools; same identity and ACL checks | Medium/High; workspace availability, identity mapping and approved publication channel unverified |
| Existing AI agents | Inventory tools/owners/data scopes; provide bounded authenticated endpoints and logged confirmed writes | High; no verified IEOS integration found |
| Recurring work | Task schedule/template with pinned SOP rules, timezone, due date, assigned owner, occurrence ledger and pause/resume | Medium; add scheduler only after base task model and operational calendar are stable |

### Acceptance criteria

- Each adapter has a named owner, source-of-truth field map, permitted data classes, identity mapping and approved read/write scope.
- Initial read-only pilot reconciles against source totals/IDs without copying restricted PII into generic work tables or creating duplicate financial records.
- Replayed/retried events do not create duplicates. Use unique source IDs/event IDs, bounded retry/backoff and visible failed-sync exceptions.
- Unauthorized users cannot access imported data via tasks, dashboards, tools, logs or aggregate counts.
- Source edits/removals/access revocation follow defined invalidation and reconciliation rules; integrations cannot publish knowledge autonomously.
- An outage can be detected, paused and resumed; manual work remains available and synchronization records last-success/error without secrets.
- Recurrence generates at most one task per schedule/occurrence. The pilot tests missed runs, pause/resume, holidays/weekends, reassignment and Asia/Kuala_Lumpur due dates.
- Generated tasks use an eligible approved SOP revision at occurrence creation, record it immutably, and stop/escalate if none is eligible. They do not mark themselves complete.
- External writes remain disabled until a separately approved pilot demonstrates validation, reconciliation, audit and recovery.

### Security considerations

Validate webhook authenticity where used; isolate integration credentials and rotate them via the approved secret store. Limit data scopes; do not give integration identities Director-equivalent access. Secure extracted content, logs and exports as carefully as original records. Keep accounting postings and CRM changes behind explicit business authorization and vendor-supported interfaces.

## 7. Recommended rollout and management controls

1. Complete P0 local acceptance and obtain a concrete release decision. Resolve environment recovery separately.
2. Pilot P1 with one department and the highest dependency processes; test approved versions through real task/evidence workflows.
3. Extend P2 to those same processes and confirm at least one assessed backup per critical process, or visibly record the gap.
4. Pilot P3 on low-sensitivity approved knowledge. Expand only after permission/citation/refusal checks pass.
5. Prioritise P4 based on demonstrated recurring workload and source-system readiness, not connector availability.

For each release retain candidate revision, migration manifest, test outcomes, owner UAT, known limits, operational support and rollback/restore plan. Director-level decisions are isolated in [Architecture Decisions Required](IEOS_ARCHITECTURE_DECISIONS_REQUIRED.md); routine indexes/UI details stay with the implementation team.

No implementation, migration, dependency installation, deployment, push or commit was performed during this audit. Stop here and await Director approval.
