-- Synthetic fixtures for the local-only IEOS Stage 3 dashboard gate.
-- Run after Stage 1 and Stage 2 fixtures.
begin;

insert into public.work_dashboard_access_grants (profile_id, granted_by) values
  ('71000000-0000-0000-0000-000000000003', '71000000-0000-0000-0000-000000000001'),
  ('71000000-0000-0000-0000-000000000006', '71000000-0000-0000-0000-000000000001');

-- Establish deterministic activity ages without changing the Stage 1 fixture.
alter table public.work_tasks disable trigger touch_work_task;
update public.work_tasks
set status_changed_at = timezone('Asia/Kuala_Lumpur', now()) - interval '4 days',
    project_reference = 'Stage 3 Campaign'
where id in (
  '72000000-0000-0000-0000-000000000002',
  '72000000-0000-0000-0000-000000000007'
);
update public.work_tasks
set status_changed_at = timezone('Asia/Kuala_Lumpur', now()) - interval '5 days'
where id = '72000000-0000-0000-0000-000000000009';
update public.work_tasks
set status_changed_at = timezone('Asia/Kuala_Lumpur', now()) - interval '4 days'
where id = '72000000-0000-0000-0000-000000000005';
alter table public.work_tasks enable trigger touch_work_task;

insert into public.daily_work_updates (
  id, task_id, staff_id, work_date, what_done_today, quantity,
  result_or_output, deliverable_completed, artifact_id, blocker_or_help, created_at
) values
  (
    '75000000-0000-0000-0000-000000000001',
    '72000000-0000-0000-0000-000000000005',
    '71000000-0000-0000-0000-000000000003',
    public.fn_wm_previous_working_day(public.fn_wm_business_date()),
    'Previous working-day synthetic update.', '1 update',
    'Previous-day activity recorded.', false, null, null,
    (public.fn_wm_previous_working_day(public.fn_wm_business_date())::timestamp + interval '10 hours') at time zone 'Asia/Kuala_Lumpur'
  ),
  (
    '75000000-0000-0000-0000-000000000002',
    '72000000-0000-0000-0000-000000000005',
    '71000000-0000-0000-0000-000000000003',
    public.fn_wm_business_date(),
    'Today synthetic update for supervisor review.', '1 update',
    'Today activity recorded.', false, null, null, now() - interval '20 minutes'
  ),
  (
    '75000000-0000-0000-0000-000000000003',
    '72000000-0000-0000-0000-000000000006',
    '71000000-0000-0000-0000-000000000004',
    public.fn_wm_business_date(),
    'Today pending synthetic update.', '1 update',
    'Pending review activity recorded.', false, null, null, now() - interval '10 minutes'
  ),
  (
    '75000000-0000-0000-0000-000000000004',
    '72000000-0000-0000-0000-000000000001',
    '71000000-0000-0000-0000-000000000004',
    public.fn_wm_business_date(),
    'Synthetic update with a restricted artifact reference.', '1 reference',
    'Restricted artifact remains protected.', false,
    '73000000-0000-0000-0000-000000000002', null, now() - interval '5 minutes'
  ),
  (
    '75000000-0000-0000-0000-000000000005',
    '72000000-0000-0000-0000-000000000008',
    '71000000-0000-0000-0000-000000000003',
    public.fn_wm_business_date(),
    'Restricted task synthetic update.', '1 update',
    'Restricted update recorded.', false, null, null, now() - interval '4 minutes'
  ),
  (
    '75000000-0000-0000-0000-000000000006',
    '72000000-0000-0000-0000-000000000003',
    '71000000-0000-0000-0000-000000000008',
    public.fn_wm_business_date(),
    'Foreign scope synthetic update.', '1 update',
    'Foreign scope activity recorded.', false, null, null, now() - interval '3 minutes'
  );

insert into public.daily_update_reviews (
  id, daily_update_id, reviewer_id, review_status, supervisor_comment
) values (
  '76000000-0000-0000-0000-000000000001',
  '75000000-0000-0000-0000-000000000002',
  '71000000-0000-0000-0000-000000000002',
  'checked',
  'Synthetic review completed.'
);

commit;
