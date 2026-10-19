-- P0 legacy access hardening. Local candidate; hosted application requires a reviewed cutover.
-- No records are deleted; ambiguous multi-role profiles stop the migration for explicit resolution.
begin;
alter table staging.profiles add column if not exists is_active boolean not null default true;
do $$ begin if exists(select 1 from staging.user_role_assignment group by profile_id having count(*)>1) then raise exception 'P0 preflight: resolve multiple roles without deleting records before cutover'; end if; end $$;
create unique index if not exists user_role_assignment_one_role_per_profile on staging.user_role_assignment(profile_id);
create or replace function staging.fn_role(uid uuid) returns text language sql stable security definer set search_path='' as $$ select r.role from staging.user_role_assignment r join staging.profiles p on p.id=r.profile_id where uid=auth.uid() and r.profile_id=uid and p.is_active $$;
create or replace function staging.fn_is_super_admin(uid uuid) returns boolean language sql stable security invoker set search_path='' as $$ select coalesce(staging.fn_role(uid)='super_admin',false) $$;
create or replace function staging.fn_is_management(uid uuid) returns boolean language sql stable security invoker set search_path='' as $$ select coalesce(staging.fn_role(uid)='management',false) $$;
create or replace function staging.fn_has_business_unit_access(uid uuid,bu_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select coalesce(uid=auth.uid() and staging.fn_role(uid) is not null and (staging.fn_is_super_admin(uid) or exists(select 1 from staging.user_business_unit_access a where a.profile_id=uid and a.business_unit_id=bu_id)),false) $$;
create or replace function staging.fn_has_department_access(uid uuid,dept_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select coalesce(uid=auth.uid() and staging.fn_role(uid) is not null and (staging.fn_is_super_admin(uid) or (staging.fn_is_management(uid) and exists(select 1 from staging.departments d where d.id=dept_id and staging.fn_has_business_unit_access(uid,d.business_unit_id))) or exists(select 1 from staging.user_department_access a where a.profile_id=uid and a.department_id=dept_id)),false) $$;
create or replace function staging.fn_task_department(task_id uuid) returns uuid language sql stable security definer set search_path='' as $$ select t.department_id from staging.content_tasks t where t.id=$1 and (staging.fn_role(auth.uid()) is not null and ((t.department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),t.department_id))) $$;
create table if not exists staging.application_access_events(id uuid primary key default gen_random_uuid(),subject_id uuid not null references staging.profiles(id),actor_id uuid not null references staging.profiles(id),event_type text not null check(event_type in ('role_changed','activity_changed')),metadata jsonb not null,created_at timestamptz not null default now());
alter table staging.application_access_events enable row level security;
create or replace function staging.audit_application_access() returns trigger language plpgsql security definer set search_path='' as $$ begin if auth.uid() is not null then if tg_table_name='user_role_assignment' then insert into staging.application_access_events(subject_id,actor_id,event_type,metadata) values(new.profile_id,auth.uid(),'role_changed',jsonb_build_object('previous_role',case when tg_op='UPDATE' then old.role else null end,'new_role',new.role)); elsif new.is_active is distinct from old.is_active then insert into staging.application_access_events(subject_id,actor_id,event_type,metadata) values(new.id,auth.uid(),'activity_changed',jsonb_build_object('previous_active',old.is_active,'new_active',new.is_active)); end if; end if; return new; end $$;
create trigger audit_application_role after insert or update on staging.user_role_assignment for each row execute function staging.audit_application_access();
create trigger audit_profile_activity after update of is_active on staging.profiles for each row execute function staging.audit_application_access();
create trigger prevent_application_access_event_mutation before update or delete on staging.application_access_events for each row execute function staging.prevent_audit_mutation();
revoke all on function staging.audit_application_access() from public,anon,authenticated;
revoke all on staging.application_access_events from public,anon,authenticated;
grant select on staging.application_access_events to authenticated;
create policy p0_application_access_events_read on staging.application_access_events for select to authenticated using(staging.fn_is_super_admin(auth.uid()));
do $$ declare p record; begin for p in select tablename,policyname from pg_policies where schemaname='staging' and tablename=any(array['organisations','business_units','departments','teams','profiles','user_role_assignment','user_business_unit_access','user_department_access','sops','content_tasks','work_files','activities','content_ideas','knowledge_items','campaigns','content_items','platform_publications','approval_categories','approval_action','record_edit_log']) loop execute format('drop policy %I on %I.%I',p.policyname,'staging',p.tablename); end loop; end $$;
create policy p0_organisations_select on staging.organisations for select to authenticated using (staging.fn_role(auth.uid()) is not null);
create policy p0_organisations_all on staging.organisations for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_business_units_select on staging.business_units for select to authenticated using (staging.fn_role(auth.uid()) is not null and (is_active or staging.fn_is_super_admin(auth.uid())) and (staging.fn_has_business_unit_access(auth.uid(),id) or exists(select 1 from staging.departments d where d.business_unit_id=business_units.id and staging.fn_has_department_access(auth.uid(),d.id))));
create policy p0_business_units_all on staging.business_units for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_departments_select on staging.departments for select to authenticated using (staging.fn_has_business_unit_access(auth.uid(),business_unit_id) or staging.fn_has_department_access(auth.uid(),id));
create policy p0_departments_all on staging.departments for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_teams_select on staging.teams for select to authenticated using ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))));
create policy p0_teams_all on staging.teams for all to authenticated using (staging.fn_role(auth.uid()) in ('super_admin','management') and (staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id)))) with check (staging.fn_role(auth.uid()) in ('super_admin','management') and (staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))));
create policy p0_profiles_select on staging.profiles for select to authenticated using ((staging.fn_role(auth.uid()) is not null and id=auth.uid()) or staging.fn_is_super_admin(auth.uid()));
create policy p0_profiles_all on staging.profiles for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_user_role_assignment_select on staging.user_role_assignment for select to authenticated using ((staging.fn_role(auth.uid()) is not null and profile_id=auth.uid()) or staging.fn_is_super_admin(auth.uid()));
create policy p0_user_role_assignment_all on staging.user_role_assignment for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_user_business_unit_access_select on staging.user_business_unit_access for select to authenticated using ((staging.fn_role(auth.uid()) is not null and profile_id=auth.uid()) or staging.fn_is_super_admin(auth.uid()));
create policy p0_user_business_unit_access_all on staging.user_business_unit_access for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_user_department_access_select on staging.user_department_access for select to authenticated using ((staging.fn_role(auth.uid()) is not null and profile_id=auth.uid()) or staging.fn_is_super_admin(auth.uid()));
create policy p0_user_department_access_all on staging.user_department_access for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_sops_select on staging.sops for select to authenticated using ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))));
create policy p0_sops_insert on staging.sops for insert to authenticated with check ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and staging.fn_role(auth.uid()) in ('super_admin','management','staff'));
create policy p0_sops_update on staging.sops for update to authenticated using ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and staging.fn_role(auth.uid()) in ('super_admin','management','staff')) with check ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and staging.fn_role(auth.uid()) in ('super_admin','management','staff'));
create policy p0_sops_delete on staging.sops for delete to authenticated using (staging.fn_role(auth.uid()) in ('super_admin','management') and (staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))));
create policy p0_content_tasks_select on staging.content_tasks for select to authenticated using ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))));
create policy p0_content_tasks_insert on staging.content_tasks for insert to authenticated with check ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and (staging.fn_role(auth.uid())<>'intern' or user_id=auth.uid()) and status in ('assigned','in_progress') and (approval_status is null or approval_status='pending') and approval_remarks is null);
create policy p0_content_tasks_update on staging.content_tasks for update to authenticated using ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and (staging.fn_role(auth.uid())<>'intern' or user_id=auth.uid())) with check ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and (staging.fn_role(auth.uid())<>'intern' or user_id=auth.uid()));
create policy p0_content_tasks_delete on staging.content_tasks for delete to authenticated using (staging.fn_role(auth.uid()) in ('super_admin','management') and (staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))));
create policy p0_work_files_select on staging.work_files for select to authenticated using (exists(select 1 from staging.content_tasks t where t.id=task_id));
create policy p0_work_files_insert on staging.work_files for insert to authenticated with check (exists(select 1 from staging.content_tasks t where t.id=task_id) and (user_id is null or user_id=auth.uid()));
create policy p0_work_files_update on staging.work_files for update to authenticated using (exists(select 1 from staging.content_tasks t where t.id=task_id)) with check (exists(select 1 from staging.content_tasks t where t.id=task_id));
create policy p0_activities_select on staging.activities for select to authenticated using (exists(select 1 from staging.content_tasks t where t.id=task_id));
create policy p0_activities_insert on staging.activities for insert to authenticated with check (exists(select 1 from staging.content_tasks t where t.id=task_id) and (user_id is null or user_id=auth.uid()));
create or replace function staging.bind_legacy_actor() returns trigger language plpgsql security invoker set search_path='' as $$ begin if auth.uid() is not null then if tg_op='INSERT' then new.user_id:=auth.uid(); else new.user_id:=old.user_id; end if; if tg_table_name='activities' then select coalesce(p.full_name,p.email) into new.actor_name from staging.profiles p where p.id=auth.uid(); if new.action='approved' and (staging.fn_role(auth.uid()) not in ('super_admin','management') or not exists(select 1 from staging.content_tasks t where t.id=new.task_id and t.status='approved')) then raise exception using errcode='42501',message='Only a scoped supervisor can record an approved task'; end if; end if; end if; return new; end $$;
create trigger bind_activity_actor before insert on staging.activities for each row execute function staging.bind_legacy_actor();
create trigger bind_work_file_actor before insert or update on staging.work_files for each row execute function staging.bind_legacy_actor();
revoke all on function staging.bind_legacy_actor() from public,anon,authenticated;
create policy p0_content_ideas_all on staging.content_ideas for all to authenticated using (staging.fn_role(auth.uid()) in ('super_admin','management')) with check (staging.fn_role(auth.uid()) in ('super_admin','management'));
create policy p0_knowledge_items_all on staging.knowledge_items for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_campaigns_select on staging.campaigns for select to authenticated using ((staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))));
create policy p0_campaigns_all on staging.campaigns for all to authenticated using (staging.fn_role(auth.uid()) in ('super_admin','management') and (staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and (business_unit_id is null or staging.fn_has_business_unit_access(auth.uid(),business_unit_id))) with check (staging.fn_role(auth.uid()) in ('super_admin','management') and (staging.fn_role(auth.uid()) is not null and ((department_id is null and staging.fn_is_super_admin(auth.uid())) or staging.fn_has_department_access(auth.uid(),department_id))) and (business_unit_id is null or staging.fn_has_business_unit_access(auth.uid(),business_unit_id)));
create or replace function staging.fn_can_edit_content_item(uid uuid,target_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from staging.content_items ci where uid=auth.uid() and ci.id=target_id and ci.status in ('draft','in_progress','revision_required') and (staging.fn_role(auth.uid()) is not null and (staging.fn_is_super_admin(auth.uid()) or (ci.department_id is not null and staging.fn_has_department_access(auth.uid(),ci.department_id)) or (ci.department_id is null and ci.business_unit_id is not null and staging.fn_role(auth.uid())='management' and staging.fn_has_business_unit_access(auth.uid(),ci.business_unit_id)))) and (staging.fn_role(auth.uid())<>'intern' or ci.user_id=uid)) $$;
create or replace function staging.fn_can_approve_content_item(uid uuid,target_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from staging.content_items ci where uid=auth.uid() and ci.id=target_id and ci.status='awaiting_approval' and (staging.fn_role(auth.uid()) is not null and (staging.fn_is_super_admin(auth.uid()) or (ci.department_id is not null and staging.fn_has_department_access(auth.uid(),ci.department_id)) or (ci.department_id is null and ci.business_unit_id is not null and staging.fn_role(auth.uid())='management' and staging.fn_has_business_unit_access(auth.uid(),ci.business_unit_id)))) and ((ci.approval_category_id is null and staging.fn_role(auth.uid())='management') or (ci.approval_category_id is not null and staging.fn_role(auth.uid())='super_admin'))) $$;
create policy p0_content_items_select on staging.content_items for select to authenticated using ((staging.fn_role(auth.uid()) is not null and (staging.fn_is_super_admin(auth.uid()) or (department_id is not null and staging.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and staging.fn_role(auth.uid())='management' and staging.fn_has_business_unit_access(auth.uid(),business_unit_id)))));
create policy p0_content_items_insert on staging.content_items for insert to authenticated with check ((staging.fn_role(auth.uid()) is not null and (staging.fn_is_super_admin(auth.uid()) or (department_id is not null and staging.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and staging.fn_role(auth.uid())='management' and staging.fn_has_business_unit_access(auth.uid(),business_unit_id)))) and (staging.fn_role(auth.uid())<>'intern' or user_id=auth.uid()) and status in ('draft','in_progress') and (approval_status is null or approval_status='pending') and approval_remarks is null);
create policy p0_content_items_update on staging.content_items for update to authenticated using (staging.fn_can_edit_content_item(auth.uid(),id)) with check ((staging.fn_role(auth.uid()) is not null and (staging.fn_is_super_admin(auth.uid()) or (department_id is not null and staging.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and staging.fn_role(auth.uid())='management' and staging.fn_has_business_unit_access(auth.uid(),business_unit_id)))) and (staging.fn_role(auth.uid())<>'intern' or user_id=auth.uid()));
create policy p0_content_items_delete on staging.content_items for delete to authenticated using (staging.fn_role(auth.uid()) in ('super_admin','management') and (staging.fn_role(auth.uid()) is not null and (staging.fn_is_super_admin(auth.uid()) or (department_id is not null and staging.fn_has_department_access(auth.uid(),department_id)) or (department_id is null and business_unit_id is not null and staging.fn_role(auth.uid())='management' and staging.fn_has_business_unit_access(auth.uid(),business_unit_id)))));
create policy p0_platform_publications_select on staging.platform_publications for select to authenticated using (exists(select 1 from staging.content_items c where c.id=content_item_id));
create policy p0_platform_publications_all on staging.platform_publications for all to authenticated using (exists(select 1 from staging.content_items c where c.id=content_item_id) and (staging.fn_role(auth.uid())<>'intern' or user_id=auth.uid())) with check (exists(select 1 from staging.content_items c where c.id=content_item_id) and (staging.fn_role(auth.uid())<>'intern' or user_id=auth.uid()));
create policy p0_approval_categories_select on staging.approval_categories for select to authenticated using (staging.fn_role(auth.uid()) is not null);
create policy p0_approval_categories_all on staging.approval_categories for all to authenticated using (staging.fn_is_super_admin(auth.uid())) with check (staging.fn_is_super_admin(auth.uid()));
create policy p0_approval_action_select on staging.approval_action for select to authenticated using (exists(select 1 from staging.content_items c where c.id=content_item_id));
create policy p0_record_edit_log_select on staging.record_edit_log for select to authenticated using (case table_name when 'sops' then exists(select 1 from staging.sops x where x.id=record_id) when 'content_ideas' then exists(select 1 from staging.content_ideas x where x.id=record_id) when 'knowledge_items' then exists(select 1 from staging.knowledge_items x where x.id=record_id) else false end);
create or replace function staging.assign_application_role(p_profile_id uuid,p_role text) returns void language plpgsql security definer set search_path='' as $$ begin if not staging.fn_is_super_admin(auth.uid()) then raise exception using errcode='42501',message='Active Super Admin required'; end if; if p_role is null or p_role not in ('super_admin','management','staff','intern') then raise exception using errcode='22023',message='Invalid application role'; end if; insert into staging.user_role_assignment(profile_id,role) values(p_profile_id,p_role) on conflict(profile_id) do update set role=excluded.role; end $$;
create or replace function staging.guard_legacy_task_workflow() returns trigger language plpgsql security invoker set search_path='' as $$ begin if auth.uid() is not null then if ((new.status in ('approved','amendment') and new.status is distinct from old.status) or (new.approval_status in ('approved','amend') and new.approval_status is distinct from old.approval_status) or new.approval_remarks is distinct from old.approval_remarks) and staging.fn_role(auth.uid()) not in ('super_admin','management') then raise exception using errcode='42501',message='Supervisor review required'; end if; if new.status='submitted' and old.status is distinct from new.status and nullif(btrim(new.work_link),'') is null and not exists(select 1 from staging.work_files f where f.task_id=new.id) then raise exception using errcode='23514',message='Output evidence is required before submission'; end if; if new.status='posted' and old.status not in ('approved','posted') then raise exception using errcode='23514',message='Approval required before posting'; end if; end if; return new; end $$;
drop trigger if exists guard_legacy_task_workflow on staging.content_tasks; create trigger guard_legacy_task_workflow before update on staging.content_tasks for each row execute function staging.guard_legacy_task_workflow();
revoke all on function staging.guard_legacy_task_workflow() from public,anon,authenticated;
create or replace function staging.validate_legacy_campaign_scope() returns trigger language plpgsql security definer set search_path='' as $$ begin if new.department_id is not null and new.business_unit_id is not null and not exists(select 1 from staging.departments d where d.id=new.department_id and d.business_unit_id=new.business_unit_id) then raise exception using errcode='23514',message='Department does not belong to selected business unit'; end if; return new; end $$;
drop trigger if exists validate_legacy_campaign_scope on staging.campaigns; create trigger validate_legacy_campaign_scope before insert or update on staging.campaigns for each row execute function staging.validate_legacy_campaign_scope();
revoke all on function staging.validate_legacy_campaign_scope() from public,anon,authenticated;
create or replace function staging.submit_content_item_for_review(target_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  perform 1 from staging.content_items where id=target_id for update;
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
  perform 1 from staging.content_items where id=target_id for update;
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
create or replace function staging.guard_content_item_workflow() returns trigger language plpgsql security invoker set search_path='' as $$ begin if (new.status is distinct from old.status or new.approval_status is distinct from old.approval_status or new.approval_remarks is distinct from old.approval_remarks) and (coalesce(current_setting('ieos.workflow_change',true),'')<>'on' or current_user<>pg_catalog.pg_get_userbyid((select relowner from pg_catalog.pg_class where oid='staging.content_items'::regclass))) then raise exception using errcode='42501',message='Content workflow state must be changed through an approved workflow action.'; end if; return new; end $$;
create or replace function staging.ieos_readiness() returns boolean language sql stable security invoker set search_path='' as $$ select staging.fn_role(auth.uid()) is not null and to_regclass('staging.work_tasks') is not null and to_regclass('staging.daily_work_updates') is not null and to_regclass('staging.master_files') is not null and to_regprocedure('staging.create_marketing_campaign(uuid,uuid,text)') is not null and exists(select 1 from pg_catalog.pg_indexes where schemaname='staging' and indexname='user_role_assignment_one_role_per_profile') and exists(select 1 from pg_catalog.pg_policies where schemaname='staging' and tablename='sops' and policyname='p0_sops_select') $$;
revoke all on function staging.fn_role(uuid) from public,anon; grant execute on function staging.fn_role(uuid) to authenticated;
revoke all on function staging.fn_is_super_admin(uuid) from public,anon; grant execute on function staging.fn_is_super_admin(uuid) to authenticated;
revoke all on function staging.fn_is_management(uuid) from public,anon; grant execute on function staging.fn_is_management(uuid) to authenticated;
revoke all on function staging.fn_has_business_unit_access(uuid,uuid) from public,anon; grant execute on function staging.fn_has_business_unit_access(uuid,uuid) to authenticated;
revoke all on function staging.fn_has_department_access(uuid,uuid) from public,anon; grant execute on function staging.fn_has_department_access(uuid,uuid) to authenticated;
revoke all on function staging.fn_task_department(uuid) from public,anon; grant execute on function staging.fn_task_department(uuid) to authenticated;
revoke all on function staging.assign_application_role(uuid,text) from public,anon; grant execute on function staging.assign_application_role(uuid,text) to authenticated;
revoke all on function staging.ieos_readiness() from public,anon; grant execute on function staging.ieos_readiness() to authenticated;
alter table staging.organisations enable row level security; revoke all on staging.organisations from anon; grant select,insert,update,delete on staging.organisations to authenticated;
alter table staging.business_units enable row level security; revoke all on staging.business_units from anon; grant select,insert,update,delete on staging.business_units to authenticated;
alter table staging.departments enable row level security; revoke all on staging.departments from anon; grant select,insert,update,delete on staging.departments to authenticated;
alter table staging.teams enable row level security; revoke all on staging.teams from anon; grant select,insert,update,delete on staging.teams to authenticated;
alter table staging.profiles enable row level security; revoke all on staging.profiles from anon; grant select,insert,update,delete on staging.profiles to authenticated;
alter table staging.user_role_assignment enable row level security; revoke all on staging.user_role_assignment from anon; grant select,insert,update,delete on staging.user_role_assignment to authenticated;
alter table staging.user_business_unit_access enable row level security; revoke all on staging.user_business_unit_access from anon; grant select,insert,update,delete on staging.user_business_unit_access to authenticated;
alter table staging.user_department_access enable row level security; revoke all on staging.user_department_access from anon; grant select,insert,update,delete on staging.user_department_access to authenticated;
alter table staging.sops enable row level security; revoke all on staging.sops from anon; grant select,insert,update,delete on staging.sops to authenticated;
alter table staging.content_tasks enable row level security; revoke all on staging.content_tasks from anon; grant select,insert,update,delete on staging.content_tasks to authenticated;
alter table staging.work_files enable row level security; revoke all on staging.work_files from anon; grant select,insert,update,delete on staging.work_files to authenticated;
alter table staging.activities enable row level security; revoke all on staging.activities from anon; grant select,insert,update,delete on staging.activities to authenticated;
alter table staging.content_ideas enable row level security; revoke all on staging.content_ideas from anon; grant select,insert,update,delete on staging.content_ideas to authenticated;
alter table staging.knowledge_items enable row level security; revoke all on staging.knowledge_items from anon; grant select,insert,update,delete on staging.knowledge_items to authenticated;
alter table staging.campaigns enable row level security; revoke all on staging.campaigns from anon; grant select,insert,update,delete on staging.campaigns to authenticated;
alter table staging.content_items enable row level security; revoke all on staging.content_items from anon; grant select,insert,update,delete on staging.content_items to authenticated;
alter table staging.platform_publications enable row level security; revoke all on staging.platform_publications from anon; grant select,insert,update,delete on staging.platform_publications to authenticated;
alter table staging.approval_categories enable row level security; revoke all on staging.approval_categories from anon; grant select,insert,update,delete on staging.approval_categories to authenticated;
alter table staging.approval_action enable row level security; revoke all on staging.approval_action from anon; grant select,insert,update,delete on staging.approval_action to authenticated;
alter table staging.record_edit_log enable row level security; revoke all on staging.record_edit_log from anon; grant select,insert,update,delete on staging.record_edit_log to authenticated;
commit;
