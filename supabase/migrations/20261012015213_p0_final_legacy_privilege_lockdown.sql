-- P0: explicit object privileges, independent of row policies. No row mutation.
-- Forward migration after Stage 1-5, configuration and both earlier P0 migrations.
begin;
do $$ begin
 if current_user <> 'postgres' then raise exception 'P0 grants require the reviewed postgres migration owner'; end if;
 if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','f') and (c.relname <> all(array['activities','application_access_events','approval_action','approval_categories','business_units','campaigns','content_ideas','content_items','content_tasks','daily_update_reviews','daily_work_updates','departments','knowledge_items','lead_interactions','marketing_lead_access_events','marketing_lead_access_grants','marketing_lead_events','marketing_lead_settings','marketing_lead_sources','marketing_lead_task_links','marketing_leads','master_file_access_grants','master_file_artifacts','master_file_categories','master_file_events','master_file_review','master_file_settings','master_file_tasks','master_files','organisations','platform_publications','profiles','record_edit_log','sops','teams','user_business_unit_access','user_department_access','user_role_assignment','work_dashboard_access_grants','work_dashboard_attention','work_dashboard_daily_updates','work_dashboard_settings','work_files','work_task_access_grants','work_task_artifacts','work_task_attention','work_task_comments','work_task_events','work_task_updates','work_tasks']) or c.relowner <> (select oid from pg_roles where rolname=current_user))) then
  raise exception 'P0 grants preflight: unexpected relation/owner; stop for review';
 end if;

 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proowner<>(select oid from pg_roles where rolname=current_user)
 and not exists(select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')) then
 raise exception 'P0 grants preflight: unexpected routine owner; stop for review';
 end if;
end $$;
revoke create on schema public from public,anon,authenticated;
grant usage on schema public to authenticated;
revoke all privileges on table public.activities from public,anon,authenticated;
grant SELECT,INSERT on table public.activities to authenticated;
revoke all privileges on table public.application_access_events from public,anon,authenticated;
grant SELECT on table public.application_access_events to authenticated;
revoke all privileges on table public.approval_action from public,anon,authenticated;
grant SELECT on table public.approval_action to authenticated;
revoke all privileges on table public.approval_categories from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.approval_categories to authenticated;
revoke all privileges on table public.business_units from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.business_units to authenticated;
revoke all privileges on table public.campaigns from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.campaigns to authenticated;
revoke all privileges on table public.content_ideas from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.content_ideas to authenticated;
revoke all privileges on table public.content_items from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.content_items to authenticated;
revoke all privileges on table public.content_tasks from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.content_tasks to authenticated;
revoke all privileges on table public.daily_update_reviews from public,anon,authenticated;
grant SELECT on table public.daily_update_reviews to authenticated;
revoke all privileges on table public.daily_work_updates from public,anon,authenticated;
grant SELECT on table public.daily_work_updates to authenticated;
revoke all privileges on table public.departments from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.departments to authenticated;
revoke all privileges on table public.knowledge_items from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.knowledge_items to authenticated;
revoke all privileges on table public.lead_interactions from public,anon,authenticated;
grant SELECT on table public.lead_interactions to authenticated;
revoke all privileges on table public.marketing_lead_access_events from public,anon,authenticated;
grant SELECT on table public.marketing_lead_access_events to authenticated;
revoke all privileges on table public.marketing_lead_access_grants from public,anon,authenticated;
grant SELECT on table public.marketing_lead_access_grants to authenticated;
revoke all privileges on table public.marketing_lead_events from public,anon,authenticated;
grant SELECT on table public.marketing_lead_events to authenticated;
revoke all privileges on table public.marketing_lead_settings from public,anon,authenticated;
grant SELECT on table public.marketing_lead_settings to authenticated;
revoke all privileges on table public.marketing_lead_sources from public,anon,authenticated;
grant SELECT on table public.marketing_lead_sources to authenticated;
revoke all privileges on table public.marketing_lead_task_links from public,anon,authenticated;
grant SELECT on table public.marketing_lead_task_links to authenticated;
revoke all privileges on table public.marketing_leads from public,anon,authenticated;
grant SELECT on table public.marketing_leads to authenticated;
revoke all privileges on table public.master_file_access_grants from public,anon,authenticated;
grant SELECT on table public.master_file_access_grants to authenticated;
revoke all privileges on table public.master_file_artifacts from public,anon,authenticated;
grant SELECT on table public.master_file_artifacts to authenticated;
revoke all privileges on table public.master_file_categories from public,anon,authenticated;
grant SELECT on table public.master_file_categories to authenticated;
revoke all privileges on table public.master_file_events from public,anon,authenticated;
grant SELECT on table public.master_file_events to authenticated;
revoke all privileges on table public.master_file_review from public,anon,authenticated;
grant SELECT on table public.master_file_review to authenticated;
revoke all privileges on table public.master_file_settings from public,anon,authenticated;
grant SELECT on table public.master_file_settings to authenticated;
revoke all privileges on table public.master_file_tasks from public,anon,authenticated;
grant SELECT on table public.master_file_tasks to authenticated;
revoke all privileges on table public.master_files from public,anon,authenticated;
grant SELECT on table public.master_files to authenticated;
revoke all privileges on table public.organisations from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.organisations to authenticated;
revoke all privileges on table public.platform_publications from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.platform_publications to authenticated;
revoke all privileges on table public.profiles from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.profiles to authenticated;
revoke all privileges on table public.record_edit_log from public,anon,authenticated;
grant SELECT on table public.record_edit_log to authenticated;
revoke all privileges on table public.sops from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.sops to authenticated;
revoke all privileges on table public.teams from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.teams to authenticated;
revoke all privileges on table public.user_business_unit_access from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.user_business_unit_access to authenticated;
revoke all privileges on table public.user_department_access from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.user_department_access to authenticated;
revoke all privileges on table public.user_role_assignment from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.user_role_assignment to authenticated;
revoke all privileges on table public.work_dashboard_access_grants from public,anon,authenticated;
grant SELECT on table public.work_dashboard_access_grants to authenticated;
revoke all privileges on table public.work_dashboard_attention from public,anon,authenticated;
grant SELECT on table public.work_dashboard_attention to authenticated;
revoke all privileges on table public.work_dashboard_daily_updates from public,anon,authenticated;
grant SELECT on table public.work_dashboard_daily_updates to authenticated;
revoke all privileges on table public.work_dashboard_settings from public,anon,authenticated;
grant SELECT on table public.work_dashboard_settings to authenticated;
revoke all privileges on table public.work_files from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table public.work_files to authenticated;
revoke all privileges on table public.work_task_access_grants from public,anon,authenticated;
grant SELECT on table public.work_task_access_grants to authenticated;
revoke all privileges on table public.work_task_artifacts from public,anon,authenticated;
grant SELECT on table public.work_task_artifacts to authenticated;
revoke all privileges on table public.work_task_attention from public,anon,authenticated;
grant SELECT on table public.work_task_attention to authenticated;
revoke all privileges on table public.work_task_comments from public,anon,authenticated;
grant SELECT on table public.work_task_comments to authenticated;
revoke all privileges on table public.work_task_events from public,anon,authenticated;
grant SELECT on table public.work_task_events to authenticated;
revoke all privileges on table public.work_task_updates from public,anon,authenticated;
grant SELECT on table public.work_task_updates to authenticated;
revoke all privileges on table public.work_tasks from public,anon,authenticated;
grant SELECT on table public.work_tasks to authenticated;
-- Application sequences are advanced only by their owner through reviewed RPCs.
revoke all privileges on all sequences in schema public from public,anon,authenticated;
-- Retain platform-owned extension routines; reset every application-owned routine.
do $$ declare f record; begin
 for f in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and not exists(select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e') loop
  execute format('revoke all privileges on function %s from public,anon,authenticated',f.signature);
 end loop;
end $$;
-- Reviewed existing RPCs and RLS/view helpers only. No trigger or low-level lookup API.
grant execute on function public.add_lead_interaction(uuid,timestamptz,text,text,text,timestamptz,text,text) to authenticated;
grant execute on function public.add_managed_work_task_artifact(uuid,text,text,text,text) to authenticated;
grant execute on function public.add_work_task_artifact(uuid,text,text,text) to authenticated;
grant execute on function public.add_work_task_comment(uuid,text,boolean) to authenticated;
grant execute on function public.assign_application_role(uuid,text) to authenticated;
grant execute on function public.comment_on_content_item(uuid,text) to authenticated;
grant execute on function public.create_lead_followup_task(uuid,date,text) to authenticated;
grant execute on function public.create_marketing_campaign(uuid,uuid,text) to authenticated;
grant execute on function public.create_marketing_lead(timestamptz,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,uuid,text,timestamptz,timestamptz,numeric,text,text,boolean) to authenticated;
grant execute on function public.create_master_file(text,uuid,uuid,text,text,uuid,text,text,text,text,text,text,boolean,text,uuid,boolean) to authenticated;
grant execute on function public.create_work_task(uuid,uuid,uuid,text,text,text,text,boolean,date,text,text,text,boolean) to authenticated;
grant execute on function public.fn_can_approve_content_item(uuid,uuid) to authenticated;
grant execute on function public.fn_can_edit_content_item(uuid,uuid) to authenticated;
grant execute on function public.fn_has_business_unit_access(uuid,uuid) to authenticated;
grant execute on function public.fn_has_department_access(uuid,uuid) to authenticated;
grant execute on function public.fn_is_management(uuid) to authenticated;
grant execute on function public.fn_is_super_admin(uuid) to authenticated;
grant execute on function public.fn_mf_can_manage_file(uuid,uuid) to authenticated;
grant execute on function public.fn_mf_can_manage_settings(uuid) to authenticated;
grant execute on function public.fn_mf_can_use(uuid) to authenticated;
grant execute on function public.fn_mf_can_view_file(uuid,uuid) to authenticated;
grant execute on function public.fn_mf_verification_stale_days() to authenticated;
grant execute on function public.fn_ml_can_access_module(uuid) to authenticated;
grant execute on function public.fn_ml_can_interact(uuid,uuid) to authenticated;
grant execute on function public.fn_ml_can_manage_lead(uuid,uuid) to authenticated;
grant execute on function public.fn_ml_can_view_lead(uuid,uuid) to authenticated;
grant execute on function public.fn_ml_is_director(uuid) to authenticated;
grant execute on function public.fn_role(uuid) to authenticated;
grant execute on function public.fn_task_department(uuid) to authenticated;
grant execute on function public.fn_wm_business_date() to authenticated;
grant execute on function public.fn_wm_can_audit_dashboard_grants(uuid) to authenticated;
grant execute on function public.fn_wm_can_manage_task(uuid,uuid) to authenticated;
grant execute on function public.fn_wm_can_view_artifact(uuid,uuid) to authenticated;
grant execute on function public.fn_wm_can_view_dashboard(uuid) to authenticated;
grant execute on function public.fn_wm_can_view_task(uuid,uuid) to authenticated;
grant execute on function public.fn_wm_previous_working_day(date) to authenticated;
grant execute on function public.fn_wm_supervisor_review_threshold() to authenticated;
grant execute on function public.fn_wm_task_has_completion_artifact(uuid) to authenticated;
grant execute on function public.fn_wm_working_days_elapsed(date,date) to authenticated;
grant execute on function public.get_marketing_lead_audit(uuid) to authenticated;
grant execute on function public.get_marketing_lead_duplicate_warnings(uuid) to authenticated;
grant execute on function public.get_marketing_lead_summary(uuid) to authenticated;
grant execute on function public.get_master_file_audit(uuid) to authenticated;
grant execute on function public.get_work_dashboard_missing_updates_today(uuid,uuid,uuid,text) to authenticated;
grant execute on function public.get_work_dashboard_team_workload(uuid,uuid,uuid,text,text,text,date,date) to authenticated;
grant execute on function public.grant_marketing_lead_access(uuid,uuid,uuid,boolean) to authenticated;
grant execute on function public.grant_master_file_access(uuid,uuid,text) to authenticated;
grant execute on function public.grant_work_task_access(uuid,uuid,text) to authenticated;
grant execute on function public.ieos_readiness() to authenticated;
grant execute on function public.link_master_file_artifact(uuid,uuid) to authenticated;
grant execute on function public.link_master_file_task(uuid,uuid) to authenticated;
grant execute on function public.list_work_dashboard_projects() to authenticated;
grant execute on function public.list_work_task_assignees() to authenticated;
grant execute on function public.mark_marketing_lead_duplicate(uuid,uuid) to authenticated;
grant execute on function public.mark_master_file_duplicate(uuid,uuid) to authenticated;
grant execute on function public.quick_update_work_task(uuid,text,integer,text,boolean) to authenticated;
grant execute on function public.review_content_item(uuid,text,text) to authenticated;
grant execute on function public.review_daily_work_update(uuid,text,text,boolean) to authenticated;
grant execute on function public.revoke_marketing_lead_access(uuid,uuid,uuid) to authenticated;
grant execute on function public.revoke_master_file_access(uuid,uuid,text) to authenticated;
grant execute on function public.search_marketing_leads(text,uuid,uuid,text,text,uuid,text,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,boolean,uuid,integer) to authenticated;
grant execute on function public.search_master_files(text,uuid,uuid,text,uuid,text,text,text,boolean,boolean,uuid,integer) to authenticated;
grant execute on function public.set_master_file_status(uuid,text) to authenticated;
grant execute on function public.submit_content_item_for_review(uuid) to authenticated;
grant execute on function public.submit_daily_work_update(uuid,text,text,text,boolean,text,text,boolean) to authenticated;
grant execute on function public.supersede_master_file(uuid,uuid) to authenticated;
grant execute on function public.supervise_work_task(uuid,text,text,boolean,boolean,text,boolean,boolean,boolean) to authenticated;
grant execute on function public.update_marketing_lead(uuid,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,uuid,text,timestamptz,timestamptz,text,numeric,text,text,boolean) to authenticated;
grant execute on function public.update_master_file_metadata(uuid,text,uuid,uuid,text,text,uuid,text,text,text,text,text,boolean,text,boolean) to authenticated;
grant execute on function public.update_work_task_management(uuid,uuid,uuid,uuid,text,text,text,text,boolean,date,text,text,boolean) to authenticated;
grant execute on function public.upsert_master_file_category(text,text,smallint,boolean) to authenticated;
grant execute on function public.verify_master_file(uuid) to authenticated;
-- Defaults belong to the creator, not its inherited roles. PostgreSQL schema defaults
-- add to global defaults, so revoke both. This changes FUTURE postgres-created
-- objects database-wide; other schemas now require explicit grants too.
alter default privileges for role postgres revoke all privileges on tables from public,anon,authenticated;
alter default privileges for role postgres revoke all privileges on sequences from public,anon,authenticated;
alter default privileges for role postgres revoke all privileges on functions from public,anon,authenticated;
alter default privileges for role postgres in schema public revoke all privileges on tables from public,anon,authenticated;
alter default privileges for role postgres in schema public revoke all privileges on sequences from public,anon,authenticated;
alter default privileges for role postgres in schema public revoke all privileges on functions from public,anon,authenticated;
-- Fail closed if inherited/column grants still confer structural operations.
do $$ begin
 if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace cross join (values('anon'),('authenticated')) r(role_name)
 where n.nspname='public' and c.relkind in ('r','p','v','m','f') and (has_table_privilege(r.role_name,c.oid,'TRUNCATE') or has_table_privilege(r.role_name,c.oid,'REFERENCES') or has_table_privilege(r.role_name,c.oid,'TRIGGER') or has_table_privilege(r.role_name,c.oid,'MAINTAIN') or has_any_column_privilege(r.role_name,c.oid,'REFERENCES'))) then
  raise exception 'P0 grants postflight: excess effective privilege; stop for owner/role review';
 end if;

 if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind in ('r','p','v','m','f') and
 (has_table_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,MAINTAIN')
 or has_any_column_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,REFERENCES'))) then
 raise exception 'P0 grants postflight: anonymous object or column access remains';
 end if;
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and not exists(select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')
 and has_function_privilege('anon',p.oid,'EXECUTE')) then
 raise exception 'P0 grants postflight: anonymous application routine execution remains';
 end if;
end $$;
commit;
