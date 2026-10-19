# IEOS Knowledge and SOP Gap Analysis

**Date:** 12 October 2026, Asia/Kuala_Lumpur  
**Basis:** Read-only review of the latest local IEOS Stage 5 worktree, including uncommitted changes. See [Current State Audit](IEOS_CURRENT_STATE_AUDIT.md) for exact revisions, evidence paths and verification limits.  
**Recommendation:** Reuse the existing application and master file register; modify KB/SOP into controlled knowledge; add training and permission-aware AI only after governance works.

## 1. Interpretation

REUSE means retain an existing bounded capability. MODIFY means extend/change a current capability, possibly with additive tables. ADD means the required capability is absent. Priorities refer to the proposed P0–P4 roadmap, not the repository's historical numbered stages. Statuses describe local implementation; all current hosted features remain **Cannot verify**.

## 2. Knowledge requirements comparison

| Requirement | Existing Feature | Current Status | REUSE/MODIFY/ADD | Priority | Risk | Recommended Action |
|---|---|---|---|---|---|---|
| Master Knowledge Register | Stage 4 master file register with identifiers, search, owner, categories, status, links and audit | Partially implemented for knowledge; file-register capability historically tested | MODIFY | P1 | High: duplicate/conflicting masters | Use master files as canonical source-asset register; link knowledge/SOP records and immutable revisions to it. Provide one knowledge register view rather than another unrelated file list. |
| Classification by company and department | Organisation/business-unit/department FKs; SOP department; master files require both scopes; KB lacks them | Partially implemented | MODIFY | P0/P1 | High: cross-company disclosure or inaccessible knowledge | Retain hierarchy, classify KB explicitly, validate department belongs to business unit. Use deliberate group-wide applicability, never null scope as permission. |
| Source authority levels | File categories and source-system labels; no authority field/rules | Not implemented | ADD | P1 | High: draft/AI text treated as policy | Controlled authority taxonomy: approved company policy, approved SOP/template, validated external reference, draft/informal. Preserve provenance and applicable scope. Escalate conflicts rather than letting AI resolve precedence. |
| Document owner and reviewer | Master-file owner; SOP creator/drafter; KB creator column not populated by create input | Partially implemented | MODIFY | P1 | High: orphaned or self-approved knowledge | Assign accountable owner and reviewer, approval actor/time, review due date and reassignment on departure. Creator remains distinct from owner. |
| Version control and effective dates | Mutable SOP version text; master-file row_version and supersession relation | Partially implemented | MODIFY | P1 | High: wrong instructions; history unrecoverable | Add immutable content revisions, unique revision numbers, effective_from/to, content hash, change reason and selected published revision. Row_version remains concurrency control. |
| Approval and publication workflow | Content approval RPCs/actions in staging; file current/under_review states | Partially implemented; no KB/SOP publication | MODIFY | P1 | High: unapproved material used operationally | Reuse guarded RPC/event patterns, not content-specific approval tables blindly. Draft → in_review → approved → effective; rejected drafts return for correction. Enforce reviewer authority in database. |
| Superseded document archiving | Master-file superseded/archived status and links | Implemented and tested for file metadata; partial for knowledge | MODIFY | P1 | High: old versions used or erased | Reuse file lifecycle; retain immutable historical knowledge revisions. Hide superseded versions from normal search, preserve restricted history and tasks pinned to them. |
| Confidentiality and role-based access | Master-file/task sensitivity and explicit grants; KB management-only; SOP scope/null-scope gaps | Partially implemented | MODIFY | P0/P1 | High: restricted metadata/content leakage | Share one active-user/scope/capability policy across register, revisions, search, templates and assistant. Deny by default; test direct APIs, IDs, counts and inactive identities. |
| SOP ownership and trained backup | File owner and SOP drafter only | Partially implemented | MODIFY | P2 | High: single-person dependency | Add process owner and backup relationships. Backup readiness must derive from current required training and practical supervisor assessment. |
| SOP-linked tasks and required evidence | Generic task instructions, final/evidence artifacts, waivers; master-file task/artifact joins | Partially implemented | MODIFY | P1 | High: task completed using wrong procedure | Pin SOP revision on assignment; specify required evidence type/checklist, supervisor review and audited exceptions. Reuse work tasks and artifacts. |
| Official templates and master records | Master-file form/template categories, current status and source URLs | Partially implemented | MODIFY | P1 | High: unofficial forms used | Mark approved template revision, purpose, owner and effective period. Link tasks/SOP steps to required templates; keep executed copies/evidence separate from the master. |
| Role-based knowledge retrieval | SOP department filter, RLS, master-file metadata search | Partially implemented | MODIFY | P1/P3 | High: inaccessible employee knowledge or leakage | Separate business job role from authorization role. Add approved/effective filtering and scoped content search. Role filtering narrows relevance; it never grants access. |
| Staff feedback and suggested improvements | Task comments and supervisor feedback; no knowledge improvement workflow | Not implemented for knowledge | ADD | P1 | Medium: useful knowledge disappears or changes without review | Simple suggestion queue linked to document/revision/task, submitter and owner; human triage, decision and resulting revision link. No direct mutation of published content. |
| AI-assisted SOP drafting with human approval | Keyword suggestions; no LLM/content drafting workflow | Not implemented | ADD | P3 | High: hallucinated process becomes policy | Produce draft only, using permitted source material and visible provenance. Owner/reviewer confirms accuracy through the P1 workflow; never auto-publish. |
| Approved knowledge from existing Custom GPTs | No corpus mapping/import or integration found | Not implemented | ADD | P1 intake; P3 tooling | High: stale, restricted or unsupported material | Inventory owner-approved source files/instructions, classify and deduplicate, record provenance and approval. GPT answers are suggestions, not authoritative company knowledge. |

