# IEOS — Technical Inspection

Repository/database audit performed before any IEOS Phase 1 code was written,
in response to the "Final Clarifications" amendments to the Phase 1 spec.
Read-only at the time this was produced — no schema or code changes.

## 1. Existing architecture found

- **Stack**: Next.js 15 (App Router, React 19, Server Actions), TypeScript strict, Tailwind v4, Supabase (`@supabase/ssr`), deployed on Vercel via GitHub auto-deploy, npm-managed.
- **Data layer**: `lib/data/*.ts` — one typed Supabase-query module per table. `lib/actions/*.ts` — server actions doing all writes + activity logging. No ORM; hand-written typed queries.
- **Auth**: `@supabase/ssr` is wired into `lib/supabase/{client,server,middleware}.ts` and `middleware.ts` calls `supabase.auth.getUser()` on every request purely to refresh a session cookie — but nothing creates a session. There is no login/signup page, no protected route, no `profiles`/`users` table, and no route checks `auth.uid()`. It's scaffold, not a working auth flow. Every table has an unused nullable `user_id uuid` column, and every RLS policy is `using (true)` (fully permissive, by design for the demo-first v1).
- **Deploy convention**: migrations are additive-only (`supabase/migrations/0001_init.sql` is the applied baseline, never edited; new schema = `0002_*.sql`+). Git push → Vercel auto-deploy.

## 2. Existing tables/modules relevant to Phase 1

| Table | Purpose today | Relevant fields |
|---|---|---|
| `departments` | SOP/task grouping (Marketing, Design, Video, Operations) | `name`, `slug`, `user_id` (unused) |
| `sops` | Procedure + master Drive link | `department_id`, `master_drive_link`, `version` |
| `content_ideas` | Idea pipeline | `status` (idea/selected/tasked/archived), rule-based `suggested_tags` |
| `content_tasks` | The original "content item" | `status` (assigned→in_progress→submitted→approved→amendment→posted), single `platform` text field, single `work_link`/`posted_url`/`posted_date` |
| `work_files` | Extra reference links per task | `task_id`, `url`, `file_type` |
| `knowledge_items` | KB entries | — |
| `activities` | Append-only audit trail per task | `action`, `actor_name`, `detail`, `created_at` — already immutable/append-only, a good structural fit for approval history |

No `users`, `business_units`, `teams`, `roles`, `approval_categories`, or per-platform publication tables existed at the time of this inspection.

## 3. Reuse / Modify / Add

**Reuse as-is**: `sops`, `knowledge_items`, `work_files`. `activities` — already append-only; becomes the approval/activity-history table with a few new `action` values. `departments` — keeps its role, gets a `business_unit_id` FK.

**Modify**: `content_tasks` → conceptually "Content Item," collapse `status` into the new 9-state workflow, add `approval_category_id`/escalation fields. `content_ideas` → add `business_unit_id` (not yet done — flagged as a Milestone 3 gap). Single `platform`/`work_link`/`posted_url`/`posted_date` on `content_tasks` → superseded by `platform_publications` (one row per intended platform).

**Genuinely new**: `business_units`, `profiles`, `user_business_unit_access`, `user_department_access`, `user_role_assignment`, `teams` (empty, FK-ready), `approval_categories`, `platform_publications`.

## 4. Revised ER model

```
business_units (IETA active; IEA, PLC, KALER inactive)
  └─< departments
        └─< sops
        └─< content_ideas ──┐
                              ├─< content_items (was content_tasks)
                              │     ├─< platform_publications (1 row per platform)
                              │     ├─< work_files
                              │     ├─< activities (append-only approval/activity trail)
                              │     └─> approval_categories (nullable FK)
                              └─< knowledge_items

teams (empty Phase 1) ──< content_items (nullable FK, unused Phase 1)

profiles (mirrors auth.users)
  ├─< user_business_unit_access >── business_units
  ├─< user_department_access   >── departments
  └─< user_role_assignment     (role: intern/creator/approver/exec/admin)
```

## 5. Revised Phase 1 workflow

**Content item lifecycle**: `draft → in_progress → awaiting_approval → revision_required → awaiting_approval → approved → scheduled_publishing → published → archived`. "Resubmitted" is an `activities` event, not a separate status. `published` requires every linked `platform_publications` row to be `Published` or `Skipped`.

**Approval routing**: default approver Hailey (management); escalates to Claire (super_admin) when `approval_category_id` is set to one of the configured categories, or manually flagged.

## 6. Genuine technical conflicts identified

1. Auth was scaffolded but inactive — no working login flow existed prior to Milestone 2.
2. RLS was `using (true)` everywhere — the biggest actual security change in scope.
3. `content_tasks.status` had no CHECK constraint/enum — extending it is app-code-enforced, consistent with existing convention.
4. Migration-immutability convention meant deprecating old columns in place rather than dropping them.
5. Existing `user_id` columns were unused nulls — right shape for ownership once real auth landed, but needed backfilling/fallback RLS for pre-auth legacy rows.
