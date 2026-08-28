-- STAGING ONLY. See supabase/staging/README.md.
-- Milestone 2 auth + access model, built and validated in `staging` before
-- being re-expressed as a production migration against `public`.

create table staging.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  created_at timestamptz not null default now()
);

create table staging.user_role_assignment (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references staging.profiles(id) on delete cascade,
  role text not null check (role in ('super_admin','management','staff','intern')),
  created_at timestamptz not null default now(),
  unique (profile_id, role)
);

create table staging.user_business_unit_access (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references staging.profiles(id) on delete cascade,
  business_unit_id uuid not null references staging.business_units(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, business_unit_id)
);

create table staging.user_department_access (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references staging.profiles(id) on delete cascade,
  department_id uuid not null references staging.departments(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, department_id)
);

-- ── Helper functions (SECURITY DEFINER so RLS policies can call them without
--    needing their own SELECT-on-profiles/access-table permissions) ─────────

create or replace function staging.fn_is_super_admin(uid uuid)
returns boolean language sql stable security definer set search_path = staging as $$
  select exists (
    select 1 from staging.user_role_assignment
    where profile_id = uid and role = 'super_admin'
  );
$$;

create or replace function staging.fn_is_management(uid uuid)
returns boolean language sql stable security definer set search_path = staging as $$
  select exists (
    select 1 from staging.user_role_assignment
    where profile_id = uid and role = 'management'
  );
$$;

create or replace function staging.fn_role(uid uuid)
returns text language sql stable security definer set search_path = staging as $$
  select role from staging.user_role_assignment where profile_id = uid limit 1;
$$;

create or replace function staging.fn_has_business_unit_access(uid uuid, bu_id uuid)
returns boolean language sql stable security definer set search_path = staging as $$
  select staging.fn_is_super_admin(uid)
    or exists (
      select 1 from staging.user_business_unit_access
      where profile_id = uid and business_unit_id = bu_id
    );
$$;

create or replace function staging.fn_has_department_access(uid uuid, dept_id uuid)
returns boolean language sql stable security definer set search_path = staging as $$
  select staging.fn_is_super_admin(uid)
    or staging.fn_is_management(uid) and exists (
      select 1 from staging.departments d
      where d.id = dept_id
        and staging.fn_has_business_unit_access(uid, d.business_unit_id)
    )
    or exists (
      select 1 from staging.user_department_access
      where profile_id = uid and department_id = dept_id
    );
$$;

-- department_id of a content_task, resolved once for reuse in child-table policies
create or replace function staging.fn_task_department(task_id uuid)
returns uuid language sql stable security definer set search_path = staging as $$
  select department_id from staging.content_tasks where id = task_id;
$$;

-- ── RLS: organisations / business_units — visible to any authenticated user
--    for active BUs; super_admin sees everything including inactive BUs ─────

alter table staging.organisations enable row level security;
create policy "staging_organisations_select" on staging.organisations
  for select using (auth.uid() is not null);
create policy "staging_organisations_write" on staging.organisations
  for all using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));

alter table staging.business_units enable row level security;
create policy "staging_business_units_select" on staging.business_units
  for select using (
    auth.uid() is not null
    and (is_active = true or staging.fn_is_super_admin(auth.uid()))
  );
create policy "staging_business_units_write" on staging.business_units
  for all using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));

-- ── RLS: departments / teams — scoped by business-unit access ───────────────

alter table staging.departments enable row level security;
create policy "staging_departments_select" on staging.departments
  for select using (
    staging.fn_has_business_unit_access(auth.uid(), business_unit_id)
    or staging.fn_has_department_access(auth.uid(), id)
  );
create policy "staging_departments_write" on staging.departments
  for all using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));

alter table staging.teams enable row level security;
create policy "staging_teams_select" on staging.teams
  for select using (staging.fn_has_department_access(auth.uid(), department_id));
create policy "staging_teams_write" on staging.teams
  for all using (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()));

-- ── RLS: sops — department-scoped read; staff+ can write within scope ───────

alter table staging.sops enable row level security;
create policy "staging_sops_select" on staging.sops
  for select using (
    department_id is null or staging.fn_has_department_access(auth.uid(), department_id)
  );
