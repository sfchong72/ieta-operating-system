-- Rollback for 0003_auth_access_rls.sql.
-- NOT applied automatically. Restores every table to the permissive
-- `using (true)` policies from 0001/0002 and drops the Milestone 2 additions.
-- Does not touch any Sprint 1-6 data, and does not touch auth.users (real
-- logins created during Milestone 2 are left alone; only the app-level
-- profiles/access/RLS layer is reverted).

drop policy if exists "organisations_select" on organisations;
drop policy if exists "organisations_write" on organisations;
create policy "organisations_v1_read" on organisations for select using (true);
create policy "organisations_v1_write" on organisations for all using (true) with check (true);

drop policy if exists "business_units_select" on business_units;
drop policy if exists "business_units_write" on business_units;
create policy "business_units_v1_read" on business_units for select using (true);
create policy "business_units_v1_write" on business_units for all using (true) with check (true);

drop policy if exists "departments_select" on departments;
drop policy if exists "departments_write" on departments;
create policy "departments_v1_read" on departments for select using (true);
create policy "departments_v1_write" on departments for all using (true) with check (true);

drop policy if exists "teams_select" on teams;
drop policy if exists "teams_write" on teams;
create policy "teams_v1_read" on teams for select using (true);
create policy "teams_v1_write" on teams for all using (true) with check (true);

drop policy if exists "sops_select" on sops;
drop policy if exists "sops_insert" on sops;
drop policy if exists "sops_update" on sops;
drop policy if exists "sops_delete" on sops;
create policy "sops_v1_read" on sops for select using (true);
create policy "sops_v1_write" on sops for all using (true) with check (true);

drop policy if exists "content_tasks_select" on content_tasks;
drop policy if exists "content_tasks_insert" on content_tasks;
drop policy if exists "content_tasks_update" on content_tasks;
drop policy if exists "content_tasks_delete" on content_tasks;
create policy "content_tasks_v1_read" on content_tasks for select using (true);
create policy "content_tasks_v1_write" on content_tasks for all using (true) with check (true);

drop policy if exists "work_files_select" on work_files;
drop policy if exists "work_files_insert" on work_files;
create policy "work_files_v1_read" on work_files for select using (true);
create policy "work_files_v1_write" on work_files for all using (true) with check (true);

drop policy if exists "activities_select" on activities;
drop policy if exists "activities_insert" on activities;
create policy "activities_v1_read" on activities for select using (true);
create policy "activities_v1_write" on activities for all using (true) with check (true);

drop policy if exists "content_ideas_all" on content_ideas;
create policy "content_ideas_v1_read" on content_ideas for select using (true);
create policy "content_ideas_v1_write" on content_ideas for all using (true) with check (true);

drop policy if exists "knowledge_items_all" on knowledge_items;
create policy "knowledge_items_v1_read" on knowledge_items for select using (true);
create policy "knowledge_items_v1_write" on knowledge_items for all using (true) with check (true);

drop table if exists user_department_access;
drop table if exists user_business_unit_access;
drop table if exists user_role_assignment;
drop table if exists profiles;

drop function if exists fn_task_department(uuid);
drop function if exists fn_has_department_access(uuid, uuid);
drop function if exists fn_has_business_unit_access(uuid, uuid);
drop function if exists fn_role(uuid);
drop function if exists fn_is_management(uuid);
drop function if exists fn_is_super_admin(uuid);
