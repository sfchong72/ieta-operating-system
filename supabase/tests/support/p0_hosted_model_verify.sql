
-- Disposable adoption assertions; never queries production records.
begin;
select extensions.plan(9);
select extensions.ok(not exists(select 1 from ieos_stage1_test.p0_original_columns s where s.digest<>ieos_stage1_test.p0_original_digest(s.schema_name,s.table_name,s.column_names)),'Every original public/staging/Auth row and column preserved');
select extensions.is((select count(*)::integer from pg_tables where schemaname='public'),46,'Incremental adoption adds 29 missing public tables');
select extensions.is((select count(*)::integer from pg_tables where schemaname='staging'),20,'Historical staging tables retained without replay');
select extensions.is((select count(*)::integer from supabase_migrations.schema_migrations where version in ('20260817144740','20260828004042','20260828044543')),3,'All original hosted ledger versions retained');
select extensions.is((select count(*)::integer from supabase_migrations.schema_migrations),12,'Only nine incremental model ledger entries appended');
select extensions.is((select count(*)::integer from public.business_units where is_active),1,'Only IETA active after adoption');
select extensions.ok(not has_table_privilege('anon','public.knowledge_items','SELECT,TRUNCATE,REFERENCES,TRIGGER') and not has_table_privilege('authenticated','public.knowledge_items','TRUNCATE,REFERENCES,TRIGGER'),'Historical broad grants removed');
select extensions.ok(not has_function_privilege('anon','public.fn_role(uuid)','EXECUTE'),'Historical anonymous function grant removed');
select extensions.ok(not has_any_column_privilege('anon','public.knowledge_items','SELECT,REFERENCES') and not has_any_column_privilege('authenticated','public.knowledge_items','REFERENCES'),'Historical column grants removed');
select * from extensions.finish();
rollback;
