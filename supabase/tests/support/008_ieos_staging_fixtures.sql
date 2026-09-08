-- Synthetic fixtures for the local-only IEOS approval/edit security gate.
-- Run only after staging/001-008 in a disposable Supabase environment.

begin;

create schema ieos_test;
revoke all on schema ieos_test from public;
grant usage on schema ieos_test to authenticated, anon;

create function ieos_test.claim(user_id uuid, role_name text)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(user_id::text, ''), true);
  perform set_config('request.jwt.claim.role', role_name, true);
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', user_id, 'role', role_name)::text,
    true
  );
end;
$$;

create function ieos_test.probe(statement text)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  succeeded boolean := false;
begin
  begin
    execute statement;
    succeeded := true;
    raise exception using errcode = 'PT001';
  exception
    when sqlstate 'PT001' then return succeeded;
    when others then return false;
  end;
end;
$$;

create function ieos_test.execute_ok(statement text)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
begin
  execute statement;
  return true;
exception when others then
  return false;
end;
$$;

create function ieos_test.affected_rows(statement text)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  affected bigint := -1;
begin
  execute statement;
  get diagnostics affected = row_count;
  return affected;
exception when others then
  return -1;
end;
$$;

grant execute on all functions in schema ieos_test to authenticated, anon;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) values (
  '00000000-0000-0000-0000-000000000000',
  '99999999-aaaa-0000-0000-000000000005',
  'authenticated', 'authenticated', 'unauthorised@staging.ieos.test', '', now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false
);

insert into staging.profiles (id, email, full_name) values (
  '99999999-aaaa-0000-0000-000000000005',
  'unauthorised@staging.ieos.test',
  'TEST Unauthorised User'
);

insert into staging.content_items (
  id, business_unit_id, department_id, title, status, user_id
) values
  (
    '88888888-0000-0000-0000-000000000001',
    '99999999-0000-0000-0002-000000000001',
    '99999999-0000-0000-0003-000000000001',
    'TEST — Routine Marketing Item', 'draft',
    '99999999-aaaa-0000-0000-000000000003'
  ),
  (
    '88888888-0000-0000-0000-000000000002',
    '99999999-0000-0000-0002-000000000001',
    '99999999-0000-0000-0003-000000000001',
    'TEST — Escalated Marketing Item', 'draft',
    '99999999-aaaa-0000-0000-000000000003'
  ),
  (
    '88888888-0000-0000-0000-000000000003',
    '99999999-0000-0000-0002-000000000001',
    '99999999-0000-0000-0003-000000000002',
    'TEST — Cross Department Item', 'draft',
    '99999999-aaaa-0000-0000-000000000003'
  ),
  (
    '88888888-0000-0000-0000-000000000004',
    '99999999-0000-0000-0002-000000000001',
    '99999999-0000-0000-0003-000000000001',
    'TEST — Intern Owned Item', 'draft',
    '99999999-aaaa-0000-0000-000000000004'
  ),
  (
    '88888888-0000-0000-0000-000000000005',
    '99999999-0000-0000-0002-000000000001',
    null,
    'TEST — Unscoped Item', 'draft',
    '99999999-aaaa-0000-0000-000000000003'
  );

update staging.content_items
set approval_category_id = (
  select id from staging.approval_categories where name = 'Major Campaign'
)
where id = '88888888-0000-0000-0000-000000000002';

commit;

