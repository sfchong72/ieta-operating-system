# IEOS Phase 1 Specification

Inter Excel Operations System (IEOS) — Phase 1 build direction, amendments,
and the approved technical specification derived from them. Consolidated
from project discussion; versioned here so it isn't only in chat history.

---

## Part A — Business requirements (Phase 1 Build Direction)

**Long-term architecture**: `Organisation → Business Unit/Company → Department → Team → User`.
Future business units: IETA, IEA, PLC, KALER. **Only IETA is active in Phase 1.**
Architecture must allow future extension without rebuilding the core database.

**Phase 1 priority problem**: IETA Marketing & Social Media Operations — manual
planning, ad hoc assignment via WhatsApp, forgotten/buried approvals,
scattered Canva/Drive links, no way to tell which version was approved or
whether a piece was actually posted on every intended platform, hard-to-find
old approved content. IEOS is the **control layer / source of truth for
workflow** — Drive/Canva remain the file storage; IEOS does not replace them.

**Core Phase 1 modules**:
- **Dashboard** — role-specific (Claire/Hailey: pending approvals, overdue,
  scheduled this week, not yet published, recently submitted; Staff/Intern:
  My Tasks, Due Today, Upcoming, Awaiting Review, Revision Required, Completed).
- **Social Media Planner** — reference: the IETA Social Media Production
  Master spreadsheet, redesigned as a proper database, not a spreadsheet
  clone. **Critical**: platforms are never a free-text field
  (`"TikTok / IG / FB"`) — each intended platform is its own
  `platform_publications` row with its own status, posting date, URL,
  posted-by, timestamp. One content item must be able to show
  `Instagram — Published, Facebook — Published, TikTok — Scheduled,
  YouTube — Not Required` at a glance.
- **Content Item record** — basic info (ID, company, department, campaign,
  title, type, language, audience, priority, PIC, due date), creative
  content (wording, caption, CTA, hashtags, Drive/Canva/final-artwork links),
  workflow (`Draft → In Progress → Submitted for Review → Revision Required →
  Resubmitted → Approved → Scheduled → Partially Published → Published →
  Archived`), review (approver, comments, dates, full approval history).
- **Approval workflow** — dedicated **My Approvals** queue for Claire/Hailey;
  Approve / Request Revision / Comment actions; complete history retained,
  never overwritten (`Submitted → Reviewed → Revision Requested → Resubmitted → Approved`).
- **Approval roles** — Hailey approves routine social posts, normal intern
  output, routine design revisions, content following an already-approved
  campaign direction. Claire approval required for: major campaigns,
  pricing/promotions, important public announcements, paid advertising,
  major brochures, partnerships, sensitive statements, new strategic
  concepts, anything Hailey escalates. Rules must be configurable.
- **Ad-hoc Tasks** — simple task module (title, description, assigned
  by/to, company, department, related content item, priority, dates,
  progress %, status, output link, blocker, comments), optionally linked to
  a Content Item.
- **Intern daily reporting** — lightweight, <2 minutes: what I completed
  today, progress %, blocker/help needed, output link, next action. No
  separate heavyweight report system — task activity drives the manager's
  Team Activity view.
- **Asset Register** — not a Drive reorganization. Track title, type,
  company, department, category, tags, year, person/airline/campaign,
  Drive link, Canva link, usage notes, status, uploaded-by, date. Goal:
  staff can search "Scoot recruitment photos" instead of duplicating folders.
- **Google Drive strategy** — Drive = storage, IEOS = organisation/search/
  ownership/workflow/approval. Only admin/manager roles create new master
  categories, departments, asset categories, permanent knowledge categories.
- **Duplicate Photo Finder** — an existing experimental Codex-built utility,
  **not production-ready**, explicitly **out of scope for Phase 1**.
  Architecture should allow a future pluggable module, nothing more.
- **Knowledge Base / SOP** — Phase 1 only prepares the architecture
  (title, company, department, category, tags, summary, owner, link, date,
  status). Full SOP lifecycle (`Draft → Review → Approved → Published →
  Staff Acknowledgement → Review Due → Superseded`) is future work. No
  Inter-Excel-specific terminology hard-coded into the underlying system.
