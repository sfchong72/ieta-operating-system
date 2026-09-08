-- STAGING ONLY. See supabase/staging/README.md.
-- Milestone 4: Approval workflow.
--
-- approval_categories did NOT already exist anywhere (confirmed by querying
-- information_schema before writing this) — built fresh here, named
-- `approval_categories` (a lookup/routing table, not a rules engine) rather
-- than `approval_rule`, matching the naming already used in
-- docs/IEOS_Phase1_Specification.md Part C. Routing: NULL category ->
-- routine -> Management (Hailey); any of the 8 seeded rows -> Super Admin
-- (Claire). "Manually escalated" is simply the 8th seeded row — Management
-- sets a content item to that category to hand it to Claire, no separate
-- escalation mechanism needed.

create table staging.approval_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

insert into staging.approval_categories (name) values
  ('Major Campaign'),
  ('Pricing / Promotion'),
  ('Paid Advertising'),
  ('Partnership / Collaboration'),
  ('Important Public Announcement'),
  ('Major Brochure / Corporate Material'),
  ('Sensitive or Strategic Content'),
  ('Manually Escalated');

alter table staging.content_items
  add column approval_category_id uuid references staging.approval_categories(id);

create table staging.approval_action (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references staging.content_items(id) on delete cascade,
  actor_id uuid references staging.profiles(id),
  action text not null check (action in ('submitted','approved','revision_requested','comment')),
  comment text,
  created_at timestamptz not null default now()
);

-- approval_categories: readable by anyone with any real access; only
-- super_admin manages the list itself (it's a "master category", per the
-- original spec's "only admin/manager roles create master categories").
alter table staging.approval_categories enable row level security;
create policy "staging_approval_categories_select" on staging.approval_categories
  for select using (auth.uid() is not null);
create policy "staging_approval_categories_write" on staging.approval_categories
  for all
  using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));

-- approval_action: insert-only, immutable. No update/delete policy at all —
-- RLS enabled with no policy for those commands denies them outright for
-- every non-bypassing role, which is exactly the "never overwritten"
-- guarantee asked for.
alter table staging.approval_action enable row level security;

create policy "staging_approval_action_select" on staging.approval_action
  for select using (
    auth.uid() is not null
    and (
      (select department_id from staging.content_items where id = content_item_id) is null
      or staging.fn_has_department_access(auth.uid(), (select department_id from staging.content_items where id = content_item_id))
    )
  );

create policy "staging_approval_action_insert" on staging.approval_action
  for insert with check (
    auth.uid() is not null
    and (
      (select department_id from staging.content_items where id = content_item_id) is null
      or staging.fn_has_department_access(auth.uid(), (select department_id from staging.content_items where id = content_item_id))
    )
    and (
      -- Anyone with access can submit/resubmit; intern restricted to own item.
      (action = 'submitted' and (
        staging.fn_role(auth.uid()) != 'intern'
        or (select user_id from staging.content_items where id = content_item_id) = auth.uid()
      ))
      -- Approve/revision-request/comment: Super Admin or Management only.
      or (action in ('approved', 'revision_requested', 'comment')
          and staging.fn_role(auth.uid()) in ('super_admin', 'management'))
    )
  );
