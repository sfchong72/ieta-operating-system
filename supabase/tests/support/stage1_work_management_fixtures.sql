-- Synthetic fixtures for the local-only IEOS Stage 1 work-management gate.
-- Run only after public migrations 0001-0004 and work_management_foundation.

begin;

create schema ieos_stage1_test;
revoke all on schema ieos_stage1_test from public;
grant usage on schema ieos_stage1_test to authenticated, anon;

create function ieos_stage1_test.claim(user_id uuid, role_name text)
returns void language plpgsql security invoker set search_path = '' as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(user_id::text, ''), true);
  perform set_config('request.jwt.claim.role', role_name, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', user_id, 'role', role_name)::text, true);
end;
$$;

create function ieos_stage1_test.probe(statement text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare succeeded boolean := false;
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

create function ieos_stage1_test.execute_ok(statement text)
returns boolean language plpgsql security invoker set search_path = '' as $$
begin
  execute statement;
  return true;
exception when others then return false;
end;
$$;

create function ieos_stage1_test.affected_rows(statement text)
returns bigint language plpgsql security invoker set search_path = '' as $$
declare affected bigint := -1;
begin
  execute statement;
  get diagnostics affected = row_count;
  return affected;
exception when others then return -1;
end;
$$;

grant execute on all functions in schema ieos_stage1_test to authenticated, anon;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) values
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'director@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'manager@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'staff@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'intern@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'unassigned@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated', 'inactive@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000007', 'authenticated', 'authenticated', 'design.staff@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '71000000-0000-0000-0000-000000000008', 'authenticated', 'authenticated', 'iea.staff@stage1.ieos.test', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), false, false);

update auth.users
set encrypted_password = extensions.crypt('IEOS-Stage1-UAT-Only!', extensions.gen_salt('bf')),
    confirmation_token = coalesce(confirmation_token, ''),
    recovery_token = coalesce(recovery_token, ''),
    email_change_token_new = coalesce(email_change_token_new, ''),
    email_change = coalesce(email_change, ''),
    phone_change = coalesce(phone_change, ''),
    phone_change_token = coalesce(phone_change_token, ''),
    email_change_token_current = coalesce(email_change_token_current, ''),
    reauthentication_token = coalesce(reauthentication_token, '')
where email in (
  'director@stage1.ieos.test',
  'manager@stage1.ieos.test',
  'intern@stage1.ieos.test',
  'staff@stage1.ieos.test',
  'inactive@stage1.ieos.test'
);

insert into auth.identities (
  id, user_id, provider_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
)
select
  u.id,
  u.id,
  u.id::text,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  now(),
  now(),
  now()
from auth.users u
where u.email in (
  'director@stage1.ieos.test',
  'manager@stage1.ieos.test',
  'intern@stage1.ieos.test',
  'staff@stage1.ieos.test',
  'inactive@stage1.ieos.test'
)
on conflict do nothing;

insert into public.profiles (id, email, full_name, is_active) values
  ('71000000-0000-0000-0000-000000000001', 'director@stage1.ieos.test', 'TEST Director', true),
  ('71000000-0000-0000-0000-000000000002', 'manager@stage1.ieos.test', 'TEST Manager', true),
  ('71000000-0000-0000-0000-000000000003', 'staff@stage1.ieos.test', 'TEST Staff', true),
  ('71000000-0000-0000-0000-000000000004', 'intern@stage1.ieos.test', 'TEST Intern', true),
  ('71000000-0000-0000-0000-000000000005', 'unassigned@stage1.ieos.test', 'TEST Unassigned', true),
  ('71000000-0000-0000-0000-000000000006', 'inactive@stage1.ieos.test', 'TEST Inactive', false),
  ('71000000-0000-0000-0000-000000000007', 'design.staff@stage1.ieos.test', 'TEST Design Staff', true),
  ('71000000-0000-0000-0000-000000000008', 'iea.staff@stage1.ieos.test', 'TEST IEA Staff', true);

insert into public.user_role_assignment (profile_id, role) values
  ('71000000-0000-0000-0000-000000000001', 'super_admin'),
  ('71000000-0000-0000-0000-000000000002', 'management'),
  ('71000000-0000-0000-0000-000000000003', 'staff'),
  ('71000000-0000-0000-0000-000000000004', 'intern'),
  ('71000000-0000-0000-0000-000000000005', 'staff'),
  ('71000000-0000-0000-0000-000000000006', 'intern'),
  ('71000000-0000-0000-0000-000000000007', 'staff'),
  ('71000000-0000-0000-0000-000000000008', 'staff');

insert into public.departments (id, business_unit_id, name, slug) values
  ('a1000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000002', 'TEST IEA Operations', 'test-iea-operations');

insert into public.user_business_unit_access (profile_id, business_unit_id) values
  ('71000000-0000-0000-0000-000000000002', '00000000-0000-0000-0002-000000000001');

insert into public.user_department_access (profile_id, department_id) values
  ('71000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001'),
  ('71000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001'),
  ('71000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000001'),
  ('71000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000002'),
  ('71000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000001');

insert into public.work_tasks (
  id, task_number, business_unit_id, department_id, assigned_to, assigned_by, created_by,
  title, instructions, expected_final_output, output_required, priority, status,
  progress_percent, current_blocker, task_sensitivity, due_date
) values
  ('72000000-0000-0000-0000-000000000001', 'TASK-TEST-001', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000002', 'TEST Intern task', 'Prepare the assigned operational artwork.', 'Final artwork link', true, 'medium', 'not_started', 0, null, 'operational', current_date + 5),
  ('72000000-0000-0000-0000-000000000002', 'TASK-TEST-002', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000002', 'TEST Design task', 'Prepare a design asset.', 'Final design link', true, 'high', 'in_progress', 40, null, 'operational', current_date + 4),
  ('72000000-0000-0000-0000-000000000003', 'TASK-TEST-003', '00000000-0000-0000-0002-000000000002', 'a1000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000008', '71000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000001', 'TEST Cross-BU task', 'Prepare an IEA operational note.', 'Reference link', true, 'low', 'in_progress', 20, null, 'operational', current_date + 7),
  ('72000000-0000-0000-0000-000000000004', 'TASK-TEST-004', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000002', 'TEST Management-only task', 'Prepare a management-only output.', 'Management reference', true, 'high', 'in_progress', 10, null, 'management_only', current_date + 2),
  ('72000000-0000-0000-0000-000000000005', 'TASK-TEST-005', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000003', '71000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000002', 'TEST Full-time-only task', 'Prepare a staff-only output.', 'Staff reference', true, 'medium', 'in_progress', 30, null, 'full_time_only', current_date + 6),
  ('72000000-0000-0000-0000-000000000006', 'TASK-TEST-006', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000002', 'TEST No-output task', 'Complete a task that creates no file.', null, false, 'low', 'in_progress', 80, null, 'operational', current_date + 1),
  ('72000000-0000-0000-0000-000000000007', 'TASK-TEST-007', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000002', 'TEST Attention task', 'Resolve this overdue blocked task.', 'Evidence link', true, 'urgent', 'blocked', 50, 'Waiting for approved source material', 'operational', current_date - 2),
  ('72000000-0000-0000-0000-000000000008', 'TASK-TEST-008', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000003', '71000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000001', 'TEST P&C task', 'Use only the restricted reference ID.', 'Restricted evidence link', true, 'high', 'in_progress', 5, null, 'pc_restricted', current_date + 10),
  ('72000000-0000-0000-0000-000000000009', 'TASK-TEST-009', '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000002', '71000000-0000-0000-0000-000000000002', 'TEST Waiting feedback', 'Wait for supervisor feedback.', 'Final link', true, 'medium', 'waiting_feedback', 70, null, 'operational', current_date + 1);

insert into public.work_task_artifacts (
  id, task_id, added_by, artifact_type, artifact_sensitivity, label, url
) values
  ('73000000-0000-0000-0000-000000000001', '72000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000002', 'reference', 'full_time_only', 'Staff-only reference', 'https://example.test/staff-reference'),
  ('73000000-0000-0000-0000-000000000002', '72000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000001', 'reference', 'pc_restricted', 'P&C reference', 'https://example.test/restricted-reference');

-- Three distinct weekdays count; the duplicate weekday and weekend do not.
insert into public.work_task_events (task_id, actor_id, event_type, metadata, counts_as_activity, created_at) values
  ('72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', 'quick_updated', '{}', true, '2026-09-01 09:00:00+08'),
  ('72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', 'quick_updated', '{}', true, '2026-09-02 09:00:00+08'),
  ('72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', 'quick_updated', '{}', true, '2026-09-03 09:00:00+08'),
  ('72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', 'quick_updated', '{}', true, '2026-09-03 15:00:00+08'),
  ('72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', 'quick_updated', '{}', true, '2026-09-05 09:00:00+08');

-- Simulate one legacy/import anomaly solely to verify detection.
alter table public.work_tasks disable trigger guard_work_task_completion;
insert into public.work_tasks (
  id, task_number, business_unit_id, department_id, assigned_to, assigned_by, created_by,
  title, instructions, expected_final_output, output_required, priority, status,
  progress_percent, completed_at, task_sensitivity
) values (
  '72000000-0000-0000-0000-000000000010', 'TASK-TEST-010',
  '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
  '71000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000002',
  '71000000-0000-0000-0000-000000000002', 'TEST Legacy missing evidence',
  'Synthetic legacy anomaly.', 'Required evidence', true, 'medium', 'completed', 100, now(), 'operational'
);
alter table public.work_tasks enable trigger guard_work_task_completion;

commit;
