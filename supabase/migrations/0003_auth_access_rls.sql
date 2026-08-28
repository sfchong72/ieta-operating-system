-- IEOS Milestone 2: Auth + access model + real RLS on `public`.
-- NOT YET APPLIED — prepared from the validated `staging` schema design for
-- review. Do not run against production until explicitly approved.
--
-- Additive: adds profiles/user_role_assignment/user_business_unit_access/
-- user_department_access and helper functions, then REPLACES every existing
-- `using (true)` permissive policy from 0001/0002 with real access-scoped
-- policies. This is the one non-additive step in the whole IEOS build so
-- far — it changes *behavior* (production RLS enforcement turns on), even
-- though it adds no destructive schema changes (no table/column dropped).
--
-- IMPORTANT — sequencing before this is safe to apply:
--   1. Every real user (Claire, Hailey, and anyone else who needs access on
--      day one) must have a `profiles` + `user_role_assignment` row BEFORE
--      this migration flips RLS from permissive to scoped, or they will be
--      locked out immediately. See the production cutover steps in the
--      Milestone 2 report for the exact order.
--   2. This migration does not touch `content_ideas` or `knowledge_items`
--      RLS beyond "any authenticated user" — those two tables have no
--      department_id column yet (see the note in the report), so true
--      department-scoping for them is Milestone 3 work.

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  created_at timestamptz not null default now()
);

create table user_role_assignment (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  role text not null check (role in ('super_admin','management','staff','intern')),
  created_at timestamptz not null default now(),
  unique (profile_id, role)
);

create table user_business_unit_access (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  business_unit_id uuid not null references business_units(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, business_unit_id)
);

create table user_department_access (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  department_id uuid not null references departments(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, department_id)
);

create or replace function fn_is_super_admin(uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from user_role_assignment where profile_id = uid and role = 'super_admin');
$$;

create or replace function fn_is_management(uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from user_role_assignment where profile_id = uid and role = 'management');
$$;

create or replace function fn_role(uid uuid)
returns text language sql stable security definer set search_path = public as $$
  select role from user_role_assignment where profile_id = uid limit 1;
$$;

create or replace function fn_has_business_unit_access(uid uuid, bu_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select fn_is_super_admin(uid)
    or exists (select 1 from user_business_unit_access where profile_id = uid and business_unit_id = bu_id);
$$;

create or replace function fn_has_department_access(uid uuid, dept_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select fn_is_super_admin(uid)
    or fn_is_management(uid) and exists (
      select 1 from departments d
      where d.id = dept_id and fn_has_business_unit_access(uid, d.business_unit_id)
    )
    or exists (select 1 from user_department_access where profile_id = uid and department_id = dept_id);
$$;

create or replace function fn_task_department(task_id uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select department_id from content_tasks where id = task_id;
$$;

-- ── Replace permissive policies with scoped ones ────────────────────────────

drop policy if exists "organisations_v1_read" on organisations;
drop policy if exists "organisations_v1_write" on organisations;
create policy "organisations_select" on organisations for select using (auth.uid() is not null);
create policy "organisations_write" on organisations for all
  using (fn_is_super_admin(auth.uid())) with check (fn_is_super_admin(auth.uid()));

drop policy if exists "business_units_v1_read" on business_units;
drop policy if exists "business_units_v1_write" on business_units;
create policy "business_units_select" on business_units for select
  using (auth.uid() is not null and (is_active = true or fn_is_super_admin(auth.uid())));
create policy "business_units_write" on business_units for all
  using (fn_is_super_admin(auth.uid())) with check (fn_is_super_admin(auth.uid()));

drop policy if exists "departments_v1_read" on departments;
drop policy if exists "departments_v1_write" on departments;
create policy "departments_select" on departments for select
  using (fn_has_business_unit_access(auth.uid(), business_unit_id) or fn_has_department_access(auth.uid(), id));
create policy "departments_write" on departments for all
  using (fn_is_super_admin(auth.uid())) with check (fn_is_super_admin(auth.uid()));

drop policy if exists "teams_v1_read" on teams;
drop policy if exists "teams_v1_write" on teams;
alter table teams enable row level security;
create policy "teams_select" on teams for select using (fn_has_department_access(auth.uid(), department_id));
create policy "teams_write" on teams for all
  using (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()))
  with check (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()));

drop policy if exists "sops_v1_read" on sops;
drop policy if exists "sops_v1_write" on sops;
create policy "sops_select" on sops for select
  using (department_id is null or fn_has_department_access(auth.uid(), department_id));
create policy "sops_insert" on sops for insert
  with check (
    fn_role(auth.uid()) in ('super_admin','management','staff')
    and (department_id is null or fn_has_department_access(auth.uid(), department_id))
  );
create policy "sops_update" on sops for update
  using (
    fn_role(auth.uid()) in ('super_admin','management','staff')
    and (department_id is null or fn_has_department_access(auth.uid(), department_id))
  );
create policy "sops_delete" on sops for delete
  using (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()));

