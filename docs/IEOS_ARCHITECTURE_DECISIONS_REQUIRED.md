# IEOS Architecture Decisions Requiring Director Approval

**Date:** 12 October 2026, Asia/Kuala_Lumpur  
**Status:** Recommendations only; no decision is presumed approved.  
**Scope:** Only decisions affecting business authority, confidential access, company responsibility, recurring cost, personnel governance or external-system ownership. Routine schema/index/UI implementation choices are excluded.

## D1. Group structure and cross-company operational access

**Decision:** Confirm whether IETA, IEA, PLC and KALER operate as business units within the existing Inter Excel organisation, and which roles may work across them.

**Recommendation:** Reuse the existing organisation → business unit → department structure. Define scoped cross-company assignments explicitly. Keep one application authorization role per person and use scope/capability grants for additional duties; business job roles remain separate.

**Alternatives:** Separate organisations within the same application for stronger business separation; separate databases only where legal/contractual isolation demands it. A separate organisation requires explicit tenant-boundary checks, not just new labels.

**Approval needed before:** P0 access-model acceptance and P1 group-wide knowledge classification. Approve a company/department visibility matrix, designated administrators and the intended Director access boundary. The untracked migration activating all four companies must not be treated as approval.

## D2. Knowledge authority, ownership and publication accountability

**Decision:** Who may approve company policy, departmental SOPs/templates and restricted material, and what constitutes official knowledge?

**Recommendation:** Treat the effective approved IEOS revision as operational authority. Every critical document has an accountable owner, named reviewer and review due date. Department-appointed reviewers approve routine SOPs; Director approves policy/restricted categories and exceptional self-review. External references, informal notes and AI output remain clearly distinguished.

**Alternatives:** Director approves every publication, offering tighter central control with a bottleneck; delegated owners approve their own low-risk content with logged exceptions, offering faster publication with weaker separation.

**Approval needed before:** P1 workflow and source intake. Approve authority taxonomy, approval delegation, review cycle and conflict-escalation owner. Resolve conflicting policies through accountable review, not automatic AI precedence.

## D3. Drive/Supabase authority and company control of source assets

**Decision:** Where editable originals, binaries and immutable approved content live, and who controls the source accounts?

**Recommendation:** Hybrid: company-controlled Drive for authoring/binary assets; existing master_files for source register; Supabase for structured approved revisions, snapshots, provenance and workflow links. Live source edits create review candidates and cannot change a published revision.

**Alternatives:** Drive-only authoritative content with IEOS metadata, requiring disciplined retained snapshots/version/ACL checks; Supabase-first document storage/authoring, creating more migration and editing work.

**Approval needed before:** P1 snapshot design and later Drive integration. Confirm company ownership, source/approval authority, which document classes may be copied into IEOS and who reconciles Drive sharing.

## D4. Confidentiality, offboarding and retention policy

**Decision:** Define who can see operational, full-time-only, management-only, appointed-personnel and P&C material, including archives, assessments, prompts and logs.

**Recommendation:** Preserve current sensitivity vocabulary with explicit grants and default denial. Give Director broad permitted operational visibility, while approving P&C rights explicitly. Apply departure/access revocation across IEOS and providers. Retain historical attribution and approved revisions under an approved retention policy; do not expose private assessment notes to general staff.

**Alternatives:** Broader management access, reducing administration with greater disclosure risk; narrower appointed access to most knowledge, reducing exposure with more maintenance and onboarding friction.

**Approval needed before:** P0 permission acceptance and P1/P2 expansion. Approve access matrix, offboarding owner, retention periods and exception handling, with legal/accounting advice where required. Technical ACL fixes implementing the approved policy do not each require Director redesign decisions.

## D5. Competency verification and successor readiness

**Decision:** Which processes are critical, who can certify competency, and what minimum backup coverage the company requires?

**Recommendation:** Reading acknowledgement is separate from practical competency. Use named supervisors, task evidence and simple outcomes. Critical processes require an assessed backup or a visible unresolved continuity risk. Use the dashboard for training/handover action, without staff rankings or automatic employment decisions.

**Alternatives:** Reading-only attestation for low-risk processes, cheaper but insufficient for critical work; formal external certification/LMS for processes where regulation or complexity demands it.

**Approval needed before:** P2 pilot. Approve critical-process list, authorized assessors, evidence standard, refresher rules, HR visibility and nominated owner/backup responsibilities.

## D6. AI data exposure, human authority and spending envelope

**Decision:** Approve the AI provider/channel, permitted data classes, retention/contract terms, maximum spending and scope of tool actions.

**Recommendation:** Start with a read-oriented IEOS assistant over approved low-sensitivity content and permitted tasks. Human-reviewed drafts and confirmed suggestions are allowed; autonomous publication, policy changes, financial posting and access changes are excluded. Restricted knowledge enters a model only after approved contractual/data controls and permission tests.

**Alternatives:** Continue human search/manual use of approved Custom GPTs, avoiding application integration initially; use a private/self-hosted model if confidentiality obligations justify its additional operating cost.

**Approval needed before:** P3 provider pilot or ingestion of confidential source material. Approve data/retention/cost policy, operational AI owner and the source inventory permitted from existing Custom GPTs. Plugin/Actions access is an interface decision, not permission to expose the entire corpus.

## D7. External systems of record and integration write authority

**Decision:** Confirm owners and write boundaries for GoHighLevel, Finance/Vercel, SQL Accounting, Google Drive and existing AI agents.

**Recommendation:** CRM owns contacts/pipeline; Finance/SQL Accounting retain their respective approved financial responsibilities; Drive owns editable source assets; IEOS owns governed operational knowledge, tasks, evidence and training. Begin integration with authorized IDs/status/read-only reconciliation. Approve external writes individually after a concrete adapter pilot.

**Alternatives:** Limited manual references/exports, lower integration cost with more routine work; bidirectional synchronization, greater automation with higher reconciliation, privacy and operational risk.

**Approval needed before:** P4 adapter work. Resolve any overlap between the Finance app and SQL Accounting, approve field ownership/data-sharing and nominate incident/reconciliation owners. Vendor licensing/API feasibility is a later technical dependency, not assumed here.

## D8. Expansion priority, operating resources and release authority

**Decision:** Approve P0–P4 sequencing relative to the old numbered module plan, designate product/knowledge/system owners and allocate maintenance/curation resources.

**Recommendation:** Stabilise the latest work first; pilot governed knowledge and critical-process backup readiness before AI/integration expansion. Require current-version acceptance evidence. Operational recovery of the inactive hosted project, production database changes and Vercel rollout remain separately authorised actions with rollback/restore plans.

**Alternatives:** Finish the historical content/operational-module sequence before knowledge governance; prioritise a single urgent business integration after P0 while deferring AI. Neither option removes the need for secure approved knowledge.

**Approval needed before:** Any implementation following this audit. Approve a bounded next-stage scope and accountable owners. A roadmap approval alone should not silently authorize hosted restoration, migrations, pushes or deployment.

## Director response format

For D1–D8 record: approved recommendation or selected alternative; appointed business owner; any scope/retention/budget conditions. No named person, actual budget, legal requirement or confidential access entitlement is assumed by these reports.

These decisions can be accepted in stages: D1/D4/D8 first for P0; D2/D3 for P1; D5 for P2; D6 for P3; D7 for P4. Implementation must wait for the relevant approval.