Evidence: `supabase/migrations/0001_init.sql`, `0003_auth_access_rls.sql`, `20260913053937_stage4_master_file_register.sql`; `lib/data/knowledge-items.ts`, `lib/data/sops.ts`, `lib/actions/knowledge.ts`, `lib/actions/sops.ts`; `supabase/staging/006_approval_workflow.sql`–`008_approval_security_hardening.sql`; historical Stage 4 test/UAT artifacts identified in the Current State Audit.

## 3. Small-company knowledge design

Keep the existing master file register as the authoritative directory of source assets, including Drive documents, forms and templates. Keep KB and SOP IDs and routes during migration. Add shared revision/publication controls that both modules use; their content can remain distinct.

Suggested additive model, subject to implementation design after approval:

| Object | Purpose | Existing capability reused |
|---|---|---|
| Knowledge/SOP master metadata | Stable identity, business-unit/department applicability, type, authority, owner, reviewer, confidentiality, source master_file_id, review_due_at | Existing knowledge_items/sops/master_files and scope/grant patterns |
| Shared document revision records | Exact immutable body/steps, revision number, source snapshot reference, hash, change reason, author, effective dates and lifecycle | Existing content fields migrated non-destructively into initial **unapproved** revisions |
| Publication/review events | Submission, approval/rejection, activation, supersession and retirement with actor/time | Existing guarded RPC, append-only event and concurrency patterns |
| Task-SOP requirements | Assigned task → exact revision, required output/template/evidence and exception reason | Existing work_tasks/work_task_artifacts; master-file joins remain asset relationships |
| Knowledge suggestions | Proposed correction/improvement, source revision/task, triage status, decision and resolution revision | Existing task feedback/UI conventions |

A shared revision table can use validated foreign keys to KB or SOP masters with an exactly-one-parent constraint. Avoid an unconstrained “table name + record ID” relationship as the sole integrity mechanism. Do not build a generalized workflow engine or a separate enterprise document platform.

Start publication with one appointed reviewer per process; Director approval is required for policy or restricted categories. The reviewer should normally be different from the drafter. If staffing requires self-review, permit only an explicit, audited Director exception for low-risk documents. Approval does not grant broader access.

Approved content is immutable. A correction creates a new draft. Approval and effective date are separate: future-effective material must not displace today's procedure prematurely. Activation/supersession must be atomic, preventing two contradictory current revisions for the same scope. Scheduled effective-date selection can be query-based before a scheduler is introduced.

Changing a Drive document behind an existing URL must not silently change the published revision. Retain an approved snapshot/content hash and show when the live source differs. A source-edit notification creates a review candidate; it cannot publish itself. The initial manual owner-review process can work before a Drive API integration.

## 4. Training and succession gaps

No training, competency or succession schema/workflow was found. Existing tasks, daily logs and reviews are reusable execution evidence, not proof that employees understand or can independently perform a process.