drop policy if exists "content_tasks_v1_read" on content_tasks;
drop policy if exists "content_tasks_v1_write" on content_tasks;
create policy "content_tasks_select" on content_tasks for select
  using (department_id is null or fn_has_department_access(auth.uid(), department_id));
create policy "content_tasks_insert" on content_tasks for insert
  with check (
    (department_id is null or fn_has_department_access(auth.uid(), department_id))
    and (fn_role(auth.uid()) != 'intern' or user_id = auth.uid())
  );
create policy "content_tasks_update" on content_tasks for update
  using (
    (department_id is null or fn_has_department_access(auth.uid(), department_id))
    and (fn_role(auth.uid()) not in ('intern') or user_id = auth.uid())
  );
create policy "content_tasks_delete" on content_tasks for delete
  using (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()));

drop policy if exists "work_files_v1_read" on work_files;
drop policy if exists "work_files_v1_write" on work_files;
create policy "work_files_select" on work_files for select
  using (fn_has_department_access(auth.uid(), fn_task_department(task_id)));
create policy "work_files_insert" on work_files for insert
  with check (fn_has_department_access(auth.uid(), fn_task_department(task_id)));

drop policy if exists "activities_v1_read" on activities;
drop policy if exists "activities_v1_write" on activities;
create policy "activities_select" on activities for select
  using (fn_has_department_access(auth.uid(), fn_task_department(task_id)));
create policy "activities_insert" on activities for insert
  with check (fn_has_department_access(auth.uid(), fn_task_department(task_id)));

-- content_ideas / knowledge_items: no department_id column yet (Milestone 3
-- work). Conservative default: Management/Super Admin only, no Staff/Intern
-- access until real department scoping lands.
drop policy if exists "content_ideas_v1_read" on content_ideas;
drop policy if exists "content_ideas_v1_write" on content_ideas;
create policy "content_ideas_all" on content_ideas for all
  using (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()))
  with check (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()));

drop policy if exists "knowledge_items_v1_read" on knowledge_items;
drop policy if exists "knowledge_items_v1_write" on knowledge_items;
create policy "knowledge_items_all" on knowledge_items for all
  using (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()))
  with check (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()));

-- profiles / access tables
alter table profiles enable row level security;
create policy "profiles_select_self" on profiles for select
  using (id = auth.uid() or fn_is_super_admin(auth.uid()));
create policy "profiles_write_admin" on profiles for all
  using (fn_is_super_admin(auth.uid())) with check (fn_is_super_admin(auth.uid()));

alter table user_role_assignment enable row level security;
create policy "role_select_self" on user_role_assignment for select
  using (profile_id = auth.uid() or fn_is_super_admin(auth.uid()));
create policy "role_write_admin" on user_role_assignment for all
  using (fn_is_super_admin(auth.uid())) with check (fn_is_super_admin(auth.uid()));

alter table user_business_unit_access enable row level security;
create policy "bu_access_select_self" on user_business_unit_access for select
  using (profile_id = auth.uid() or fn_is_super_admin(auth.uid()));
create policy "bu_access_write_admin" on user_business_unit_access for all
  using (fn_is_super_admin(auth.uid())) with check (fn_is_super_admin(auth.uid()));

alter table user_department_access enable row level security;
create policy "dept_access_select_self" on user_department_access for select
  using (profile_id = auth.uid() or fn_is_super_admin(auth.uid()));
create policy "dept_access_write_admin" on user_department_access for all
  using (fn_is_super_admin(auth.uid())) with check (fn_is_super_admin(auth.uid()));
