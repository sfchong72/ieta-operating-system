-- P0 legacy access hardening. Local candidate; hosted application requires a reviewed cutover.
-- No records are deleted; ambiguous multi-role profiles stop the migration for explicit resolution.
begin;
alter table public.profiles add column if not exists is_active boolean not null default true;
do $$ begin if exists(select 1 from public.user_role_assignment group by profile_id having count(*)>1) then raise exception 'P0 preflight: resolve multiple roles without deleting records before cutover'; end if; end $$;
create unique index if not exists user_role_assignment_one_role_per_profile on public.user_role_assignment(profile_id);
create or replace function public.fn_role(uid uuid) returns text language sql stable security definer set search_path='' as $$ select r.role from public.user_role_assignment r join public.profiles p on p.id=r.profile_id where uid=auth.uid() and r.profile_id=uid and p.is_active $$;
create or replace function public.fn_is_super_admin(uid uuid) returns boolean language sql stable security invoker set search_path='' as $$ select coalesce(public.fn_role(uid)='super_admin',false) $$;
create or replace function public.fn_is_management(uid uuid) returns boolean language sql stable security invoker set search_path='' as $$ select coalesce(public.fn_role(uid)='management',false) $$;
create or replace function public.fn_has_business_unit_access(uid uuid,bu_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select coalesce(uid=auth.uid() and public.fn_role(uid) is not null and (public.fn_is_super_admin(uid) or exists(select 1 from public.user_business_unit_access a where a.profile_id=uid and a.business_unit_id=bu_id)),false) $$;
create or replace function public.fn_has_department_access(uid uuid,dept_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select coalesce(uid=auth.uid() and public.fn_role(uid) is not null and (public.fn_is_super_admin(uid) or (public.fn_is_management(uid) and exists(select 1 from public.departments d where d.id=dept_id and public.fn_has_business_unit_access(uid,d.business_unit_id))) or exists(select 1 from public.user_department_access a where a.profile_id=uid and a.department_id=dept_id)),false) $$;
create or replace function public.fn_task_department(task_id uuid) returns uuid language sql stable security definer set search_path='' as $$ select t.department_id from public.content_tasks t where t.id=$1 and (public.fn_role(auth.uid()) is not null and ((t.department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),t.department_id))) $$;
create table if not exists public.application_access_events(id uuid primary key default gen_random_uuid(),subject_id uuid not null references public.profiles(id),actor_id uuid not null references public.profiles(id),event_type text not null check(event_type in ('role_changed','activity_changed')),metadata jsonb not null,created_at timestamptz not null default now());
alter table public.application_access_events enable row level security;
create or replace function public.audit_application_access() returns trigger language plpgsql security definer set search_path='' as $$ begin if auth.uid() is not null then if tg_table_name='user_role_assignment' then insert into public.application_access_events(subject_id,actor_id,event_type,metadata) values(new.profile_id,auth.uid(),'role_changed',jsonb_build_object('previous_role',case when tg_op='UPDATE' then old.role else null end,'new_role',new.role)); elsif new.is_active is distinct from old.is_active then insert into public.application_access_events(subject_id,actor_id,event_type,metadata) values(new.id,auth.uid(),'activity_changed',jsonb_build_object('previous_active',old.is_active,'new_active',new.is_active)); end if; end if; return new; end $$;
create trigger audit_application_role after insert or update on public.user_role_assignment for each row execute function public.audit_application_access();
create trigger audit_profile_activity after update of is_active on public.profiles for each row execute function public.audit_application_access();
create trigger prevent_application_access_event_mutation before update or delete on public.application_access_events for each row execute function public.prevent_audit_mutation();
revoke all on function public.audit_application_access() from public,anon,authenticated;
revoke all on public.application_access_events from public,anon,authenticated;
grant select on public.application_access_events to authenticated;
create policy p0_application_access_events_read on public.application_access_events for select to authenticated using(public.fn_is_super_admin(auth.uid()));
do $$ declare p record; begin for p in select tablename,policyname from pg_policies where schemaname='public' and tablename=any(array['organisations','business_units','departments','teams','profiles','user_role_assignment','user_business_unit_access','user_department_access','sops','content_tasks','work_files','activities','content_ideas','knowledge_items','campaigns','content_items','platform_publications','approval_categories','approval_action','record_edit_log']) loop execute format('drop policy %I on %I.%I',p.policyname,'public',p.tablename); end loop; end $$;
create policy p0_organisations_select on public.organisations for select to authenticated using (public.fn_role(auth.uid()) is not null);
create policy p0_organisations_all on public.organisations for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_business_units_select on public.business_units for select to authenticated using (public.fn_role(auth.uid()) is not null and (is_active or public.fn_is_super_admin(auth.uid())) and (public.fn_has_business_unit_access(auth.uid(),id) or exists(select 1 from public.departments d where d.business_unit_id=business_units.id and public.fn_has_department_access(auth.uid(),d.id))));
create policy p0_business_units_all on public.business_units for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_departments_select on public.departments for select to authenticated using (public.fn_has_business_unit_access(auth.uid(),business_unit_id) or public.fn_has_department_access(auth.uid(),id));
create policy p0_departments_all on public.departments for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_teams_select on public.teams for select to authenticated using ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))));
create policy p0_teams_all on public.teams for all to authenticated using (public.fn_role(auth.uid()) in ('super_admin','management') and (public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id)))) with check (public.fn_role(auth.uid()) in ('super_admin','management') and (public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))));
create policy p0_profiles_select on public.profiles for select to authenticated using ((public.fn_role(auth.uid()) is not null and id=auth.uid()) or public.fn_is_super_admin(auth.uid()));
create policy p0_profiles_all on public.profiles for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_user_role_assignment_select on public.user_role_assignment for select to authenticated using ((public.fn_role(auth.uid()) is not null and profile_id=auth.uid()) or public.fn_is_super_admin(auth.uid()));
create policy p0_user_role_assignment_all on public.user_role_assignment for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_user_business_unit_access_select on public.user_business_unit_access for select to authenticated using ((public.fn_role(auth.uid()) is not null and profile_id=auth.uid()) or public.fn_is_super_admin(auth.uid()));
create policy p0_user_business_unit_access_all on public.user_business_unit_access for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_user_department_access_select on public.user_department_access for select to authenticated using ((public.fn_role(auth.uid()) is not null and profile_id=auth.uid()) or public.fn_is_super_admin(auth.uid()));
create policy p0_user_department_access_all on public.user_department_access for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_sops_select on public.sops for select to authenticated using ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))));
create policy p0_sops_insert on public.sops for insert to authenticated with check ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and public.fn_role(auth.uid()) in ('super_admin','management','staff'));
create policy p0_sops_update on public.sops for update to authenticated using ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and public.fn_role(auth.uid()) in ('super_admin','management','staff')) with check ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and public.fn_role(auth.uid()) in ('super_admin','management','staff'));
create policy p0_sops_delete on public.sops for delete to authenticated using (public.fn_role(auth.uid()) in ('super_admin','management') and (public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))));
create policy p0_content_tasks_select on public.content_tasks for select to authenticated using ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))));
create policy p0_content_tasks_insert on public.content_tasks for insert to authenticated with check ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and (public.fn_role(auth.uid())<>'intern' or user_id=auth.uid()) and status in ('assigned','in_progress') and (approval_status is null or approval_status='pending') and approval_remarks is null);
create policy p0_content_tasks_update on public.content_tasks for update to authenticated using ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and (public.fn_role(auth.uid())<>'intern' or user_id=auth.uid())) with check ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and (public.fn_role(auth.uid())<>'intern' or user_id=auth.uid()));
create policy p0_content_tasks_delete on public.content_tasks for delete to authenticated using (public.fn_role(auth.uid()) in ('super_admin','management') and (public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))));
create policy p0_work_files_select on public.work_files for select to authenticated using (exists(select 1 from public.content_tasks t where t.id=task_id));
create policy p0_work_files_insert on public.work_files for insert to authenticated with check (exists(select 1 from public.content_tasks t where t.id=task_id) and (user_id is null or user_id=auth.uid()));
create policy p0_work_files_update on public.work_files for update to authenticated using (exists(select 1 from public.content_tasks t where t.id=task_id)) with check (exists(select 1 from public.content_tasks t where t.id=task_id));
create policy p0_activities_select on public.activities for select to authenticated using (exists(select 1 from public.content_tasks t where t.id=task_id));
create policy p0_activities_insert on public.activities for insert to authenticated with check (exists(select 1 from public.content_tasks t where t.id=task_id) and (user_id is null or user_id=auth.uid()));
create or replace function public.bind_legacy_actor() returns trigger language plpgsql security invoker set search_path='' as $$ begin if auth.uid() is not null then if tg_op='INSERT' then new.user_id:=auth.uid(); else new.user_id:=old.user_id; end if; if tg_table_name='activities' then select coalesce(p.full_name,p.email) into new.actor_name from public.profiles p where p.id=auth.uid(); if new.action='approved' and (public.fn_role(auth.uid()) not in ('super_admin','management') or not exists(select 1 from public.content_tasks t where t.id=new.task_id and t.status='approved')) then raise exception using errcode='42501',message='Only a scoped supervisor can record an approved task'; end if; end if; end if; return new; end $$;
create trigger bind_activity_actor before insert on public.activities for each row execute function public.bind_legacy_actor();
create trigger bind_work_file_actor before insert or update on public.work_files for each row execute function public.bind_legacy_actor();
revoke all on function public.bind_legacy_actor() from public,anon,authenticated;
create policy p0_content_ideas_all on public.content_ideas for all to authenticated using (public.fn_role(auth.uid()) in ('super_admin','management')) with check (public.fn_role(auth.uid()) in ('super_admin','management'));
create policy p0_knowledge_items_all on public.knowledge_items for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_campaigns_select on public.campaigns for select to authenticated using ((public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))));
create policy p0_campaigns_all on public.campaigns for all to authenticated using (public.fn_role(auth.uid()) in ('super_admin','management') and (public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and (business_unit_id is null or public.fn_has_business_unit_access(auth.uid(),business_unit_id))) with check (public.fn_role(auth.uid()) in ('super_admin','management') and (public.fn_role(auth.uid()) is not null and ((department_id is null and public.fn_is_super_admin(auth.uid())) or public.fn_has_department_access(auth.uid(),department_id))) and (business_unit_id is null or public.fn_has_business_unit_access(auth.uid(),business_unit_id)));
create or replace function public.fn_can_edit_content_item(uid uuid,target_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.content_items ci where uid=auth.uid() and ci.id=target_id and ci.status in ('draft','in_progress','revision_required') and (public.fn_role(auth.uid()) is not null and (public.fn_is_super_admin(auth.uid()) or (ci.department_id is not null and public.fn_has_department_access(auth.uid(),ci.department_id)) or (ci.department_id is null and ci.business_unit_id is not null and public.fn_role(auth.uid())='management' and public.fn_has_business_unit_access(auth.uid(),ci.business_unit_id)))) and (public.fn_role(auth.uid())<>'intern' or ci.user_id=uid)) $$;
create or replace function public.fn_can_approve_content_item(uid uuid,target_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.content_items ci where uid=auth.uid() and ci.id=target_id and ci.status='awaiting_approval' and (public.fn_role(auth.uid()) is not null and (public.fn_is_super_admin(auth.uid()) or (ci.department_id is not null and public.fn_has_department_access(auth.uid(),ci.department_id)) or (ci.department_id is null and ci.business_unit_id is not null and public.fn_role(auth.uid())='management' and public.fn_has_business_unit_access(auth.uid(),ci.business_unit_id)))) and ((ci.approval_category_id is null and public.fn_role(auth.uid())='management') or (ci.approval_category_id is not null and public.fn_role(auth.uid())='super_admin'))) $$;
create policy p0_content_items_select on public.content_items for select to authenticated using ((public.fn_role(auth.uid()) is not null and (public.fn_is_super_admin(auth.uid()) or (department_id is not null and public.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and public.fn_role(auth.uid())='management' and public.fn_has_business_unit_access(auth.uid(),business_unit_id)))));
create policy p0_content_items_insert on public.content_items for insert to authenticated with check ((public.fn_role(auth.uid()) is not null and (public.fn_is_super_admin(auth.uid()) or (department_id is not null and public.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and public.fn_role(auth.uid())='management' and public.fn_has_business_unit_access(auth.uid(),business_unit_id)))) and (public.fn_role(auth.uid())<>'intern' or user_id=auth.uid()) and status in ('draft','in_progress') and (approval_status is null or approval_status='pending') and approval_remarks is null);
create policy p0_content_items_update on public.content_items for update to authenticated using (public.fn_can_edit_content_item(auth.uid(),id)) with check ((public.fn_role(auth.uid()) is not null and (public.fn_is_super_admin(auth.uid()) or (department_id is not null and public.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and public.fn_role(auth.uid())='management' and public.fn_has_business_unit_access(auth.uid(),business_unit_id)))) and (public.fn_role(auth.uid())<>'intern' or user_id=auth.uid()));
create policy p0_content_items_delete on public.content_items for delete to authenticated using (public.fn_role(auth.uid()) in ('super_admin','management') and (public.fn_role(auth.uid()) is not null and (public.fn_is_super_admin(auth.uid()) or (department_id is not null and public.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and public.fn_role(auth.uid())='management' and public.fn_has_business_unit_access(auth.uid(),business_unit_id)))));
create policy p0_platform_publications_select on public.platform_publications for select to authenticated using (exists(select 1 from public.content_items c where c.id=content_item_id));
create policy p0_platform_publications_all on public.platform_publications for all to authenticated using (exists(select 1 from public.content_items c where c.id=content_item_id) and (public.fn_role(auth.uid())<>'intern' or user_id=auth.uid())) with check (exists(select 1 from public.content_items c where c.id=content_item_id) and (public.fn_role(auth.uid())<>'intern' or user_id=auth.uid()));
create policy p0_approval_categories_select on public.approval_categories for select to authenticated using (public.fn_role(auth.uid()) is not null);
create policy p0_approval_categories_all on public.approval_categories for all to authenticated using (public.fn_is_super_admin(auth.uid())) with check (public.fn_is_super_admin(auth.uid()));
create policy p0_approval_action_select on public.approval_action for select to authenticated using (exists(select 1 from public.content_items c where c.id=content_item_id));
create policy p0_record_edit_log_select on public.record_edit_log for select to authenticated using (case table_name when 'sops' then exists(select 1 from public.sops x where x.id=record_id) when 'content_ideas' then exists(select 1 from public.content_ideas x where x.id=record_id) when 'knowledge_items' then exists(select 1 from public.knowledge_items x where x.id=record_id) else false end);
create or replace function public.assign_application_role(p_profile_id uuid,p_role text) returns void language plpgsql security definer set search_path='' as $$ begin if not public.fn_is_super_admin(auth.uid()) then raise exception using errcode='42501',message='Active Super Admin required'; end if; if p_role is null or p_role not in ('super_admin','management','staff','intern') then raise exception using errcode='22023',message='Invalid application role'; end if; insert into public.user_role_assignment(profile_id,role) values(p_profile_id,p_role) on conflict(profile_id) do update set role=excluded.role; end $$;
create or replace function public.guard_legacy_task_workflow() returns trigger language plpgsql security invoker set search_path='' as $$ begin if auth.uid() is not null then if ((new.status in ('approved','amendment') and new.status is distinct from old.status) or (new.approval_status in ('approved','amend') and new.approval_status is distinct from old.approval_status) or new.approval_remarks is distinct from old.approval_remarks) and public.fn_role(auth.uid()) not in ('super_admin','management') then raise exception using errcode='42501',message='Supervisor review required'; end if; if new.status='submitted' and old.status is distinct from new.status and nullif(btrim(new.work_link),'') is null and not exists(select 1 from public.work_files f where f.task_id=new.id) then raise exception using errcode='23514',message='Output evidence is required before submission'; end if; if new.status='posted' and old.status not in ('approved','posted') then raise exception using errcode='23514',message='Approval required before posting'; end if; end if; return new; end $$;
drop trigger if exists guard_legacy_task_workflow on public.content_tasks; create trigger guard_legacy_task_workflow before update on public.content_tasks for each row execute function public.guard_legacy_task_workflow();
revoke all on function public.guard_legacy_task_workflow() from public,anon,authenticated;
create or replace function public.validate_legacy_campaign_scope() returns trigger language plpgsql security definer set search_path='' as $$ begin if new.department_id is not null and new.business_unit_id is not null and not exists(select 1 from public.departments d where d.id=new.department_id and d.business_unit_id=new.business_unit_id) then raise exception using errcode='23514',message='Department does not belong to selected business unit'; end if; return new; end $$;
drop trigger if exists validate_legacy_campaign_scope on public.campaigns; create trigger validate_legacy_campaign_scope before insert or update on public.campaigns for each row execute function public.validate_legacy_campaign_scope();
revoke all on function public.validate_legacy_campaign_scope() from public,anon,authenticated;
create or replace function public.submit_content_item_for_review(target_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  perform 1 from public.content_items where id=target_id for update;
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
  perform 1 from public.content_items where id=target_id for update;
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
create or replace function public.guard_content_item_workflow() returns trigger language plpgsql security invoker set search_path='' as $$ begin if (new.status is distinct from old.status or new.approval_status is distinct from old.approval_status or new.approval_remarks is distinct from old.approval_remarks) and (coalesce(current_setting('ieos.workflow_change',true),'')<>'on' or current_user<>pg_catalog.pg_get_userbyid((select relowner from pg_catalog.pg_class where oid='public.content_items'::regclass))) then raise exception using errcode='42501',message='Content workflow state must be changed through an approved workflow action.'; end if; return new; end $$;
create or replace function public.ieos_readiness() returns boolean language sql stable security invoker set search_path='' as $$ select public.fn_role(auth.uid()) is not null and to_regclass('public.work_tasks') is not null and to_regclass('public.daily_work_updates') is not null and to_regclass('public.master_files') is not null and to_regprocedure('public.create_marketing_campaign(uuid,uuid,text)') is not null and exists(select 1 from pg_catalog.pg_indexes where schemaname='public' and indexname='user_role_assignment_one_role_per_profile') and exists(select 1 from pg_catalog.pg_policies where schemaname='public' and tablename='sops' and policyname='p0_sops_select') $$;
revoke all on function public.fn_role(uuid) from public,anon; grant execute on function public.fn_role(uuid) to authenticated;
revoke all on function public.fn_is_super_admin(uuid) from public,anon; grant execute on function public.fn_is_super_admin(uuid) to authenticated;
revoke all on function public.fn_is_management(uuid) from public,anon; grant execute on function public.fn_is_management(uuid) to authenticated;
revoke all on function public.fn_has_business_unit_access(uuid,uuid) from public,anon; grant execute on function public.fn_has_business_unit_access(uuid,uuid) to authenticated;
revoke all on function public.fn_has_department_access(uuid,uuid) from public,anon; grant execute on function public.fn_has_department_access(uuid,uuid) to authenticated;
revoke all on function public.fn_task_department(uuid) from public,anon; grant execute on function public.fn_task_department(uuid) to authenticated;
revoke all on function public.assign_application_role(uuid,text) from public,anon; grant execute on function public.assign_application_role(uuid,text) to authenticated;
revoke all on function public.ieos_readiness() from public,anon; grant execute on function public.ieos_readiness() to authenticated;
alter table public.organisations enable row level security; revoke all on public.organisations from anon; grant select,insert,update,delete on public.organisations to authenticated;
alter table public.business_units enable row level security; revoke all on public.business_units from anon; grant select,insert,update,delete on public.business_units to authenticated;
alter table public.departments enable row level security; revoke all on public.departments from anon; grant select,insert,update,delete on public.departments to authenticated;
alter table public.teams enable row level security; revoke all on public.teams from anon; grant select,insert,update,delete on public.teams to authenticated;
alter table public.profiles enable row level security; revoke all on public.profiles from anon; grant select,insert,update,delete on public.profiles to authenticated;
alter table public.user_role_assignment enable row level security; revoke all on public.user_role_assignment from anon; grant select,insert,update,delete on public.user_role_assignment to authenticated;
alter table public.user_business_unit_access enable row level security; revoke all on public.user_business_unit_access from anon; grant select,insert,update,delete on public.user_business_unit_access to authenticated;
alter table public.user_department_access enable row level security; revoke all on public.user_department_access from anon; grant select,insert,update,delete on public.user_department_access to authenticated;
alter table public.sops enable row level security; revoke all on public.sops from anon; grant select,insert,update,delete on public.sops to authenticated;
alter table public.content_tasks enable row level security; revoke all on public.content_tasks from anon; grant select,insert,update,delete on public.content_tasks to authenticated;
alter table public.work_files enable row level security; revoke all on public.work_files from anon; grant select,insert,update,delete on public.work_files to authenticated;
alter table public.activities enable row level security; revoke all on public.activities from anon; grant select,insert,update,delete on public.activities to authenticated;
alter table public.content_ideas enable row level security; revoke all on public.content_ideas from anon; grant select,insert,update,delete on public.content_ideas to authenticated;
alter table public.knowledge_items enable row level security; revoke all on public.knowledge_items from anon; grant select,insert,update,delete on public.knowledge_items to authenticated;
alter table public.campaigns enable row level security; revoke all on public.campaigns from anon; grant select,insert,update,delete on public.campaigns to authenticated;
alter table public.content_items enable row level security; revoke all on public.content_items from anon; grant select,insert,update,delete on public.content_items to authenticated;
alter table public.platform_publications enable row level security; revoke all on public.platform_publications from anon; grant select,insert,update,delete on public.platform_publications to authenticated;
alter table public.approval_categories enable row level security; revoke all on public.approval_categories from anon; grant select,insert,update,delete on public.approval_categories to authenticated;
alter table public.approval_action enable row level security; revoke all on public.approval_action from anon; grant select,insert,update,delete on public.approval_action to authenticated;
alter table public.record_edit_log enable row level security; revoke all on public.record_edit_log from anon; grant select,insert,update,delete on public.record_edit_log to authenticated;
create or replace function public.fn_ml_attention_reason(target_lead public.marketing_leads)
returns text language sql stable set search_path = '' as $$
  select case
    when target_lead.status in ('signed_up','not_suitable','withdrawn','closed_other') then null
    when target_lead.last_contact_at is null
      and target_lead.date_received + make_interval(hours => public.fn_ml_initial_response_hours()) < now()
      then 'OVERDUE INITIAL RESPONSE'
    when target_lead.next_follow_up_at < now() then 'OVERDUE FOLLOW-UP'
    when (target_lead.next_follow_up_at at time zone 'Asia/Kuala_Lumpur')::date = (now() at time zone 'Asia/Kuala_Lumpur')::date then 'DUE TODAY'
    when target_lead.last_contact_at is null then 'NEW / UNCONTACTED'
    when target_lead.status = 'consultation_booked'
      and target_lead.consultation_date between now() and now() + interval '7 days'
      then 'CONSULTATION UPCOMING'
    else null
  end;
$$;
commit;
