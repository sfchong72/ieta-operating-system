-- Read-only checksum of every application/auth table. Helper exists only in this psql session.
create function pg_temp.p0_database_fingerprint() returns text
language plpgsql security invoker set search_path='' as $$
declare t record; row_hash text; table_hashes text := '';
begin
  for t in select schemaname,tablename from pg_catalog.pg_tables
    where schemaname in ('public','staging','auth','extensions')
    order by schemaname,tablename
  loop
    execute format('select md5(coalesce(string_agg(to_jsonb(r)::text,chr(10) order by to_jsonb(r)::text),'''')) from %I.%I r',t.schemaname,t.tablename) into row_hash;
    table_hashes := table_hashes || t.schemaname || '.' || t.tablename || ':' || row_hash || E'\n';
  end loop;
  return md5(table_hashes);
end;
$$;
select pg_temp.p0_database_fingerprint();
