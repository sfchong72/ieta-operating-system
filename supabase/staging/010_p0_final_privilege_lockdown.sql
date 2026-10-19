-- P0: explicit object privileges, independent of row policies. No row mutation.
-- LOCAL TEST MIRROR ONLY; not a hosted adoption migration.
begin;
do $$ begin
 if current_user <> 'postgres' then raise exception 'P0 grants require the reviewed postgres migration owner'; end if;
 if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='staging' and c.relkind in ('r','p','v','m','f') and (c.relname <> all(array['activities','application_access_events','approval_action','approval_categories','business_units','campaigns','content_ideas','content_items','content_tasks','departments','knowledge_items','organisations','platform_publications','profiles','record_edit_log','sops','teams','user_business_unit_access','user_department_access','user_role_assignment','work_files']) or c.relowner <> (select oid from pg_roles where rolname=current_user))) then
  raise exception 'P0 grants preflight: unexpected relation/owner; stop for review';
 end if;

 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='staging' and p.proowner<>(select oid from pg_roles where rolname=current_user)
 and not exists(select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')) then
 raise exception 'P0 grants preflight: unexpected routine owner; stop for review';
 end if;
end $$;
revoke create on schema staging from public,anon,authenticated;
revoke usage on schema staging from public,anon;
grant usage on schema staging to authenticated;
revoke all privileges on table staging.activities from public,anon,authenticated;
grant SELECT,INSERT on table staging.activities to authenticated;
revoke all privileges on table staging.application_access_events from public,anon,authenticated;
grant SELECT on table staging.application_access_events to authenticated;
revoke all privileges on table staging.approval_action from public,anon,authenticated;
grant SELECT on table staging.approval_action to authenticated;
revoke all privileges on table staging.approval_categories from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.approval_categories to authenticated;
revoke all privileges on table staging.business_units from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.business_units to authenticated;
revoke all privileges on table staging.campaigns from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.campaigns to authenticated;
revoke all privileges on table staging.content_ideas from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.content_ideas to authenticated;
revoke all privileges on table staging.content_items from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.content_items to authenticated;
revoke all privileges on table staging.content_tasks from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.content_tasks to authenticated;
revoke all privileges on table staging.departments from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.departments to authenticated;
revoke all privileges on table staging.knowledge_items from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.knowledge_items to authenticated;
revoke all privileges on table staging.organisations from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.organisations to authenticated;
revoke all privileges on table staging.platform_publications from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.platform_publications to authenticated;
revoke all privileges on table staging.profiles from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.profiles to authenticated;
revoke all privileges on table staging.record_edit_log from public,anon,authenticated;
grant SELECT on table staging.record_edit_log to authenticated;
revoke all privileges on table staging.sops from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.sops to authenticated;
revoke all privileges on table staging.teams from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.teams to authenticated;
revoke all privileges on table staging.user_business_unit_access from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.user_business_unit_access to authenticated;
revoke all privileges on table staging.user_department_access from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.user_department_access to authenticated;
revoke all privileges on table staging.user_role_assignment from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.user_role_assignment to authenticated;
revoke all privileges on table staging.work_files from public,anon,authenticated;
grant SELECT,INSERT,UPDATE,DELETE on table staging.work_files to authenticated;
-- Application sequences are advanced only by their owner through reviewed RPCs.
revoke all privileges on all sequences in schema staging from public,anon,authenticated;
-- Retain platform-owned extension routines; reset every application-owned routine.
do $$ declare f record; begin
 for f in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='staging' and not exists(select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e') loop
  execute format('revoke all privileges on function %s from public,anon,authenticated',f.signature);
 end loop;
end $$;
-- Reviewed existing RPCs and RLS/view helpers only. No trigger or low-level lookup API.
grant execute on function staging.assign_application_role(uuid,text) to authenticated;
grant execute on function staging.comment_on_content_item(uuid,text) to authenticated;
grant execute on function staging.fn_can_approve_content_item(uuid,uuid) to authenticated;
grant execute on function staging.fn_can_edit_content_item(uuid,uuid) to authenticated;
grant execute on function staging.fn_has_business_unit_access(uuid,uuid) to authenticated;
grant execute on function staging.fn_has_department_access(uuid,uuid) to authenticated;
grant execute on function staging.fn_is_management(uuid) to authenticated;
grant execute on function staging.fn_is_super_admin(uuid) to authenticated;
grant execute on function staging.fn_role(uuid) to authenticated;
grant execute on function staging.fn_task_department(uuid) to authenticated;
grant execute on function staging.ieos_readiness() to authenticated;
grant execute on function staging.review_content_item(uuid,text,text) to authenticated;
grant execute on function staging.submit_content_item_for_review(uuid) to authenticated;
alter default privileges for role postgres in schema staging revoke all privileges on tables from public,anon,authenticated;
alter default privileges for role postgres in schema staging revoke all privileges on sequences from public,anon,authenticated;
alter default privileges for role postgres in schema staging revoke all privileges on functions from public,anon,authenticated;
-- Fail closed if inherited/column grants still confer structural operations.
do $$ begin
 if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace cross join (values('anon'),('authenticated')) r(role_name)
 where n.nspname='staging' and c.relkind in ('r','p','v','m','f') and (has_table_privilege(r.role_name,c.oid,'TRUNCATE') or has_table_privilege(r.role_name,c.oid,'REFERENCES') or has_table_privilege(r.role_name,c.oid,'TRIGGER') or has_table_privilege(r.role_name,c.oid,'MAINTAIN') or has_any_column_privilege(r.role_name,c.oid,'REFERENCES'))) then
  raise exception 'P0 grants postflight: excess effective privilege; stop for owner/role review';
 end if;

 if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='staging' and c.relkind in ('r','p','v','m','f') and
 (has_table_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,MAINTAIN')
 or has_any_column_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,REFERENCES'))) then
 raise exception 'P0 grants postflight: anonymous object or column access remains';
 end if;
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='staging' and not exists(select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')
 and has_function_privilege('anon',p.oid,'EXECUTE')) then
 raise exception 'P0 grants postflight: anonymous application routine execution remains';
 end if;
end $$;
commit;
