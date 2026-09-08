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
  on staging.user_role_assignment (profile_id);

create or replace function staging.fn_role(uid uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select ura.role
  from staging.user_role_assignment ura
  where uid = auth.uid()
    and ura.profile_id = uid
  limit 1;
$$;

create or replace function staging.fn_is_super_admin(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from staging.user_role_assignment ura
    where uid = auth.uid()
      and ura.profile_id = uid and ura.role = 'super_admin'
  );
$$;

create or replace function staging.fn_is_management(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from staging.user_role_assignment ura
    where uid = auth.uid()
      and ura.profile_id = uid and ura.role = 'management'
  );
$$;

create or replace function staging.fn_has_business_unit_access(uid uuid, bu_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select uid = auth.uid()
    and (
      staging.fn_is_super_admin(uid)
    or exists (
      select 1
      from staging.user_business_unit_access uba
      where uba.profile_id = uid and uba.business_unit_id = bu_id
    )
    );
$$;

create or replace function staging.fn_has_department_access(uid uuid, dept_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select uid = auth.uid()
    and (
      staging.fn_is_super_admin(uid)
    or (
      staging.fn_is_management(uid)
      and exists (
        select 1
        from staging.departments d
        where d.id = dept_id
          and staging.fn_has_business_unit_access(uid, d.business_unit_id)
      )
    )
    or exists (
      select 1
      from staging.user_department_access uda
      where uda.profile_id = uid and uda.department_id = dept_id
    )
    );
$$;

create or replace function staging.fn_task_department(task_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select ct.department_id
  from staging.content_tasks ct
  where ct.id = $1;
$$;

create or replace function staging.fn_can_edit_content_item(uid uuid, target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from staging.content_items ci
    where ci.id = target_id
      and ci.status in ('draft', 'in_progress', 'revision_required')
      and (
        (ci.department_id is null and staging.fn_role(uid) in ('super_admin', 'management'))
        or staging.fn_has_department_access(uid, ci.department_id)
      )
      and (
        staging.fn_role(uid) <> 'intern'
        or ci.user_id = uid
      )
  );
$$;

create or replace function staging.fn_can_approve_content_item(uid uuid, target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from staging.content_items ci
    where ci.id = target_id
      and ci.status = 'awaiting_approval'
      and (
        (ci.department_id is null and staging.fn_role(uid) in ('super_admin', 'management'))
        or staging.fn_has_department_access(uid, ci.department_id)
      )
      and (
        (ci.approval_category_id is null and staging.fn_role(uid) = 'management')
        or (ci.approval_category_id is not null and staging.fn_role(uid) = 'super_admin')
      )
  );
$$;

-- A regular PostgREST update may edit content fields, but it may not move the
-- workflow state. Only the reviewed RPCs below set this transaction-local flag.
create or replace function staging.guard_content_item_workflow()
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

create or replace function staging.validate_content_item_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.department_id is not null and new.business_unit_id is not null and not exists (
    select 1
    from staging.departments d
    where d.id = new.department_id and d.business_unit_id = new.business_unit_id
  ) then
    raise exception using errcode = '23514', message = 'Department does not belong to the selected business unit.';
  end if;

  if new.campaign_id is not null and not exists (
    select 1
    from staging.campaigns c
    where c.id = new.campaign_id
      and (new.department_id is null or c.department_id = new.department_id)
      and (new.business_unit_id is null or c.business_unit_id = new.business_unit_id)
  ) then
    raise exception using errcode = '23514', message = 'Campaign is outside the selected content scope.';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_content_item_workflow on staging.content_items;
create trigger guard_content_item_workflow
before update on staging.content_items
for each row execute function staging.guard_content_item_workflow();

drop trigger if exists validate_content_item_scope on staging.content_items;
create trigger validate_content_item_scope
before insert or update on staging.content_items
for each row execute function staging.validate_content_item_scope();

drop policy if exists "staging_content_items_select" on staging.content_items;
create policy "staging_content_items_select" on staging.content_items
  for select using (
    auth.uid() is not null
    and (
      (department_id is null and staging.fn_role(auth.uid()) in ('super_admin', 'management'))
      or staging.fn_has_department_access(auth.uid(), department_id)
    )
  );

drop policy if exists "staging_content_items_insert" on staging.content_items;
create policy "staging_content_items_insert" on staging.content_items
  for insert with check (
    auth.uid() is not null
    and (
      (department_id is null and staging.fn_role(auth.uid()) in ('super_admin', 'management'))
      or staging.fn_has_department_access(auth.uid(), department_id)
    )
    and (staging.fn_role(auth.uid()) <> 'intern' or user_id = auth.uid())
  );

drop policy if exists "staging_content_items_update" on staging.content_items;
create policy "staging_content_items_update" on staging.content_items
  for update
  using (staging.fn_can_edit_content_item(auth.uid(), id))
  with check (staging.fn_can_edit_content_item(auth.uid(), id));

-- Audit rows are database-generated only. This prevents clients from forging
-- submitted/approved/edited history entries.
drop policy if exists "staging_approval_action_insert" on staging.approval_action;
drop policy if exists "staging_record_edit_log_insert" on staging.record_edit_log;

create or replace function staging.prevent_audit_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = '42501', message = 'Audit history is immutable.';
end;
$$;

drop trigger if exists prevent_approval_action_mutation on staging.approval_action;
create trigger prevent_approval_action_mutation
before update or delete on staging.approval_action
for each row execute function staging.prevent_audit_mutation();

drop trigger if exists prevent_record_edit_log_mutation on staging.record_edit_log;
create trigger prevent_record_edit_log_mutation
before update or delete on staging.record_edit_log
for each row execute function staging.prevent_audit_mutation();

create or replace function staging.log_content_item_edit()
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
    insert into staging.approval_action (content_item_id, actor_id, action, comment)
    values (new.id, auth.uid(), 'edited', 'Edited: ' || changed_fields);
  end if;
  return new;
end;
$$;

drop trigger if exists log_content_item_edit on staging.content_items;
create trigger log_content_item_edit
after update on staging.content_items
for each row execute function staging.log_content_item_edit();

create or replace function staging.log_generic_record_edit()
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
    insert into staging.record_edit_log (table_name, record_id, actor_id, summary)
    values (tg_table_name, new.id, auth.uid(), 'Edited: ' || changed_fields);
  end if;
  return new;
end;
$$;

drop trigger if exists log_sop_edit on staging.sops;
create trigger log_sop_edit
after update on staging.sops
for each row execute function staging.log_generic_record_edit();

drop trigger if exists log_content_idea_edit on staging.content_ideas;
create trigger log_content_idea_edit
after update on staging.content_ideas
for each row execute function staging.log_generic_record_edit();

drop trigger if exists log_knowledge_item_edit on staging.knowledge_items;
create trigger log_knowledge_item_edit
after update on staging.knowledge_items
for each row execute function staging.log_generic_record_edit();

-- Scope generic edit-history reads to users who can read the source record.
drop policy if exists "staging_record_edit_log_select" on staging.record_edit_log;
create policy "staging_record_edit_log_select" on staging.record_edit_log
  for select using (
    case table_name
      when 'sops' then exists (
        select 1 from staging.sops s
        where s.id = record_id
          and (s.department_id is null or staging.fn_has_department_access(auth.uid(), s.department_id))
      )
      when 'content_ideas' then staging.fn_role(auth.uid()) in ('super_admin', 'management')
      when 'knowledge_items' then staging.fn_role(auth.uid()) in ('super_admin', 'management')
      else false
    end
  );

create or replace function staging.submit_content_item_for_review(target_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not staging.fn_can_edit_content_item(uid, target_id) then
    raise exception using errcode = '42501', message = 'Not authorised to submit this content item.';
  end if;

  perform set_config('ieos.workflow_change', 'on', true);
  update staging.content_items
  set status = 'awaiting_approval', approval_status = 'pending', approval_remarks = null
  where id = target_id;

  insert into staging.approval_action (content_item_id, actor_id, action)
  values (target_id, uid, 'submitted');
end;
$$;

create or replace function staging.review_content_item(
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
  if uid is null or not staging.fn_can_approve_content_item(uid, target_id) then
    raise exception using errcode = '42501', message = 'Not authorised to review this content item.';
  end if;

  perform set_config('ieos.workflow_change', 'on', true);
  if decision = 'approved' then
    update staging.content_items
    set status = 'approved', approval_status = 'approved', approval_remarks = nullif(btrim(review_comment), '')
    where id = target_id;
  else
    update staging.content_items
    set status = 'revision_required', approval_status = 'amend', approval_remarks = btrim(review_comment)
    where id = target_id;
  end if;

  insert into staging.approval_action (content_item_id, actor_id, action, comment)
  values (target_id, uid, decision, nullif(btrim(review_comment), ''));
end;
$$;

create or replace function staging.comment_on_content_item(target_id uuid, body text)
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
  if uid is null or not staging.fn_can_approve_content_item(uid, target_id) then
    raise exception using errcode = '42501', message = 'Not authorised to comment on this content item.';
  end if;

  insert into staging.approval_action (content_item_id, actor_id, action, comment)
  values (target_id, uid, 'comment', btrim(body));
end;
$$;

revoke all on function staging.submit_content_item_for_review(uuid) from public, anon;
revoke all on function staging.review_content_item(uuid, text, text) from public, anon;
revoke all on function staging.comment_on_content_item(uuid, text) from public, anon;
grant execute on function staging.submit_content_item_for_review(uuid) to authenticated;
grant execute on function staging.review_content_item(uuid, text, text) to authenticated;
grant execute on function staging.comment_on_content_item(uuid, text) to authenticated;

revoke all on function staging.fn_role(uuid) from public, anon;
revoke all on function staging.fn_is_super_admin(uuid) from public, anon;
revoke all on function staging.fn_is_management(uuid) from public, anon;
revoke all on function staging.fn_has_business_unit_access(uuid, uuid) from public, anon;
revoke all on function staging.fn_has_department_access(uuid, uuid) from public, anon;
revoke all on function staging.fn_task_department(uuid) from public, anon;
revoke all on function staging.fn_can_edit_content_item(uuid, uuid) from public, anon;
revoke all on function staging.fn_can_approve_content_item(uuid, uuid) from public, anon;

grant execute on function staging.fn_role(uuid) to authenticated;
grant execute on function staging.fn_is_super_admin(uuid) to authenticated;
grant execute on function staging.fn_is_management(uuid) to authenticated;
grant execute on function staging.fn_has_business_unit_access(uuid, uuid) to authenticated;
grant execute on function staging.fn_has_department_access(uuid, uuid) to authenticated;
grant execute on function staging.fn_task_department(uuid) to authenticated;
grant execute on function staging.fn_can_edit_content_item(uuid, uuid) to authenticated;
grant execute on function staging.fn_can_approve_content_item(uuid, uuid) to authenticated;

revoke all on function staging.guard_content_item_workflow() from public, anon, authenticated;
revoke all on function staging.validate_content_item_scope() from public, anon, authenticated;
revoke all on function staging.prevent_audit_mutation() from public, anon, authenticated;
revoke all on function staging.log_content_item_edit() from public, anon, authenticated;
revoke all on function staging.log_generic_record_edit() from public, anon, authenticated;

-- The staging schema is private to signed-in IEOS users. RLS remains the
-- authorization boundary for every row; anon receives no schema access.
revoke all on schema staging from anon;
grant usage on schema staging to authenticated;
grant select, insert, update, delete on all tables in schema staging to authenticated;
grant usage, select on all sequences in schema staging to authenticated;
