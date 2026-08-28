-- STAGING ONLY. See supabase/staging/README.md.
-- 4 dummy test accounts, one per role. `.test` is an IANA-reserved TLD that
-- cannot receive real mail and cannot collide with any real account.
-- No passwords are set (magic-link only accounts); auth.identities rows are
-- created so the accounts are structurally valid Supabase Auth users.

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) values
  ('00000000-0000-0000-0000-000000000000', '99999999-aaaa-0000-0000-000000000001', 'authenticated', 'authenticated', 'super.admin@staging.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '99999999-aaaa-0000-0000-000000000002', 'authenticated', 'authenticated', 'management@staging.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '99999999-aaaa-0000-0000-000000000003', 'authenticated', 'authenticated', 'staff@staging.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '99999999-aaaa-0000-0000-000000000004', 'authenticated', 'authenticated', 'intern@staging.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false);

insert into auth.identities (id, provider_id, user_id, identity_data, provider, created_at, updated_at) values
  (gen_random_uuid(), '99999999-aaaa-0000-0000-000000000001', '99999999-aaaa-0000-0000-000000000001', '{"sub":"99999999-aaaa-0000-0000-000000000001","email":"super.admin@staging.ieos.test"}', 'email', now(), now()),
  (gen_random_uuid(), '99999999-aaaa-0000-0000-000000000002', '99999999-aaaa-0000-0000-000000000002', '{"sub":"99999999-aaaa-0000-0000-000000000002","email":"management@staging.ieos.test"}', 'email', now(), now()),
  (gen_random_uuid(), '99999999-aaaa-0000-0000-000000000003', '99999999-aaaa-0000-0000-000000000003', '{"sub":"99999999-aaaa-0000-0000-000000000003","email":"staff@staging.ieos.test"}', 'email', now(), now()),
  (gen_random_uuid(), '99999999-aaaa-0000-0000-000000000004', '99999999-aaaa-0000-0000-000000000004', '{"sub":"99999999-aaaa-0000-0000-000000000004","email":"intern@staging.ieos.test"}', 'email', now(), now());

insert into staging.profiles (id, email, full_name) values
  ('99999999-aaaa-0000-0000-000000000001', 'super.admin@staging.ieos.test', 'TEST Super Admin (Claire-equivalent)'),
  ('99999999-aaaa-0000-0000-000000000002', 'management@staging.ieos.test', 'TEST Management (Hailey-equivalent)'),
  ('99999999-aaaa-0000-0000-000000000003', 'staff@staging.ieos.test', 'TEST Staff'),
  ('99999999-aaaa-0000-0000-000000000004', 'intern@staging.ieos.test', 'TEST Intern');

insert into staging.user_role_assignment (profile_id, role) values
  ('99999999-aaaa-0000-0000-000000000001', 'super_admin'),
  ('99999999-aaaa-0000-0000-000000000002', 'management'),
  ('99999999-aaaa-0000-0000-000000000003', 'staff'),
  ('99999999-aaaa-0000-0000-000000000004', 'intern');

-- Management: access to TEST IETA business unit only (not TEST IEA) — tests
-- cross-business-unit restriction.
insert into staging.user_business_unit_access (profile_id, business_unit_id) values
  ('99999999-aaaa-0000-0000-000000000002', '99999999-0000-0000-0002-000000000001');

-- Staff + Intern: access to TEST Marketing department only (not TEST Design,
-- not TEST IEA General) — tests cross-department restriction.
insert into staging.user_department_access (profile_id, department_id) values
  ('99999999-aaaa-0000-0000-000000000003', '99999999-0000-0000-0003-000000000001'),
  ('99999999-aaaa-0000-0000-000000000004', '99999999-0000-0000-0003-000000000001');