| Requirement | Existing Feature | Current Status | REUSE/MODIFY/ADD | Priority | Risk | Recommended Action |
|---|---|---|---|---|---|---|
| Role-specific onboarding | Profiles and four authorization roles | Not implemented | ADD | P2 | High: inconsistent onboarding | Controlled job-role checklist and staff/intern role assignment; keep separate from super_admin/management/staff/intern permissions. |
| Required SOP/training assignments | Work assignment and external training-material file category | Partially implemented | MODIFY | P2 | High: missed critical training | Generate simple training assignments from job-role requirements, pinned to approved revisions. |
| Training completion | Daily outputs and task completion | Not implemented as training | ADD | P2 | Medium: reading mistaken for capability | Record acknowledgement and training date separately from practical assessment. |
| Practical task assessment | Task/evidence/supervisor workflow | Partially implemented | MODIFY | P2 | High: unsupported competency claims | Link a sample work task and required evidence to an assessment rubric with pass/correction outcome. |
| Supervisor verification | Append-only daily reviews and task final approval | Partially implemented | MODIFY | P2 | High: self-certification | Record authorized assessor, outcome, date and evidence; keep prior attempts. Do not equate generic task approval with qualification. |
| Competency status | No competency model | Not implemented | ADD | P2 | High: unqualified staff relied on | Derive not_started, learning, supervised_only, competent, refresher_due from current requirements/assessments. |
| Refresher training | No training expiry/recurrence | Not implemented | ADD | P2 | Medium: stale competence | Review_due/expiry dates and affected-revision flags; start with dashboard/manual assignment, automate later. |
| Primary process owner | Master-file owner only | Partially implemented | MODIFY | P2 | High: missing accountability | Explicit process-owner relationship; appoint replacement when profile inactive. |
| Trained backup/successor | No readiness model | Not implemented | ADD | P2 | High: key-person dependency | Backup nomination plus derived readiness from current required assessments; nomination alone is insufficient. |
| Handover checklists and evidence | Tasks, artifacts, comments | Partially implemented | MODIFY | P2 | High: lost access/files/context | Handover task with owner/backup, approved SOPs, open work, source ownership, permission transfer and evidence checklist. Never hand over passwords in task text. |
| Succession-risk dashboard | Scoped task dashboard | Not implemented for succession | ADD | P2 | High: unrecognised continuity risk | Add scoped exceptions: no owner, no ready backup, overdue refresher, pending handover or inactive owner. No employee ranking/automated HR decision. |

### Minimal maintainable training model

Use the same app and database, with a small set of focused records:

1. **Job roles and staff job-role assignments:** controlled job-role names; one person can hold several business responsibilities without receiving several conflicting authorization roles.
2. **Role-SOP requirements:** job role, required SOP/revision, whether practical assessment is required, renewal period and evidence rubric.
3. **Training assignments:** person, requirement, pinned revision, due date, acknowledgement/training timestamps and optional linked work task.
4. **Training assessments:** append-only attempts, assessor, outcome, observed task/artifact, notes and validity dates.
5. **Process responsibilities:** process/SOP, primary owner and nominated backup(s); readiness derived from evidence.
6. **Handover items:** task-backed checklist items and completion/evidence/verification.

This represents seven focused tables if job roles and person-role assignments are separate. Keep competency as a query/view over these facts initially, rather than another freely editable score table. Reuse existing profiles, task artifacts, audit and confidentiality controls.

Start with 5–10 critical processes in one department. Reading the SOP satisfies acknowledgement only. “Competent” requires all mandatory current requirements and required practical passes. A major SOP change marks affected people for reassessment; minor editorial changes can retain qualification after owner confirmation. Preserve prior version qualifications for historical audit.

When an owner leaves, retain their historical identity, disable access and nominate a new owner; check the backup's evidence, open tasks, file ownership and provider permissions. Expose missing cover as a continuity exception. Personnel assessment details remain available only to the employee and authorised supervisors/Director/HR; ordinary colleagues may see approved cover arrangements without private assessment notes.

## 5. Employee AI Assistant: recommended architecture

### Trusted retrieval flow

1. IEOS verifies the current session, active profile, scopes and capabilities server-side. The user cannot choose another profile ID to gain permission.
2. If a task is selected, verify task access first. Fetch its pinned SOP revision, output requirements, approved template references and permitted artifacts.
3. Search only permitted, approved, currently effective knowledge. For historical task context, deliberately retrieve its pinned revision and clearly indicate if superseded; never silently substitute a new process.
4. Apply authorization in the database/retrieval service **before** text enters a model. Search titles, snippets, counts, chunks and related sources must obey the same visibility rule.
5. Return a bounded source pack: stable document ID, exact revision, section/step, effective date, source reference/hash and authorised link. The model explains these sources step by step.
6. Validate cited source IDs against the retrieved pack. Refuse unsupported policy claims; explain absent evidence and route unresolved questions to the named owner/reviewer.
7. Offer a separate feedback submission, confirmed by the employee, linked to source/task. It creates a suggestion and audit event, never changes approved knowledge.

Initial tools can be limited to **search approved knowledge**, **get approved revision**, **get my permitted task guidance**, **get approved template**, and **submit knowledge suggestion**. No shell, unrestricted SQL, arbitrary URL crawling, publishing, account changes or transaction-writing tool is needed.

### Required assistant behaviour