- **Permissions (RBAC from day one)**: Super Admin (Claire) — full access.
  Management (Hailey) — broad operational access except restricted
  confidential areas. Staff — department-related content and assigned work.
  Intern — own/assigned tasks, permitted content, shared approved resources,
  submit/comment/update; cannot change approval rules, master categories, or
  modify approved SOPs. Architecture must support future custom roles.
- **Entity separation** — no giant `tasks` table. Keep Organisation,
  Business Unit, Department, User, Campaign, Content Item, Platform
  Publication, Task, Approval, Asset, Knowledge Item, SOP (future) distinct,
  connected by relationships.
- **Key workflow to get right**: Plan → Assign → Work → Submit → Review →
  Request Revision (if needed) → Resubmit → Approve → Schedule → Publish to
  individual platforms → Verify platform posting → Archive → Easily
  find/reuse later. More important than adding many modules.
- **Phase 1 screens (~12)**: Login, Dashboard, Social Media Planner,
  Calendar View, Content Item Detail, My Tasks, Task Detail, My Approvals,
  Campaigns, Asset Library, Team Activity, Basic Admin/Users/Roles. Planner
  default table columns: `Date | Content | Type | Platforms | PIC | Workflow
  | Approval | Publishing Progress`, e.g. platform progress shown as
  `IG ✓  FB ✓  TikTok Pending  YouTube N/A`.
- **Explicitly out of scope for Phase 1**: Student Affairs, Finance,
  Payroll, HR records, visa management, accounting, full SOP management,
  automated Drive cleanup, duplicate photo finder integration, WhatsApp API
  integration, AI content generation, external customer/company SaaS,
  complex analytics.

---

## Part B — Amendments and confirmed decisions

From the "Final Clarifications" pass and subsequent milestone approvals:

1. **Existing repository/schema** — do not assume a fresh foundation;
   inspect first (see `IEOS_Technical_Inspection.md`). Avoid parallel
   User/Auth/Role structures if suitable ones already exist.
