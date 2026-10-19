
-- DISPOSABLE REHEARSAL ONLY. Not an automatically deployed migration.
begin;
do $$ begin if current_database()<>'p0_hosted_adoption' then raise exception 'Wrong quarantine database'; end if; end $$;
revoke all privileges on schema staging from public,anon,authenticated;
revoke all privileges on all tables in schema staging from public,anon,authenticated;
revoke all privileges on all sequences in schema staging from public,anon,authenticated;
revoke all privileges on all functions in schema staging from public,anon,authenticated;
alter default privileges for role postgres in schema staging revoke all privileges on tables from public,anon,authenticated;
alter default privileges for role postgres in schema staging revoke all privileges on sequences from public,anon,authenticated;
alter default privileges for role postgres in schema staging revoke all privileges on functions from public,anon,authenticated;
select extensions.plan(4);
select extensions.ok(not has_schema_privilege('anon','staging','USAGE') and not has_schema_privilege('authenticated','staging','USAGE'),'Staging quarantine denies both API roles');
select extensions.ok(not exists(select 1 from ieos_stage1_test.p0_original_columns s where s.digest<>ieos_stage1_test.p0_original_digest(s.schema_name,s.table_name,s.column_names)),'Quarantine preserves all historical records');
select extensions.is((select count(*)::integer from pg_tables where schemaname='staging'),20,'Quarantine retains historical tables');
select extensions.ok(not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='staging' and (has_function_privilege('anon',p.oid,'EXECUTE') or has_function_privilege('authenticated',p.oid,'EXECUTE'))),'Staging historical routines uncallable');
select * from extensions.finish();
commit;
