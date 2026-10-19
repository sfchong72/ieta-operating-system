
-- DISPOSABLE MODEL ONLY. No hosted connection or production data.
-- Local historical definitions reduced to recorded hosted metadata.
create extension if not exists pgtap with schema extensions;
do $$ declare x record; begin
 if current_database()<>'p0_hosted_adoption' then raise exception 'Wrong model database'; end if;
 for x in select n.nspname,c.relname,t.tgname from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','staging') and not t.tgisinternal loop
 execute format('drop trigger %I on %I.%I',x.tgname,x.nspname,x.relname); end loop;
 for x in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='staging' and p.proname not in ('fn_role','fn_is_super_admin','fn_is_management','fn_has_business_unit_access','fn_has_department_access','fn_task_department') loop execute format('drop function %s',x.signature); end loop;
end $$;
insert into public.profiles(id,email,full_name) select id,email,'SYNTHETIC MODEL '||right(id::text,1) from auth.users where id in ('71000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000002');
insert into public.user_role_assignment(profile_id,role) values('71000000-0000-0000-0000-000000000001','super_admin'),('71000000-0000-0000-0000-000000000002','management');
insert into staging.profiles(id,email,full_name) select id,email,'SYNTHETIC STAGING '||right(id::text,1) from auth.users where id::text like '71000000-%' and right(id::text,1) between '1' and '6';
insert into staging.user_role_assignment(profile_id,role) values('71000000-0000-0000-0000-000000000001','super_admin'),('71000000-0000-0000-0000-000000000002','management');
create schema supabase_migrations;
create table supabase_migrations.schema_migrations(version text primary key,statements text[],name text);
insert into supabase_migrations.schema_migrations(version,name) values('20260817144740','org_business_unit_team'),('20260828004042','auth_access_rls'),('20260828044543','content_core');
grant all privileges on all tables in schema public,staging to anon,authenticated;
grant select(id),references(id) on public.knowledge_items to anon,authenticated;
grant all privileges on all sequences in schema public,staging to anon,authenticated;
grant usage on schema public,staging to anon,authenticated;
grant execute on all functions in schema public,staging to anon,authenticated;
-- Preserve original columns, including Auth, despite additive P0 columns.
create table ieos_stage1_test.p0_original_columns(schema_name text,table_name text,column_names text[],digest text,primary key(schema_name,table_name));
insert into ieos_stage1_test.p0_original_columns(schema_name,table_name,column_names) select table_schema,table_name,array_agg(column_name::text order by ordinal_position) from information_schema.columns where table_schema in ('public','staging','auth') group by table_schema,table_name;
create function ieos_stage1_test.p0_original_digest(schema_name text,table_name text,column_names text[]) returns text language plpgsql security invoker set search_path='' as $$ declare answer text; begin execute format('select md5(coalesce(string_agg((select jsonb_object_agg(k,to_jsonb(r)->k) from unnest($1) k)::text,chr(10) order by (select jsonb_object_agg(k,to_jsonb(r)->k) from unnest($1) k)::text),'''')) from %I.%I r',schema_name,table_name) using column_names into answer; return answer; end $$;
update ieos_stage1_test.p0_original_columns s set digest=ieos_stage1_test.p0_original_digest(s.schema_name,s.table_name,s.column_names);
select extensions.plan(7);
select extensions.is((select count(*)::integer from pg_tables where schemaname='public'),17,'Model public table count matches hosted metadata');
select extensions.is((select count(*)::integer from pg_tables where schemaname='staging'),20,'Model staging table count matches hosted metadata');
select extensions.ok(not exists(select 1 from information_schema.columns where table_schema in ('public','staging') and table_name='profiles' and column_name='is_active'),'Model has no pre-P0 activity column');
select extensions.ok(not exists(select 1 from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','staging') and not t.tgisinternal),'Model has no hosted workflow triggers');
select extensions.is((select count(*)::integer from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','staging')),12,'Model has twelve legacy helpers');
select extensions.is((select count(*)::integer from supabase_migrations.schema_migrations),3,'Model has exact three hosted ledger versions');
select extensions.ok(has_table_privilege('anon','public.knowledge_items','TRUNCATE') and has_table_privilege('authenticated','public.knowledge_items','TRIGGER') and has_any_column_privilege('anon','public.knowledge_items','REFERENCES'),'Model reproduces legacy excess grants');
select * from extensions.finish();
