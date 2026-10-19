-- Disposable public-schema approval regression fixtures.
insert into public.organisations (id, name, slug) values
  ('99888888-0000-0000-0001-000000000001', 'TEST — Inter Excel', 'public-test-inter-excel');

insert into public.business_units (id, organisation_id, name, slug, is_active) values
  ('99888888-0000-0000-0002-000000000001', '99888888-0000-0000-0001-000000000001', 'TEST — IETA', 'public-test-ieta', true),
  ('99888888-0000-0000-0002-000000000002', '99888888-0000-0000-0001-000000000001', 'TEST — IEA', 'public-test-iea', false);

insert into public.departments (id, business_unit_id, name, slug) values
  ('99888888-0000-0000-0003-000000000001', '99888888-0000-0000-0002-000000000001', 'TEST — Marketing', 'public-test-marketing'),
  ('99888888-0000-0000-0003-000000000002', '99888888-0000-0000-0002-000000000001', 'TEST — Design', 'public-test-design'),
  ('99888888-0000-0000-0003-000000000003', '99888888-0000-0000-0002-000000000002', 'TEST — IEA General', 'public-test-iea-general');

insert into public.sops (id, title, department_id, master_drive_link, version) values
  ('99888888-0000-0000-0004-000000000001', 'TEST — Marketing SOP', '99888888-0000-0000-0003-000000000001', 'https://example.test/marketing-sop', 'v1'),
  ('99888888-0000-0000-0004-000000000002', 'TEST — Design SOP', '99888888-0000-0000-0003-000000000002', 'https://example.test/design-sop', 'v1'),
  ('99888888-0000-0000-0004-000000000003', 'TEST — IEA SOP', '99888888-0000-0000-0003-000000000003', 'https://example.test/iea-sop', 'v1');

insert into public.content_tasks (id, title, department_id, pic_name, platform, status, deadline) values
  ('99888888-0000-0000-0005-000000000001', 'TEST — Marketing task', '99888888-0000-0000-0003-000000000001', 'Test Staff', 'Instagram', 'assigned', current_date + 7),
  ('99888888-0000-0000-0005-000000000002', 'TEST — Design task', '99888888-0000-0000-0003-000000000002', 'Test Staff', 'Instagram', 'assigned', current_date + 7),
  ('99888888-0000-0000-0005-000000000003', 'TEST — IEA task', '99888888-0000-0000-0003-000000000003', 'Test Staff', 'Instagram', 'assigned', current_date + 7);

-- STAGING ONLY. See supabase/staging/README.md.
-- 4 dummy test accounts, one per role. `.test` is an IANA-reserved TLD that
-- cannot receive real mail and cannot collide with any real account.
-- No passwords are set (magic-link only accounts); auth.identities rows are
-- created so the accounts are structurally valid Supabase Auth users.

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) values
  ('00000000-0000-0000-0000-000000000000', '99888888-aaaa-0000-0000-000000000001', 'authenticated', 'authenticated', 'super.admin@public.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '99888888-aaaa-0000-0000-000000000002', 'authenticated', 'authenticated', 'management@public.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '99888888-aaaa-0000-0000-000000000003', 'authenticated', 'authenticated', 'staff@public.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '99888888-aaaa-0000-0000-000000000004', 'authenticated', 'authenticated', 'intern@public.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false);

insert into auth.identities (id, provider_id, user_id, identity_data, provider, created_at, updated_at) values
  (gen_random_uuid(), '99888888-aaaa-0000-0000-000000000001', '99888888-aaaa-0000-0000-000000000001', '{"sub":"99888888-aaaa-0000-0000-000000000001","email":"super.admin@public.ieos.test"}', 'email', now(), now()),
  (gen_random_uuid(), '99888888-aaaa-0000-0000-000000000002', '99888888-aaaa-0000-0000-000000000002', '{"sub":"99888888-aaaa-0000-0000-000000000002","email":"management@public.ieos.test"}', 'email', now(), now()),
  (gen_random_uuid(), '99888888-aaaa-0000-0000-000000000003', '99888888-aaaa-0000-0000-000000000003', '{"sub":"99888888-aaaa-0000-0000-000000000003","email":"staff@public.ieos.test"}', 'email', now(), now()),
  (gen_random_uuid(), '99888888-aaaa-0000-0000-000000000004', '99888888-aaaa-0000-0000-000000000004', '{"sub":"99888888-aaaa-0000-0000-000000000004","email":"intern@public.ieos.test"}', 'email', now(), now());

