-- P0 local candidate: public compatibility for the existing approval/edit features.
-- Apply only after the approved Stage 1-5 release manifest; no hosted authorization.
begin;
do $$ begin if exists (select 1 from public.user_role_assignment group by profile_id having count(*) > 1) then raise exception 'P0 preflight: conflicting application roles require reviewed reconciliation; no records changed.'; end if; end $$;

-- Port of the preserved existing 006_approval_workflow.sql; original staging script remains unchanged.
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

create table public.approval_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

insert into public.approval_categories (name) values
  ('Major Campaign'),
  ('Pricing / Promotion'),
  ('Paid Advertising'),
  ('Partnership / Collaboration'),
  ('Important Public Announcement'),
  ('Major Brochure / Corporate Material'),
  ('Sensitive or Strategic Content'),
  ('Manually Escalated');

alter table public.content_items
  add column approval_category_id uuid references public.approval_categories(id);

create table public.approval_action (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references public.content_items(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  action text not null check (action in ('submitted','approved','revision_requested','comment')),
  comment text,
  created_at timestamptz not null default now()
);

-- approval_categories: readable by anyone with any real access; only
-- super_admin manages the list itself (it's a "master category", per the
-- original spec's "only admin/manager roles create master categories").
alter table public.approval_categories enable row level security;
create policy "approval_categories_select" on public.approval_categories
  for select using (auth.uid() is not null);
create policy "approval_categories_write" on public.approval_categories
  for all
  using (public.fn_is_super_admin(auth.uid()))
  with check (public.fn_is_super_admin(auth.uid()));

-- approval_action: insert-only, immutable. No update/delete policy at all —
-- RLS enabled with no policy for those commands denies them outright for
-- every non-bypassing role, which is exactly the "never overwritten"
-- guarantee asked for.
alter table public.approval_action enable row level security;

create policy "approval_action_select" on public.approval_action
  for select using (
    auth.uid() is not null
    and (
      (select department_id from public.content_items where id = content_item_id) is null
      or public.fn_has_department_access(auth.uid(), (select department_id from public.content_items where id = content_item_id))
    )
  );

create policy "approval_action_insert" on public.approval_action
  for insert with check (
    auth.uid() is not null
    and (
      (select department_id from public.content_items where id = content_item_id) is null
      or public.fn_has_department_access(auth.uid(), (select department_id from public.content_items where id = content_item_id))
    )
    and (
      -- Anyone with access can submit/resubmit; intern restricted to own item.
      (action = 'submitted' and (
        public.fn_role(auth.uid()) != 'intern'
        or (select user_id from public.content_items where id = content_item_id) = auth.uid()
      ))
      -- Approve/revision-request/comment: Super Admin or Management only.
      or (action in ('approved', 'revision_requested', 'comment')
          and public.fn_role(auth.uid()) in ('super_admin', 'management'))
    )
  );

-- Port of the preserved existing 007_edit_support.sql; original staging script remains unchanged.
-- STAGING ONLY. See supabase/staging/README.md.
-- Adds Edit support across content_tasks, content_items, sops,
-- content_ideas, knowledge_items, and work_files.

-- 1. approval_action gets a new 'edited' action type (content_items audit trail).
alter table public.approval_action drop constraint approval_action_action_check;
alter table public.approval_action add constraint approval_action_action_check
  check (action in ('submitted','approved','revision_requested','comment','edited'));

-- 2. record_edit_log: generic edit audit trail for sops/content_ideas/
--    knowledge_items, which have no per-record activity table of their own
--    (unlike content_tasks -> activities, content_items -> approval_action).
create table public.record_edit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null check (table_name in ('sops','content_ideas','knowledge_items')),
  record_id uuid not null,
  actor_id uuid references public.profiles(id),
  summary text not null,
  created_at timestamptz not null default now()
);

alter table public.record_edit_log enable row level security;
create policy "record_edit_log_select" on public.record_edit_log
  for select using (auth.uid() is not null);
create policy "record_edit_log_insert" on public.record_edit_log
  for insert with check (auth.uid() is not null and actor_id = auth.uid());

-- 3. work_files needs an UPDATE policy — it currently only has select/insert,
--    so "correct a work link after the fact" is blocked at the DB level
--    even once the UI exists. Same department-scoping as its own select policy.
create policy "work_files_update" on public.work_files
  for update using (
    public.fn_has_department_access(auth.uid(), public.fn_task_department(task_id))
  );

-- 4. approval_action_insert is a hard allow-list of action types
--    (submitted / approved / revision_requested / comment) — extending the
--    CHECK constraint to allow 'edited' isn't enough on its own, this policy
--    also has to explicitly admit it, or every edit is silently RLS-blocked
--    even though it passes the table's own CHECK. Same rule as 'submitted':
--    anyone with department access, intern restricted to their own item —
--    i.e. the same people who can write to content_items at all can log
--    an edit to it.
drop policy "approval_action_insert" on public.approval_action;
create policy "approval_action_insert" on public.approval_action
  for insert with check (
    auth.uid() is not null
    and (
      (select department_id from public.content_items where id = content_item_id) is null
      or public.fn_has_department_access(auth.uid(), (select department_id from public.content_items where id = content_item_id))
    )
    and (
      -- Anyone with access can submit/resubmit; intern restricted to own item.
      (action in ('submitted', 'edited') and (
        public.fn_role(auth.uid()) != 'intern'
        or (select user_id from public.content_items where id = content_item_id) = auth.uid()
      ))
      -- Approve/revision-request/comment: Super Admin or Management only.
      or (action in ('approved', 'revision_requested', 'comment')
          and public.fn_role(auth.uid()) in ('super_admin', 'management'))
    )
  );

-- Port of the preserved existing 008_approval_security_hardening.sql; original staging script remains unchanged.
-- STAGING ONLY. See supabase/staging/README.md.
-- Hardens the recovered Milestone 4 approval/edit draft without modifying
-- the already-applied 006/007 staging steps.
--
-- Guarantees added here:
--   * direct table writes cannot forge approval transitions or audit rows;
--   * submit/review/comment operations update state and history atomically;
--   * routine items route to Management and categorised items to Super Admin;
--   * content may only be edited while draft/in-progress/revision-required;
--   * edit history is written by database triggers in the same transaction;
--   * helper/RPC functions use an empty search_path and qualified objects.

-- The access model assumes one effective role per profile. The original
-- unique(profile_id, role) constraint permitted contradictory multiple roles.
create unique index if not exists user_role_assignment_one_role_per_profile
  on public.user_role_assignment (profile_id);

create or replace function public.fn_role(uid uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select ura.role
  from public.user_role_assignment ura
  where uid = auth.uid()
    and ura.profile_id = uid
  limit 1;
$$;

create or replace function public.fn_is_super_admin(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_role_assignment ura
    where uid = auth.uid()
      and ura.profile_id = uid and ura.role = 'super_admin'
  );
$$;

create or replace function public.fn_is_management(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_role_assignment ura
    where uid = auth.uid()
      and ura.profile_id = uid and ura.role = 'management'
  );
$$;

create or replace function public.fn_has_business_unit_access(uid uuid, bu_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select uid = auth.uid()
    and (
      public.fn_is_super_admin(uid)
    or exists (
      select 1
      from public.user_business_unit_access uba
      where uba.profile_id = uid and uba.business_unit_id = bu_id
    )
    );
$$;

create or replace function public.fn_has_department_access(uid uuid, dept_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select uid = auth.uid()
    and (
      public.fn_is_super_admin(uid)
    or (
      public.fn_is_management(uid)
      and exists (
        select 1
        from public.departments d
        where d.id = dept_id
          and public.fn_has_business_unit_access(uid, d.business_unit_id)
      )
    )
    or exists (
      select 1
      from public.user_department_access uda
      where uda.profile_id = uid and uda.department_id = dept_id
    )
    );
$$;

create or replace function public.fn_task_department(task_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select ct.department_id
  from public.content_tasks ct
  where ct.id = $1;
$$;

create or replace function public.fn_can_edit_content_item(uid uuid, target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.content_items ci
    where ci.id = target_id
      and ci.status in ('draft', 'in_progress', 'revision_required')
      and (
        (ci.department_id is null and public.fn_role(uid) in ('super_admin', 'management'))
        or public.fn_has_department_access(uid, ci.department_id)
      )
      and (
        public.fn_role(uid) <> 'intern'
        or ci.user_id = uid
      )
  );
$$;

create or replace function public.fn_can_approve_content_item(uid uuid, target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.content_items ci
    where ci.id = target_id
      and ci.status = 'awaiting_approval'
      and (
        (ci.department_id is null and public.fn_role(uid) in ('super_admin', 'management'))
        or public.fn_has_department_access(uid, ci.department_id)
      )
      and (
        (ci.approval_category_id is null and public.fn_role(uid) = 'management')
        or (ci.approval_category_id is not null and public.fn_role(uid) = 'super_admin')
      )
  );
$$;

-- A regular PostgREST update may edit content fields, but it may not move the
-- workflow state. Only the reviewed RPCs below set this transaction-local flag.
create or replace function public.guard_content_item_workflow()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (
    new.status is distinct from old.status
    or new.approval_status is distinct from old.approval_status
    or new.approval_remarks is distinct from old.approval_remarks
  ) and coalesce(current_setting('ieos.workflow_change', true), '') <> 'on' then
    raise exception using
      errcode = '42501',
      message = 'Content workflow state must be changed through an approved workflow action.';
  end if;
  return new;
end;
$$;

create or replace function public.validate_content_item_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.department_id is not null and new.business_unit_id is not null and not exists (
    select 1
    from public.departments d
    where d.id = new.department_id and d.business_unit_id = new.business_unit_id
  ) then
    raise exception using errcode = '23514', message = 'Department does not belong to the selected business unit.';
  end if;

  if new.campaign_id is not null and not exists (
    select 1
    from public.campaigns c
    where c.id = new.campaign_id
      and (new.department_id is null or c.department_id = new.department_id)
      and (new.business_unit_id is null or c.business_unit_id = new.business_unit_id)
  ) then
    raise exception using errcode = '23514', message = 'Campaign is outside the selected content scope.';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_content_item_workflow on public.content_items;
create trigger guard_content_item_workflow
before update on public.content_items
for each row execute function public.guard_content_item_workflow();

drop trigger if exists validate_content_item_scope on public.content_items;
create trigger validate_content_item_scope
before insert or update on public.content_items
for each row execute function public.validate_content_item_scope();

drop policy if exists "content_items_select" on public.content_items;
create policy "content_items_select" on public.content_items
  for select using (
    auth.uid() is not null
    and (
      (department_id is null and public.fn_role(auth.uid()) in ('super_admin', 'management'))
      or public.fn_has_department_access(auth.uid(), department_id)
    )
  );

drop policy if exists "content_items_insert" on public.content_items;
create policy "content_items_insert" on public.content_items
  for insert with check (
    auth.uid() is not null
    and (
      (department_id is null and public.fn_role(auth.uid()) in ('super_admin', 'management'))
      or public.fn_has_department_access(auth.uid(), department_id)
    )
    and (public.fn_role(auth.uid()) <> 'intern' or user_id = auth.uid())
  );

drop policy if exists "content_items_update" on public.content_items;
create policy "content_items_update" on public.content_items
  for update
  using (public.fn_can_edit_content_item(auth.uid(), id))
  with check (public.fn_can_edit_content_item(auth.uid(), id));

-- Audit rows are database-generated only. This prevents clients from forging
-- submitted/approved/edited history entries.
drop policy if exists "approval_action_insert" on public.approval_action;
drop policy if exists "record_edit_log_insert" on public.record_edit_log;

create or replace function public.prevent_audit_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = '42501', message = 'Audit history is immutable.';
end;
$$;

drop trigger if exists prevent_approval_action_mutation on public.approval_action;
create trigger prevent_approval_action_mutation
before update or delete on public.approval_action
for each row execute function public.prevent_audit_mutation();

drop trigger if exists prevent_record_edit_log_mutation on public.record_edit_log;
create trigger prevent_record_edit_log_mutation
before update or delete on public.record_edit_log
for each row execute function public.prevent_audit_mutation();

create or replace function public.log_content_item_edit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_fields text;
begin
  select string_agg(e.key, ', ' order by e.key)
  into changed_fields
  from jsonb_each(to_jsonb(new)) e
  where e.key not in (
    'id', 'created_at', 'status', 'approval_status', 'approval_remarks',
    'suggested_tags', 'tags_source', 'tags_confidence', 'tags_review_status',
    'priority_score', 'priority_source', 'priority_confidence', 'priority_review_status'
  )
    and e.value is distinct from to_jsonb(old) -> e.key;

  if changed_fields is not null then
    insert into public.approval_action (content_item_id, actor_id, action, comment)
    values (new.id, auth.uid(), 'edited', 'Edited: ' || changed_fields);
  end if;
  return new;
end;
$$;

drop trigger if exists log_content_item_edit on public.content_items;
create trigger log_content_item_edit
after update on public.content_items
for each row execute function public.log_content_item_edit();

create or replace function public.log_generic_record_edit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_fields text;
begin
  select string_agg(e.key, ', ' order by e.key)
  into changed_fields
  from jsonb_each(to_jsonb(new)) e
  where e.key not in ('id', 'created_at')
    and e.value is distinct from to_jsonb(old) -> e.key;

  if changed_fields is not null then
    insert into public.record_edit_log (table_name, record_id, actor_id, summary)
    values (tg_table_name, new.id, auth.uid(), 'Edited: ' || changed_fields);
  end if;
  return new;
end;
$$;

drop trigger if exists log_sop_edit on public.sops;
create trigger log_sop_edit
after update on public.sops
for each row execute function public.log_generic_record_edit();

drop trigger if exists log_content_idea_edit on public.content_ideas;
create trigger log_content_idea_edit
after update on public.content_ideas
for each row execute function public.log_generic_record_edit();

drop trigger if exists log_knowledge_item_edit on public.knowledge_items;
create trigger log_knowledge_item_edit
after update on public.knowledge_items
for each row execute function public.log_generic_record_edit();

-- Scope generic edit-history reads to users who can read the source record.
drop policy if exists "record_edit_log_select" on public.record_edit_log;
create policy "record_edit_log_select" on public.record_edit_log
  for select using (
    case table_name
      when 'sops' then exists (
        select 1 from public.sops s
        where s.id = record_id
          and (s.department_id is null or public.fn_has_department_access(auth.uid(), s.department_id))
      )
      when 'content_ideas' then public.fn_role(auth.uid()) in ('super_admin', 'management')
      when 'knowledge_items' then public.fn_role(auth.uid()) in ('super_admin', 'management')
      else false
    end
  );

create or replace function public.submit_content_item_for_review(target_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not public.fn_can_edit_content_item(uid, target_id) then
    raise exception using errcode = '42501', message = 'Not authorised to submit this content item.';
  end if;

  perform set_config('ieos.workflow_change', 'on', true);
  update public.content_items
  set status = 'awaiting_approval', approval_status = 'pending', approval_remarks = null
  where id = target_id;

  insert into public.approval_action (content_item_id, actor_id, action)
  values (target_id, uid, 'submitted');
end;
$$;

create or replace function public.review_content_item(
  target_id uuid,
  decision text,
  review_comment text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if decision is null or decision not in ('approved', 'revision_requested') then
    raise exception using errcode = '22023', message = 'Invalid review decision.';
  end if;
  if decision = 'revision_requested' and nullif(btrim(review_comment), '') is null then
    raise exception using errcode = '22023', message = 'A revision comment is required.';
  end if;
  if uid is null or not public.fn_can_approve_content_item(uid, target_id) then
    raise exception using errcode = '42501', message = 'Not authorised to review this content item.';
  end if;

  perform set_config('ieos.workflow_change', 'on', true);
  if decision = 'approved' then
    update public.content_items
    set status = 'approved', approval_status = 'approved', approval_remarks = nullif(btrim(review_comment), '')
    where id = target_id;
  else
    update public.content_items
    set status = 'revision_required', approval_status = 'amend', approval_remarks = btrim(review_comment)
    where id = target_id;
  end if;

  insert into public.approval_action (content_item_id, actor_id, action, comment)
  values (target_id, uid, decision, nullif(btrim(review_comment), ''));
end;
$$;

create or replace function public.comment_on_content_item(target_id uuid, body text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if nullif(btrim(body), '') is null then
    raise exception using errcode = '22023', message = 'Comment cannot be empty.';
  end if;
  if uid is null or not public.fn_can_approve_content_item(uid, target_id) then
    raise exception using errcode = '42501', message = 'Not authorised to comment on this content item.';
  end if;

  insert into public.approval_action (content_item_id, actor_id, action, comment)
  values (target_id, uid, 'comment', btrim(body));
end;
$$;

revoke all on function public.submit_content_item_for_review(uuid) from public, anon;
revoke all on function public.review_content_item(uuid, text, text) from public, anon;
revoke all on function public.comment_on_content_item(uuid, text) from public, anon;
grant execute on function public.submit_content_item_for_review(uuid) to authenticated;
grant execute on function public.review_content_item(uuid, text, text) to authenticated;
grant execute on function public.comment_on_content_item(uuid, text) to authenticated;

revoke all on function public.fn_role(uuid) from public, anon;
revoke all on function public.fn_is_super_admin(uuid) from public, anon;
revoke all on function public.fn_is_management(uuid) from public, anon;
revoke all on function public.fn_has_business_unit_access(uuid, uuid) from public, anon;
revoke all on function public.fn_has_department_access(uuid, uuid) from public, anon;
revoke all on function public.fn_task_department(uuid) from public, anon;
revoke all on function public.fn_can_edit_content_item(uuid, uuid) from public, anon;
revoke all on function public.fn_can_approve_content_item(uuid, uuid) from public, anon;

grant execute on function public.fn_role(uuid) to authenticated;
grant execute on function public.fn_is_super_admin(uuid) to authenticated;
grant execute on function public.fn_is_management(uuid) to authenticated;
grant execute on function public.fn_has_business_unit_access(uuid, uuid) to authenticated;
grant execute on function public.fn_has_department_access(uuid, uuid) to authenticated;
grant execute on function public.fn_task_department(uuid) to authenticated;
grant execute on function public.fn_can_edit_content_item(uuid, uuid) to authenticated;
grant execute on function public.fn_can_approve_content_item(uuid, uuid) to authenticated;

revoke all on function public.guard_content_item_workflow() from public, anon, authenticated;
revoke all on function public.validate_content_item_scope() from public, anon, authenticated;
revoke all on function public.prevent_audit_mutation() from public, anon, authenticated;
revoke all on function public.log_content_item_edit() from public, anon, authenticated;
revoke all on function public.log_generic_record_edit() from public, anon, authenticated;

-- The staging schema is private to signed-in IEOS users. RLS remains the
-- authorization boundary for every row; anon receives no schema access.
-- Public schema retains managed Supabase usage; table/RPC grants are explicit below.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.approval_categories, public.approval_action, public.record_edit_log to authenticated;


commit;
