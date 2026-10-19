# IEOS P1 Knowledge Reuse Notes

Date: 12 October 2026, Asia/Kuala_Lumpur. **Planning notes only. No P1 implementation or knowledge import was performed.** Continue the existing IEOS architecture; do not rebuild the application.

P0 has stabilised the existing runtime, public approval compatibility and access boundary. It has not created a Master Knowledge Register, immutable SOP revisions, training records, successor tracking, retrieval index or Employee AI Assistant. The four original audit reports remain the requirements reference.

## Confirmed reusable components

| Existing component | Reuse in P1 | Confirmed dependency / boundary |
|---|---|---|
| organisations → business_units → departments | Classify knowledge within one Inter Excel organisation and IETA/IEA/PLC/KALER units | D1 approved in principle; detailed company/department matrix and activation still require Director acceptance. Existing IDs should be retained. |
| profiles, user_role_assignment and scope grants | Authenticated person/owner/reviewer identity; one application role with separate scoped duties | P0 unique role/RPC and inactive denial pass. Do not encode each business responsibility as another application role. |
| getCurrentUser and server Supabase client | Reuse current session/activity checks for pages/actions | Database RLS/RPC remains the authority; UI filtering alone cannot protect restricted knowledge. |
| sops and SOP list/detail/form | Preserve current SOP IDs, department links, content and user familiarity | Existing version field is mutable metadata, not immutable publication history. Null-scope entries are Super Admin-only until reviewed. |
| knowledge_items and legacy KB UI | Preserve source material, categories/tags and references during controlled migration | P0 access is Super Admin-only because company/confidentiality fields are absent. No automatic conversion into approved policy; steward review and classification are required. |
| master_files, categories, grants and events | Use as the master source/form/template register and governed external-link metadata | Stage 4's confidentiality, lifecycle, verification and relationships pass 92 assertions. Metadata/current-file designation is not proof that the content is an approved SOP revision. |
| Master-file register/search/detail/review UI | Reuse company/department filters, current-first search, verification and review/cleanup patterns | Preserve source provider links and existing file purposes; add only knowledge-specific relationships when P1 is approved. |
| work_tasks, work_task_artifacts and task events | Link an assigned task and its required evidence to the exact SOP revision used | Stage 1 remains the generic work domain. Do not replace content_tasks/content_items or copy restricted source text into public task summaries. |
| content_tasks.sop_id and legacy output workflow | Preserve current marketing task/SOP links and evidence behaviour | Existing link identifies a mutable SOP, not a historical approved version. Add a compatible revision reference later while retaining the legacy link. |
| daily_work_updates and daily_update_reviews | Preserve actual output and supervisor evidence review | Reading an SOP or a checked daily update is not a competency certificate. Training/assessment is P2. |
| Public approval categories/actions/edit logs and guarded RPC patterns | Reuse submission, attributed decisions, required revision comments, row locks and guarded transitions | Public and staging approval matrices both pass. These tables currently govern content_items; do not pretend content approval already publishes knowledge. Adapt the pattern to a bounded knowledge domain after D2. |
| Scoped Stage 1–5 capability/record grants and confidentiality classes | Retain operational, full-time, management, appointed and P&C vocabulary with explicit appointments | Avoid parallel competing ACL vocabularies. Unknown content stays denied until classified. Test rows, snippets, source links, archives, search counts and citations. |
| Immutable events and P0 application_access_events | Reuse actor attribution and audit design for publication/access changes | P0 access events are Super Admin-only role/activity history; they are not a general knowledge revision store. |
| Attention/review and dashboard patterns | Add small, actionable overdue-review/currentness views when authorised | Do not implement rankings, training dashboards or knowledge health measures during P0. |
| Disposable harness, negative tests and /api/ready | Extend tested baseline for knowledge dependencies and regression | Keep explicit migration manifests and fresh local replay; retain Stage 1–5 suites. Readiness needs updating with future actual dependencies. |

The confirmed SQL/UI foundation is reusable. The absence of publication governance cannot be solved by treating existing mutable rows, Drive edits or AI answers as approved revisions.

## Simplest maintainable P1 direction, subject to approval

Reuse the current master-file register for source ownership and official templates. Give each knowledge/SOP entry a stable register identity, classification and accountable owner, with a small immutable revision record containing approved content/source snapshot, version, effective dates, reviewer and decision. Link superseded revisions instead of overwriting approved text. Keep comments/suggested improvements separate from approved content.

Adapt the existing guarded approval pattern rather than building a generic rules engine. Default retrieval should use only the current effective approved revision within the caller's company/department/confidentiality scope. Retain direct relationships to the exact revision used by a task. Preserve old IDs and legacy material through reviewed adoption; do not silently mark it approved or destroy prior context.

The existing master_files current/superseded/archive lifecycle can support source records, but knowledge revision status needs its own explicit publication meaning. A current Drive link or edited SOP version string must not automatically replace approved knowledge.

If D3 adopts the audit's hybrid recommendation, company-controlled Google Drive remains the authoring/binary source, while IEOS/Supabase owns approval metadata and retained approved snapshots. Drive ACLs and source ownership must be reconciled separately; IEOS permission to see a link does not grant or revoke provider access. No sync, download, snapshot ingestion or AI embedding was implemented in P0.

## Dependencies before P1 starts

| Dependency | Confirmed P0 position | Required approval / action |
|---|---|---|
| P0 acceptance and release baseline | Local candidate passed; no hosted release | Director accepts bounded P0 and separately authorises the environment/next implementation scope. |
| D2 source authority and publication accountability | Not approved by the P0 instruction | Approve knowledge authority levels, owners/reviewers, publication delegation, review cycles and policy-conflict escalation. |
| D3 source storage/ownership | Not approved by the P0 instruction | Choose Drive/Supabase authority, approved snapshots and company-controlled source accounts. |
| D1/D4 detailed access | Approved in principle; tested scoped/default-deny mechanisms | Approve actual unit/department/restricted-access matrix, stewards and retention/offboarding responsibilities. |
| Legacy inventory | All records/source paths retained; no bulk import or classification | Review SOPs/KB/master-file overlap, unknown scope, duplicates, source ownership and confidentiality without treating tags as authority. |
| Hosted adoption and data/ledger compatibility | Not verified locally | Complete separately authorised inventory/recovery rehearsal before any hosted migration. |
| Revision/task design | Existing SOP/task IDs and evidence domains reusable | Add compatible exact-version relationships; preserve existing tasks and history. |
| Acceptance/security tests | Existing Stage 1–5, approval and P0 suites pass | Add P1 tests for draft/approved/effective/superseded visibility, immutable history, denied search/count/snippet/link leakage, owner/reviewer transitions and concurrent updates. |
| Custom GPT/AI source material | No ingestion performed | Inventory company-controlled source documents. Human review/classification comes before publication; GPT answers are not authoritative source documents. D6 is needed before model exposure in P3. |

## Scope reserved for later phases

Role onboarding, SOP/training assignments, practical assessment, verified competency, refresher dates, trained backup and handover evidence remain P2 under D5. The Employee AI Assistant, permission-aware retrieval/citations and human-reviewed drafting remain P3 under D6. CRM, finance, accounting, Drive synchronization, plugins and existing-agent integration remain P4 under D7 unless separately approved.

P0's readiness/security and source-register work establishes dependencies; it does not activate these future capabilities. Staff feedback should remain a suggestion for review, never an automatic mutation of approved content. No AI assistant, vector store, new training schema or integration adapter was added.

**Next step requires a separately approved P1 brief after P0 review. Stop here.**