| Behaviour | Design control |
|---|---|
| Explain SOPs step by step | Use stored step/section identifiers, prerequisites, decisions, required output and escalation points; distinguish source instructions from explanation. |
| Guide assigned work | Read authorised task context and pinned SOP; show evidence checklist and submission/review route. It does not mark work complete automatically. |
| Cite exact source/version | Every procedural/policy claim cites document ID, revision and section/step; preserve effective date and snapshot hash in audit context. |
| Retrieve forms/templates | Return only authorised approved master/template revisions; show how to create a working copy without overwriting the master. |
| Identify missing information | State which prerequisite or approved guidance is absent. Ask for necessary task context without requesting restricted data in generic text. |
| Escalate policy conflicts | Present permitted conflicting sources with versions/applicability; refer to owner/reviewer/Director. Abstain until resolved. No model-created policy compromise. |
| Avoid restricted disclosure | Same RLS/capabilities as UI, permission-bound caching, denied-source IDs omitted, no all-company prompt corpus or role inferred from the conversation. |
| Handle hostile source instructions | Treat document text as evidence, not instructions to change tools/security. Restrict tools and destinations; evaluate prompt injection. |
| Record useful feedback | Confirmed suggestion queue; human triage and separate approved revision workflow. Redact/minimise sensitive feedback and logs. |
| Respect revocation/freshness | Recheck active status and access each request; invalidate permission/content caches on revocation, supersession or publication. Do not reuse another user's chat context. |

Use database full-text search first for a small curated corpus. Add vector/hybrid search only if measured retrieval quality requires it. Every indexed chunk must belong to one exact revision and inherit current authorization; an embedding is not an access-control boundary. Retired or revoked sources must stop appearing in new answers even if older index entries remain.

The ingestion worker may need a narrowly scoped server identity. Employee retrieval should use user-session policies or an equally constrained server capability service, not unrestricted service-role searches followed by model filtering. Service credentials stay server-side. AI availability must not block ordinary SOP/task access.

### Google Drive versus Supabase

| Aspect | Drive source documents | Structured Supabase knowledge |
|---|---|---|
| Strength | Familiar authoring/collaboration and existing source assets | Workflow relationships, immutable approved snapshots, exact task/revision links and consistent RLS |
| Main weakness | Live URL content and sharing can change independently of IEOS approval | Requires controlled extraction/curation; duplicates can drift if source ownership is unclear |
| Exact version citation | Requires retained approved export/snapshot; do not assume a mutable URL proves the content used | Revision ID, body/steps, effective dates, hash and source provenance are directly queryable |
| Permission alignment | Drive ACL and IEOS policy must both be satisfied for linked source access | Same database policy can govern metadata/content/chunks; binary storage still needs separate controls |
| AI retrieval | Needs authorized extraction and freshness/ACL handling | Easier to filter approved/effective content before generation |
| Maintenance | Lower authoring friction; connector/ACL reconciliation needed for automation | Small structured records are maintainable; avoid copying every external document |

**Recommended hybrid:** Keep editable originals and binary assets in company-controlled Drive; reuse IEOS master_files for metadata/links; store reviewed structured text/steps and immutable published snapshots in Supabase, with source provenance. Drive remains the authoring source; the approved IEOS revision is the operational authority consumed by tasks and AI. Decide this authority explicitly before rollout.

A manual, reviewed snapshot process is sufficient for P1. P3 needs access to approved snapshots; full Drive synchronisation can wait until P4. Thus the assistant does not depend on building all integrations first.

Drive's API revision list may be incomplete for frequently edited Google documents and does not replace retained approval evidence. Its sharing model is independently managed. [Google Drive revision guidance](https://developers.google.com/workspace/drive/api/guides/manage-revisions), [Drive permissions guidance](https://developers.google.com/workspace/drive/api/guides/manage-sharing).

### Custom GPTs and ChatGPT Plugins

Inventory the approved source documents and instructions behind existing GPTs; obtain the owner's controlled export/provenance and review in P1. Preserve accepted knowledge and useful drafting instructions. Do not ingest private chat histories by default, treat generated answers as authoritative, or assume an API exists for calling any Custom GPT from IEOS.

Official OpenAI documentation describes GPT Actions as Custom GPT calls to external APIs. A future GPT Action or plugin/MCP connector can therefore call an authenticated IEOS knowledge endpoint, subject to the same permissions. That is an optional additional interface; it does not establish an existing IEOS integration. [GPT Actions](https://developers.openai.com/api/docs/actions/introduction).

OpenAI also documents migration of GPT instructions/reference files to plugin skills, while custom actions need separate replacement. This may preserve existing workflows, but workspace feature access and the users' actual GPT inventory were not verified in this audit. [Custom GPT workflow migration](https://learn.chatgpt.com/docs/migrate-custom-gpts).

No AI assistant, connector, ingestion job or database change was implemented.
