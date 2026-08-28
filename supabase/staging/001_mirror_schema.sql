-- STAGING ONLY. See supabase/staging/README.md.
-- Mirrors the structural shape of `public` (Sprint 1-6 + Milestone 1) into a
-- separate `staging` schema, with minimal synthetic test data only.
-- Does not read from or write to `public` in any way.

create schema if not exists staging;

create table staging.organisations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  created_at timestamptz not null default now()
);

create table staging.business_units (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid references staging.organisations(id) on delete cascade,
  name text not null,
  slug text unique,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create table staging.departments (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid references staging.business_units(id),
  name text not null,
  slug text unique,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.teams (
  id uuid primary key default gen_random_uuid(),
  department_id uuid references staging.departments(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table staging.sops (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  department_id uuid references staging.departments(id) on delete set null,
  master_drive_link text,
  version text default 'v1',
  content text,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.content_ideas (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  platform text,
  topic text,
  status text default 'idea',
  suggested_tags text,
  tags_source text,
  tags_confidence numeric,
  tags_review_status text default 'unreviewed',
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.content_tasks (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid references staging.content_ideas(id) on delete set null,
  title text not null,
  department_id uuid references staging.departments(id) on delete set null,
  pic_name text not null,
  platform text,
  deadline date,
  status text not null default 'assigned',
  work_link text,
  approval_status text,
  approval_remarks text,
  posted_url text,
  posted_date date,
  remarks text,
  priority_score numeric,
  priority_source text,
  priority_confidence numeric,
  priority_review_status text default 'unreviewed',
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.work_files (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references staging.content_tasks(id) on delete cascade,
  label text,
  url text not null,
  file_type text,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.knowledge_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,
  body text,
  tags text[],
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.activities (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references staging.content_tasks(id) on delete cascade,
  action text not null,
  actor_name text,
  detail text,
  user_id uuid,
  created_at timestamptz not null default now()
);

-- Minimal synthetic seed: 1 org, 2 business units (to test cross-BU
-- restriction), 3 departments (2 under IETA to test cross-department
-- restriction, 1 under IEA), a handful of dummy content rows per department.

insert into staging.organisations (id, name, slug) values
  ('99999999-0000-0000-0001-000000000001', 'TEST — Inter Excel', 'test-inter-excel');

insert into staging.business_units (id, organisation_id, name, slug, is_active) values
  ('99999999-0000-0000-0002-000000000001', '99999999-0000-0000-0001-000000000001', 'TEST — IETA', 'test-ieta', true),
  ('99999999-0000-0000-0002-000000000002', '99999999-0000-0000-0001-000000000001', 'TEST — IEA', 'test-iea', false);

insert into staging.departments (id, business_unit_id, name, slug) values
  ('99999999-0000-0000-0003-000000000001', '99999999-0000-0000-0002-000000000001', 'TEST — Marketing', 'test-marketing'),
  ('99999999-0000-0000-0003-000000000002', '99999999-0000-0000-0002-000000000001', 'TEST — Design', 'test-design'),
  ('99999999-0000-0000-0003-000000000003', '99999999-0000-0000-0002-000000000002', 'TEST — IEA General', 'test-iea-general');

insert into staging.sops (id, title, department_id, master_drive_link, version) values
  ('99999999-0000-0000-0004-000000000001', 'TEST — Marketing SOP', '99999999-0000-0000-0003-000000000001', 'https://example.test/marketing-sop', 'v1'),
  ('99999999-0000-0000-0004-000000000002', 'TEST — Design SOP', '99999999-0000-0000-0003-000000000002', 'https://example.test/design-sop', 'v1'),
  ('99999999-0000-0000-0004-000000000003', 'TEST — IEA SOP', '99999999-0000-0000-0003-000000000003', 'https://example.test/iea-sop', 'v1');

insert into staging.content_tasks (id, title, department_id, pic_name, platform, status, deadline) values
  ('99999999-0000-0000-0005-000000000001', 'TEST — Marketing task', '99999999-0000-0000-0003-000000000001', 'Test Staff', 'Instagram', 'assigned', current_date + 7),
  ('99999999-0000-0000-0005-000000000002', 'TEST — Design task', '99999999-0000-0000-0003-000000000002', 'Test Staff', 'Instagram', 'assigned', current_date + 7),
  ('99999999-0000-0000-0005-000000000003', 'TEST — IEA task', '99999999-0000-0000-0003-000000000003', 'Test Staff', 'Instagram', 'assigned', current_date + 7);