insert into public.profiles (id, email, full_name) values
  ('99888888-aaaa-0000-0000-000000000001', 'super.admin@public.ieos.test', 'TEST Super Admin (Claire-equivalent)'),
  ('99888888-aaaa-0000-0000-000000000002', 'management@public.ieos.test', 'TEST Management (Hailey-equivalent)'),
  ('99888888-aaaa-0000-0000-000000000003', 'staff@public.ieos.test', 'TEST Staff'),
  ('99888888-aaaa-0000-0000-000000000004', 'intern@public.ieos.test', 'TEST Intern');

insert into public.user_role_assignment (profile_id, role) values
  ('99888888-aaaa-0000-0000-000000000001', 'super_admin'),
  ('99888888-aaaa-0000-0000-000000000002', 'management'),
  ('99888888-aaaa-0000-0000-000000000003', 'staff'),
  ('99888888-aaaa-0000-0000-000000000004', 'intern');

-- Management: access to TEST IETA business unit only (not TEST IEA) — tests
-- cross-business-unit restriction.
insert into public.user_business_unit_access (profile_id, business_unit_id) values
  ('99888888-aaaa-0000-0000-000000000002', '99888888-0000-0000-0002-000000000001');

-- Staff + Intern: access to TEST Marketing department only (not TEST Design,
-- not TEST IEA General) — tests cross-department restriction.
insert into public.user_department_access (profile_id, department_id) values
  ('99888888-aaaa-0000-0000-000000000003', '99888888-0000-0000-0003-000000000001'),
  ('99888888-aaaa-0000-0000-000000000004', '99888888-0000-0000-0003-000000000001');

-- Synthetic fixtures for the local-only IEOS approval/edit security gate.
-- Run only after staging/001-008 in a disposable Supabase environment.

begin;

create schema ieos_public_test;
revoke all on schema ieos_public_test from public;
grant usage on schema ieos_public_test to authenticated, anon;

create function ieos_public_test.claim(user_id uuid, role_name text)
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

create function ieos_public_test.probe(statement text)
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

create function ieos_public_test.execute_ok(statement text)
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

create function ieos_public_test.affected_rows(statement text)
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

grant execute on all functions in schema ieos_public_test to authenticated, anon;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) values (
  '00000000-0000-0000-0000-000000000000',
  '99888888-aaaa-0000-0000-000000000005',
  'authenticated', 'authenticated', 'unauthorised@public.ieos.test', '', now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false
);

insert into public.profiles (id, email, full_name) values (
  '99888888-aaaa-0000-0000-000000000005',
  'unauthorised@public.ieos.test',
  'TEST Unauthorised User'
);

insert into public.content_items (
  id, business_unit_id, department_id, title, status, user_id
) values
  (
    '88888888-0000-0000-0000-000000000001',
    '99888888-0000-0000-0002-000000000001',
    '99888888-0000-0000-0003-000000000001',
    'TEST — Routine Marketing Item', 'draft',
    '99888888-aaaa-0000-0000-000000000003'
  ),
  (
    '88888888-0000-0000-0000-000000000002',
    '99888888-0000-0000-0002-000000000001',
    '99888888-0000-0000-0003-000000000001',
    'TEST — Escalated Marketing Item', 'draft',
    '99888888-aaaa-0000-0000-000000000003'
  ),
  (
    '88888888-0000-0000-0000-000000000003',
    '99888888-0000-0000-0002-000000000001',
    '99888888-0000-0000-0003-000000000002',
    'TEST — Cross Department Item', 'draft',
    '99888888-aaaa-0000-0000-000000000003'
  ),
  (
    '88888888-0000-0000-0000-000000000004',
    '99888888-0000-0000-0002-000000000001',
    '99888888-0000-0000-0003-000000000001',
    'TEST — Intern Owned Item', 'draft',
    '99888888-aaaa-0000-0000-000000000004'
  ),
  (
    '88888888-0000-0000-0000-000000000005',
    '99888888-0000-0000-0002-000000000001',
    null,
    'TEST — Unscoped Item', 'draft',
    '99888888-aaaa-0000-0000-000000000003'
  );

update public.content_items
set approval_category_id = (
  select id from public.approval_categories where name = 'Major Campaign'
)
where id = '88888888-0000-0000-0000-000000000002';

commit;

