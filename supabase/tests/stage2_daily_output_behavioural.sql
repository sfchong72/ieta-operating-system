-- Local-only behavioural security and workflow gate for IEOS Stage 2.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(35);

set local role anon;
select ieos_stage1_test.claim(null, 'anon');
select extensions.ok(not ieos_stage1_test.probe('select count(*) from public.daily_work_updates'), 'T01 [ANON SELECT] daily updates are denied');
select extensions.ok(not ieos_stage1_test.probe($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000001','x','1','y',false,null,null,true)$q$), 'T02 [ANON RPC] submission is denied');
select extensions.ok(not has_function_privilege('anon', 'public.submit_daily_work_update(uuid,text,text,text,boolean,text,text,boolean)', 'EXECUTE'), 'T03 [GRANTS] anon has no submit execution');
select extensions.ok(has_function_privilege('authenticated', 'public.submit_daily_work_update(uuid,text,text,text,boolean,text,text,boolean)', 'EXECUTE'), 'T04 [GRANTS] authenticated has reviewed submit signature');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000005', 'authenticated');
select extensions.is((select count(*)::bigint from public.daily_work_updates), 0::bigint, 'T05 [UNASSIGNED SELECT] no daily updates are visible');
select extensions.ok(not ieos_stage1_test.probe($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000001','x','1','y',false,null,null,true)$q$), 'T06 [UNASSIGNED RPC] submission is denied');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000006', 'authenticated');
select extensions.ok(not ieos_stage1_test.probe($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000001','x','1','y',false,null,null,true)$q$), 'T07 [INACTIVE RPC] inactive caller is denied');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000004', 'authenticated');
select extensions.is((select count(*)::bigint from public.daily_work_updates where task_id='72000000-0000-0000-0000-000000000007'), 5::bigint, 'T08 [INTERN SELECT] assigned update history is visible');
select extensions.is((select count(*)::bigint from public.daily_work_updates where task_id='72000000-0000-0000-0000-000000000003'), 0::bigint, 'T09 [CROSS SCOPE SELECT] foreign business-unit history is hidden');
select extensions.ok(not ieos_stage1_test.probe($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000002','Forbidden','1','Forbidden',false,null,null,true)$q$), 'T10 [CROSS USER] intern cannot update another user task');
select extensions.ok(not ieos_stage1_test.probe($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000001','Completed item','1','Final result',true,null,null,true)$q$), 'T11 [EVIDENCE REQUIRED] completed deliverable without link is denied');
select extensions.ok(not ieos_stage1_test.probe($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000001','Safe work','1','Safe result',false,null,null,false)$q$), 'T12 [DATA HANDLING] confirmation is required');
select extensions.ok(ieos_stage1_test.execute_ok($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000001','Prepared final synthetic artwork','1 artwork','Final artwork ready',true,'https://example.test/stage2-evidence',null,true)$q$), 'T13 [SUBMIT] assignee can submit completed deliverable with evidence');
select extensions.ok(exists(select 1 from public.daily_work_updates where task_id='72000000-0000-0000-0000-000000000001' and staff_id='71000000-0000-0000-0000-000000000004' and deliverable_completed), 'T14 [AUTH IDENTITY] staff identity derives from auth');
select extensions.ok(exists(select 1 from public.daily_work_updates u join public.work_task_artifacts a on a.id=u.artifact_id and a.task_id=u.task_id where u.task_id='72000000-0000-0000-0000-000000000001' and a.artifact_type='evidence' and a.url='https://example.test/stage2-evidence'), 'T15 [ARTIFACT LINK] evidence creates a linked task artifact');
select extensions.is((select a.artifact_sensitivity from public.daily_work_updates u join public.work_task_artifacts a on a.id=u.artifact_id where u.task_id='72000000-0000-0000-0000-000000000001' order by u.created_at desc limit 1), 'operational'::text, 'T16 [ARTIFACT SENSITIVITY] evidence inherits permitted task sensitivity');
select extensions.ok(exists(select 1 from public.work_tasks t join public.daily_work_updates u on u.task_id=t.id where t.id='72000000-0000-0000-0000-000000000001' and t.last_activity_at is not null and t.last_activity_at >= u.created_at), 'T17 [ATOMIC ACTIVITY] task activity advances with accepted update');
select extensions.ok(exists(select 1 from public.work_task_events where task_id='72000000-0000-0000-0000-000000000001' and actor_id='71000000-0000-0000-0000-000000000004' and event_type='daily_update_added'), 'T18 [AUDIT] authenticated update event is present');
select extensions.is(ieos_stage1_test.affected_rows($q$insert into public.daily_work_updates(task_id,staff_id,what_done_today,result_or_output) values('72000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000001','Forged','Forged')$q$), (-1)::bigint, 'T19 [DIRECT INSERT] client cannot forge updates');
select extensions.is(ieos_stage1_test.affected_rows($q$update public.daily_work_updates set what_done_today='Changed' where task_id='72000000-0000-0000-0000-000000000001'$q$), (-1)::bigint, 'T20 [IMMUTABLE] client cannot update submission');
select extensions.is(ieos_stage1_test.affected_rows($q$delete from public.daily_work_updates where task_id='72000000-0000-0000-0000-000000000001'$q$), (-1)::bigint, 'T21 [IMMUTABLE] client cannot delete submission');
select extensions.ok(not ieos_stage1_test.probe($q$select public.review_daily_work_update('74000000-0000-0000-0000-000000000001','approved','Self review',true)$q$), 'T22 [REVIEW AUTHORITY] intern cannot review submission');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000002', 'authenticated');
select extensions.ok(ieos_stage1_test.execute_ok($q$select public.review_daily_work_update('74000000-0000-0000-0000-000000000001','checked','Checked synthetic output.',true)$q$), 'T23 [MANAGER REVIEW] scoped manager can append review');
select extensions.ok(ieos_stage1_test.execute_ok($q$select public.review_daily_work_update('74000000-0000-0000-0000-000000000001','approved','Approved synthetic output.',true)$q$), 'T24 [APPEND REVIEW] later review is appended');
select extensions.is((select count(*)::bigint from public.daily_update_reviews where daily_update_id='74000000-0000-0000-0000-000000000001'), 2::bigint, 'T25 [APPEND ONLY] both review events remain');
select extensions.ok(exists(select 1 from public.daily_update_reviews where daily_update_id='74000000-0000-0000-0000-000000000001' and reviewer_id='71000000-0000-0000-0000-000000000002'), 'T26 [REVIEW IDENTITY] reviewer derives from auth');
select extensions.ok(not ieos_stage1_test.probe($q$select public.review_daily_work_update('74000000-0000-0000-0000-000000000001','correction_required',null,true)$q$), 'T27 [CORRECTION VALIDATION] correction requires comment');
select extensions.is(ieos_stage1_test.affected_rows($q$update public.daily_update_reviews set review_status='approved'$q$), (-1)::bigint, 'T28 [REVIEW IMMUTABLE] client cannot update reviews');
select extensions.is(ieos_stage1_test.affected_rows($q$delete from public.daily_update_reviews$q$), (-1)::bigint, 'T29 [REVIEW IMMUTABLE] client cannot delete reviews');
select extensions.ok(not ieos_stage1_test.probe($q$select public.submit_daily_work_update('72000000-0000-0000-0000-000000000003','Forbidden','1','Forbidden',false,null,null,true)$q$), 'T30 [MANAGER SCOPE] manager cannot submit across business unit');
select extensions.ok(not ieos_stage1_test.probe($q$select public.review_daily_work_update('74000000-0000-0000-0000-000000000001','invalid','Invalid',true)$q$), 'T31 [REVIEW STATUS] invalid state is denied');
select extensions.ok(exists(select 1 from public.work_task_events where task_id='72000000-0000-0000-0000-000000000007' and actor_id='71000000-0000-0000-0000-000000000002' and event_type='daily_update_reviewed'), 'T32 [REVIEW AUDIT] review event is recorded');
select extensions.ok(exists(select 1 from public.work_task_attention where id='72000000-0000-0000-0000-000000000007' and meaningful_working_days=3 and 'STUCK'=any(attention_flags)), 'T33 [WORKING DAYS] three distinct weekdays trigger STUCK');
select extensions.is((select meaningful_working_days from public.work_task_attention where id='72000000-0000-0000-0000-000000000007'), 3, 'T34 [DISTINCT DAYS] same-day duplicates and weekend do not inflate count');
reset role;

select extensions.throws_ok(
  $q$insert into public.daily_work_updates(task_id,staff_id,what_done_today,result_or_output,artifact_id) values('72000000-0000-0000-0000-000000000002','71000000-0000-0000-0000-000000000007','Mismatch','Mismatch','73000000-0000-0000-0000-000000000001')$q$,
  '23514',
  'Daily update artifact must belong to the linked task.',
  'T35 [ARTIFACT INTEGRITY] artifact from another task is rejected'
);

select * from extensions.finish();
rollback;