2. **Authentication** — prefer existing auth if already working (it
   wasn't — see inspection); Google SSO deferred; **Supabase magic-link
   email is approved for Phase 1**, using Resend as the SMTP provider.
3. **User access model** — never hard-restrict one user to one
   company/department/role. Model: `User → Primary Business Unit → User
   Business Unit Access → User Department Access → User Role Assignment`.
   Most Phase 1 users have IETA Marketing access only; Claire and select
   management can hold cross-company access without restructuring later.
4. **Approval categories** — configurable, not a rules engine. Escalate to
   Claire: Major Campaign, Pricing/Promotion, Paid Advertising,
   Partnership/Collaboration, Important Public Announcement, Major
   Brochure/Corporate Material, Sensitive/Strategic Content, anything
   manually escalated by Hailey. Everything else → Hailey.
5. **Team entity** — table exists, left empty in Phase 1 (populated later
   with real Marketing & Social Media members: Hailey, Alya, Roslan,
   Intern 1, Intern 2).
6. **Platform publishing** — manual in Phase 1, no platform APIs.
   `platform_publications` status: Planned / Scheduled / Published /
   Skipped / Not Required. `Published` requires posting date/time,
   published URL, published-by (auto from logged-in user) — a **controlled
   requirement**, not a soft prompt; Manager/Super Admin may override with a
   captured reason. Content is fully `Published` only once every required
   platform is `Published` or `Skipped`.
7. **Content workflow** — simplified to `Draft → In Progress → Awaiting
   Approval → Revision Required → Awaiting Approval → Approved →
   Scheduled/Publishing → Published → Archived`. "Resubmitted" is an
   immutable activity/approval event, never a separate long-lived status.
8. **Historical content** — do not launch empty, do not import the entire
   archive. A small selected real set as seed/UAT data (one IG+FB item, one
   IG+FB+TikTok item, one IG+FB+LinkedIn item, different languages,
   different PICs, revision/approval examples), expandable later.
9. **Timezone** — `Asia/Kuala_Lumpur` for all operational dates, deadlines,
   calendars, dashboard calculations, and displayed timestamps. Database
   timestamps may stay UTC internally.
10. **Business units** — IETA, IEA, PLC, KALER confirmed as future units;
    **only IETA is operationally activated in Phase 1.**
11. **Branding** — renamed to **IEOS / Inter Excel Operations System**, used
    as the primary navigation/product name. No IETA-specific terminology
    hard-coded into the platform itself. Active Phase 1 workspace displays
    as **"IETA — Marketing & Social Media."**

**Database/deployment safety (binding for all future milestones)**:
- No experimental development directly against production. Prefer a real
  Supabase branch where available; this org is on the free plan (branching
  requires Pro), so the working alternative is a `staging` Postgres schema
  inside the same project, clearly separated and documented, never confused
  with `public`.
- All schema changes as numbered migration files. Additive-only —
  `0001_init.sql` and later applied migrations are never edited; new work
  is `000N_*.sql`. Existing tables are extended, never destructively
  replaced.
- Every production migration needs: a pre-migration backup/snapshot, a
  tested rollback migration, RLS/auth tested first in staging, and
  confirmation existing data is unaffected.
- Milestones are applied to production one at a time, each with its own
  report (what changed, migrations, tests performed, data verification,
  issues, go/no-go recommendation) before the next milestone starts.

---

## Part C — Approved technical specification

### Architecture
Next.js 15 (App Router/Server Actions) + Supabase (Postgres 17 + RLS +
`@supabase/ssr`) + Vercel, same stack as the existing app. Auth newly
activated via Supabase magic-link (Resend SMTP). RLS moves from permissive
`using (true)` to policies scoped through the access-grant tables below.

### Entity model
```
organisations (Phase 1: one row — "Inter Excel")
  └─< business_units  (IETA active; IEA, PLC, KALER inactive placeholders)
        └─< departments  (Phase 1: "Marketing & Social Media" active)
              └─< teams  (Phase 1: real Marketing team members)
              └─< campaigns → content_items → platform_publications
                                            → work_files / activities (approval history)
              └─< assets (asset register)
              └─< knowledge_items (future-ready stub)

tasks (ad-hoc) → business_units, departments, content_items (optional),
                 assigned_by/assigned_to → profiles, task_updates (daily log)

profiles (mirrors auth.users)
  ├─< user_business_unit_access
  ├─< user_department_access
  └─< user_role_assignment (super_admin | management | staff | intern)

approval_categories (lookup, admin-editable — the 8 escalation categories)
```

### Role permission matrix

| Capability | Super Admin | Management | Staff | Intern |
|---|---|---|---|---|
| Cross-business-unit access | Yes (multi-BU grants) | Scoped to assigned BU(s) | Scoped | Scoped |
| Approve routine content | Yes | Yes | No | No |
| Approve escalated/major categories | Yes | No (routes to Super Admin) | No | No |
| Create/edit content in own dept | Yes | Yes | Yes | Assigned only |
| Create master categories | Yes | No | No | No |
| Manage users & roles | Yes | No | No | No |
| Delete content | Yes | Yes | No | No |

### Content workflow / state model
`Draft → In Progress → Awaiting Approval → Revision Required ⇄ Awaiting
Approval → Approved → Scheduled/Publishing → Published → Archived`.
`platform_publications`: `Planned → Scheduled → Published`, or `Skipped`,
or `Not Required`; `Published` requires date/time + URL + published-by.

### Screen/navigation map
Login → app shell (role-aware sidebar) → Dashboard, Social Media Planner
(table ⇄ calendar), Content Item Detail, My Tasks/Task Detail, My Approvals,
Campaigns, Asset Library, Team Activity, Admin (Users & Roles — Super Admin
only).

### Milestones
1. **Foundation** (done, in production) — organisations/business_units/
   teams schema, IETA + Marketing & Social Media seeded active.
2. **Auth + access** (built & tested in `staging`, pending production
   cutover) — Supabase Auth activation, profiles/access tables, real RLS,
   Admin Users screen.
3. Content Item core + `platform_publications`.
4. Approval workflow (`approvals`/history table, My Approvals queue,
   `approval_categories` routing).
5. Tasks module.
6. Daily activity + Team Activity view.
7. Asset Register.
8. Calendar view + dashboards, full success-scenario polish.
