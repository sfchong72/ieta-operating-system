-- IEOS Milestone 1: Organisation -> Business Unit -> Department -> Team foundation.
-- Additive only. Does not modify, rename, or drop any Sprint 1-6 table, column, or row.
-- The only existing-table change is a new nullable column on `departments`.

create table if not exists organisations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  created_at timestamptz not null default now()
);

create table if not exists business_units (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid references organisations(id) on delete cascade,
  name text not null,
  slug text unique,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  department_id uuid references departments(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

-- Link existing departments to a business unit. Nullable so existing rows remain
-- valid before the backfill below runs, and so this column add can never fail
-- or lose data even if run out of order.
alter table departments add column if not exists business_unit_id uuid references business_units(id);

-- RLS: enabled on every new table, permissive for now (matches the existing
-- Phase-1 demo-first pattern). Real auth-scoped policies land in Milestone 2
-- once Supabase Auth + user_business_unit_access/user_department_access exist.
alter table organisations enable row level security;
drop policy if exists "organisations_v1_read" on organisations;
create policy "organisations_v1_read" on organisations for select using (true);
drop policy if exists "organisations_v1_write" on organisations;
create policy "organisations_v1_write" on organisations for all using (true) with check (true);

alter table business_units enable row level security;
drop policy if exists "business_units_v1_read" on business_units;
create policy "business_units_v1_read" on business_units for select using (true);
drop policy if exists "business_units_v1_write" on business_units;
create policy "business_units_v1_write" on business_units for all using (true) with check (true);

alter table teams enable row level security;
drop policy if exists "teams_v1_read" on teams;
create policy "teams_v1_read" on teams for select using (true);
drop policy if exists "teams_v1_write" on teams;
create policy "teams_v1_write" on teams for all using (true) with check (true);

-- Seed: one organisation, four business units. Only IETA is active in Phase 1
-- (IEA/PLC/KALER exist as inactive rows so nothing needs restructuring later).
insert into organisations (id, name, slug) values
  ('00000000-0000-0000-0001-000000000001', 'Inter Excel', 'inter-excel')
on conflict do nothing;

insert into business_units (id, organisation_id, name, slug, is_active) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'IETA', 'ieta', true),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'IEA', 'iea', false),
  ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0001-000000000001', 'PLC', 'plc', false),
  ('00000000-0000-0000-0002-000000000004', '00000000-0000-0000-0001-000000000001', 'KALER', 'kaler', false)
on conflict do nothing;

-- Backfill: the 4 existing departments (Marketing, Design, Video, Operations)
-- all belong to IETA, the only active business unit in Phase 1.
update departments
set business_unit_id = '00000000-0000-0000-0002-000000000001'
where business_unit_id is null;