create policy "staging_sops_insert" on staging.sops
  for insert with check (
    staging.fn_role(auth.uid()) in ('super_admin','management','staff')
    and (department_id is null or staging.fn_has_department_access(auth.uid(), department_id))
  );
create policy "staging_sops_update" on staging.sops
  for update using (
    staging.fn_role(auth.uid()) in ('super_admin','management','staff')
    and (department_id is null or staging.fn_has_department_access(auth.uid(), department_id))
  );
create policy "staging_sops_delete" on staging.sops
  for delete using (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()));

-- ── RLS: content_tasks — department-scoped; intern writes limited to own rows

alter table staging.content_tasks enable row level security;
create policy "staging_content_tasks_select" on staging.content_tasks
  for select using (
    department_id is null or staging.fn_has_department_access(auth.uid(), department_id)
  );
create policy "staging_content_tasks_insert" on staging.content_tasks
  for insert with check (
    (department_id is null or staging.fn_has_department_access(auth.uid(), department_id))
    and (staging.fn_role(auth.uid()) != 'intern' or user_id = auth.uid())
  );
create policy "staging_content_tasks_update" on staging.content_tasks
  for update using (
    (department_id is null or staging.fn_has_department_access(auth.uid(), department_id))
    and (staging.fn_role(auth.uid()) not in ('intern') or user_id = auth.uid())
  );
create policy "staging_content_tasks_delete" on staging.content_tasks
  for delete using (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()));

-- ── RLS: work_files / activities — inherit scope from their parent task ────

alter table staging.work_files enable row level security;
create policy "staging_work_files_select" on staging.work_files
  for select using (staging.fn_has_department_access(auth.uid(), staging.fn_task_department(task_id)));
create policy "staging_work_files_insert" on staging.work_files
  for insert with check (staging.fn_has_department_access(auth.uid(), staging.fn_task_department(task_id)));

alter table staging.activities enable row level security;
create policy "staging_activities_select" on staging.activities
  for select using (staging.fn_has_department_access(auth.uid(), staging.fn_task_department(task_id)));
create policy "staging_activities_insert" on staging.activities
  for insert with check (staging.fn_has_department_access(auth.uid(), staging.fn_task_department(task_id)));

-- ── RLS: content_ideas / knowledge_items — NOT department-scoped in the
--    current (Sprint 1-6) schema (no department_id column). Rather than open
--    these to every authenticated user, restrict to Management/Super Admin
--    only as the safest conservative default until Milestone 3 adds real
--    department scoping (Content Item redesign). Staff/Intern get no access
--    to these two tables in the meantime. ───────────────────────────────────

alter table staging.content_ideas enable row level security;
create policy "staging_content_ideas_all" on staging.content_ideas
  for all
  using (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()));

alter table staging.knowledge_items enable row level security;
create policy "staging_knowledge_items_all" on staging.knowledge_items
  for all
  using (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()));

-- ── RLS: profiles / access tables — users see their own profile + access
--    rows; super_admin sees and manages everyone's (Admin Users screen) ─────

alter table staging.profiles enable row level security;
create policy "staging_profiles_select_self" on staging.profiles
  for select using (id = auth.uid() or staging.fn_is_super_admin(auth.uid()));
create policy "staging_profiles_write_admin" on staging.profiles
  for all using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));

alter table staging.user_role_assignment enable row level security;
create policy "staging_role_select_self" on staging.user_role_assignment
  for select using (profile_id = auth.uid() or staging.fn_is_super_admin(auth.uid()));
create policy "staging_role_write_admin" on staging.user_role_assignment
  for all using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));

alter table staging.user_business_unit_access enable row level security;
create policy "staging_bu_access_select_self" on staging.user_business_unit_access
  for select using (profile_id = auth.uid() or staging.fn_is_super_admin(auth.uid()));
create policy "staging_bu_access_write_admin" on staging.user_business_unit_access
  for all using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));

alter table staging.user_department_access enable row level security;
create policy "staging_dept_access_select_self" on staging.user_department_access
  for select using (profile_id = auth.uid() or staging.fn_is_super_admin(auth.uid()));
create policy "staging_dept_access_write_admin" on staging.user_department_access
  for all using (staging.fn_is_super_admin(auth.uid()))
  with check (staging.fn_is_super_admin(auth.uid()));
