-- Synthetic Stage 2 fixtures. Run after Stage 1 fixtures.
begin;

insert into public.daily_work_updates (
  id, task_id, staff_id, work_date, what_done_today, quantity,
  result_or_output, deliverable_completed, blocker_or_help, created_at
) values
  ('74000000-0000-0000-0000-000000000001', '72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', '2026-09-01', 'Prepared synthetic draft.', '1 draft', 'Draft recorded.', false, null, '2026-09-01 09:00:00+08'),
  ('74000000-0000-0000-0000-000000000002', '72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', '2026-09-02', 'Revised synthetic draft.', '2 sections', 'Revision recorded.', false, null, '2026-09-02 09:00:00+08'),
  ('74000000-0000-0000-0000-000000000003', '72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', '2026-09-03', 'Prepared review copy.', '1 copy', 'Review copy recorded.', false, 'Waiting for synthetic feedback.', '2026-09-03 09:00:00+08'),
  ('74000000-0000-0000-0000-000000000004', '72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', '2026-09-03', 'Added another note.', '1 note', 'Same-day note recorded.', false, null, '2026-09-03 15:00:00+08'),
  ('74000000-0000-0000-0000-000000000005', '72000000-0000-0000-0000-000000000007', '71000000-0000-0000-0000-000000000004', '2026-09-05', 'Weekend synthetic check.', '1 check', 'Weekend entry recorded.', false, null, '2026-09-05 09:00:00+08');

update public.work_tasks
set last_activity_at = '2026-09-05 09:00:00+08'
where id = '72000000-0000-0000-0000-000000000007';

commit;
