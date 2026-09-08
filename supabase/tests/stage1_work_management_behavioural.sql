-- Local-only behavioural security and workflow gate for IEOS Stage 1.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(60);

-- Anonymous identity.
set local role anon;
select ieos_stage1_test.claim(null, 'anon');
select extensions.is(
  (select count(*)::bigint from public.work_tasks), 0::bigint,
  'T01 [ANON SELECT] no work task is visible'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.create_work_task(
    '00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001',
    '71000000-0000-0000-0000-000000000004',null,'Forbidden','Forbidden','Forbidden',true,
    current_date,'medium','not_started','operational',true)$q$),
  'T02 [ANON RPC] create task is denied'
);
select extensions.ok(
  not has_function_privilege('anon', 'public.create_work_task(uuid,uuid,uuid,text,text,text,text,boolean,date,text,text,text,boolean)', 'EXECUTE'),
  'T03 [GRANTS] anon has no create-task execution'
);
select extensions.ok(
  has_function_privilege('authenticated', 'public.create_work_task(uuid,uuid,uuid,text,text,text,text,boolean,date,text,text,text,boolean)', 'EXECUTE'),
  'T04 [GRANTS] authenticated role has the reviewed RPC signature'
);
reset role;

-- Authenticated but unassigned user.
set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000005', 'authenticated');
select extensions.is(
  (select count(*)::bigint from public.work_tasks), 0::bigint,
  'T05 [UNASSIGNED SELECT] no task is visible'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000001','in_progress',10,null,true)$q$),
  'T06 [UNASSIGNED RPC] task update is denied'
);
select extensions.ok(
  not ieos_stage1_test.probe('select * from public.list_work_task_assignees()'),
  'T07 [UNASSIGNED RPC] assignee directory is denied'
);
reset role;

-- Inactive profile.
set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000006', 'authenticated');
select extensions.is(
  (select count(*)::bigint from public.work_tasks), 0::bigint,
  'T08 [INACTIVE SELECT] inactive user sees no tasks'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000001','in_progress',10,null,true)$q$),
  'T09 [INACTIVE RPC] inactive user cannot update'
);
reset role;

-- Intern: own assigned operational work only; no management fields.
set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000004', 'authenticated');
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000001'), 1::bigint,
  'T10 [INTERN SELECT] assigned operational task is visible'
);
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000002'), 0::bigint,
  'T11 [CROSS DEPARTMENT] foreign department task is hidden'
);
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000003'), 0::bigint,
  'T12 [CROSS BUSINESS UNIT] foreign business-unit task is hidden'
);
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000004'), 0::bigint,
  'T13 [SENSITIVITY] management-only task is hidden from intern'
);
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000008'), 0::bigint,
  'T14 [P&C] restricted task is hidden from intern'
);
select extensions.is(
  (select count(*)::bigint from public.work_task_artifacts where id='73000000-0000-0000-0000-000000000001'), 0::bigint,
  'T15 [ARTIFACT] full-time-only artifact is hidden from intern'
);
select extensions.is(
  (select count(*)::bigint from public.work_task_artifacts where id='73000000-0000-0000-0000-000000000002'), 0::bigint,
  'T16 [ARTIFACT] P&C artifact is hidden although parent task is visible'
);
select extensions.is(
  ieos_stage1_test.affected_rows($q$update public.work_tasks set assigned_to='71000000-0000-0000-0000-000000000003' where id='72000000-0000-0000-0000-000000000001'$q$),
  (-1)::bigint,
  'T17 [DIRECT WRITE] intern cannot alter assignment'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000001','in_progress',25,null,true)$q$),
  'T18 [QUICK UPDATE] intern can update assigned task'
);
select extensions.ok(
  exists (select 1 from public.work_task_updates where task_id='72000000-0000-0000-0000-000000000001' and created_by='71000000-0000-0000-0000-000000000004'),
  'T19 [AUDIT IDENTITY] update author derives from auth identity'
);
select extensions.ok(
  exists (select 1 from public.work_task_events where task_id='72000000-0000-0000-0000-000000000001' and actor_id='71000000-0000-0000-0000-000000000004' and event_type='quick_updated'),
  'T20 [AUDIT IDENTITY] event actor derives from auth identity'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000002','in_progress',50,null,true)$q$),
  'T21 [CROSS SCOPE RPC] intern cannot update another task'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.update_work_task_management(
    '72000000-0000-0000-0000-000000000001','00000000-0000-0000-0002-000000000001',
    'a0000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000003',
    null,'Forbidden','Forbidden','Forbidden',true,current_date,'medium','operational',true)$q$),
  'T22 [MANAGEMENT FIELDS] intern cannot use management edit RPC'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.add_work_task_artifact(
    '72000000-0000-0000-0000-000000000001','working','Canva draft','https://www.canva.com/design/test-draft')$q$),
  'T23 [ARTIFACT] intern can paste an operational work link'
);
select extensions.is(
  (select artifact_sensitivity from public.work_task_artifacts where task_id='72000000-0000-0000-0000-000000000001' and label='Canva draft'),
  'operational'::text,
  'T24 [ARTIFACT SENSITIVITY] staff-facing RPC forces operational sensitivity'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.add_managed_work_task_artifact(
    '72000000-0000-0000-0000-000000000001','reference','pc_restricted','Forbidden','https://example.test/forbidden')$q$),
  'T25 [ARTIFACT SENSITIVITY] intern cannot choose restricted sensitivity'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.add_work_task_comment(
    '72000000-0000-0000-0000-000000000001','Draft started; no personal data included.',true)$q$),
  'T26 [COMMENT] intern can add a task comment'
);
select extensions.ok(
  exists (select 1 from public.work_task_comments where task_id='72000000-0000-0000-0000-000000000001' and author_id='71000000-0000-0000-0000-000000000004'),
  'T27 [COMMENT IDENTITY] comment author derives from auth identity'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$insert into public.work_task_events(task_id,actor_id,event_type) values(
    '72000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000001','supervisor_reviewed')$q$),
  'T28 [AUDIT FORGERY] direct event insert is denied'
);
select extensions.ok(
  ieos_stage1_test.affected_rows($q$update public.work_task_events set actor_id='71000000-0000-0000-0000-000000000001' where task_id='72000000-0000-0000-0000-000000000001'$q$) = -1
  and ieos_stage1_test.affected_rows($q$delete from public.work_task_events where task_id='72000000-0000-0000-0000-000000000001'$q$) = -1,
  'T29 [AUDIT IMMUTABILITY] client update and delete are denied'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000001','blocked',30,null,true)$q$),
  'T30 [BLOCKED VALIDATION] blocked status requires blocker information'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000006','completed',100,null,true)$q$),
  'T31 [COMPLETION] task without evidence or waiver cannot complete'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.supervise_work_task(
    '72000000-0000-0000-0000-000000000006','Self waiver',null,false,true,'No file',true,false,true)$q$),
  'T32 [WAIVER] assignee cannot self-waive evidence'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.add_work_task_artifact(
    '72000000-0000-0000-0000-000000000001','final','Final artwork','https://www.canva.com/design/final-artwork')$q$),
  'T33 [EVIDENCE] assignee can add final artifact'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000001','completed',100,null,true)$q$),
  'T34 [COMPLETION] evidence permits completion'
);
select extensions.ok(
  exists (select 1 from public.work_tasks where id='72000000-0000-0000-0000-000000000001' and status='completed' and progress_percent=100 and completed_at is not null),
  'T35 [COMPLETION STATE] completed invariants are stored'
);
select extensions.ok(
  not exists (select 1 from public.work_task_attention where id='72000000-0000-0000-0000-000000000001' and 'COMPLETED MISSING EVIDENCE'=any(attention_flags)),
  'T36 [COMPLETION FLAG] evidenced task is not flagged missing evidence'
);
reset role;

-- Full-time staff remains assignment-scoped.
set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000003', 'authenticated');
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000005'), 1::bigint,
  'T37 [STAFF SELECT] assigned full-time-only task is visible'
);
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000009'), 0::bigint,
  'T38 [STAFF SELECT] unrelated intern task is hidden'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.quick_update_work_task(
    '72000000-0000-0000-0000-000000000009','in_progress',80,null,true)$q$),
  'T39 [STAFF RPC] unrelated task update is denied'
);
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000008'), 0::bigint,
  'T40 [STAFF P&C] P&C task remains hidden from assigned staff without grant'
);
reset role;

-- Management: all departments in granted BU, never implicit cross-BU/P&C.
set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000002', 'authenticated');
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000002'), 1::bigint,
  'T41 [MANAGEMENT SELECT] granted BU task is visible across department'
);
select extensions.is(
  (select count(*)::bigint from public.work_tasks where id='72000000-0000-0000-0000-000000000003'), 0::bigint,
  'T42 [MANAGEMENT SCOPE] cross-BU task is hidden'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.create_work_task(
    '00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001',
    '71000000-0000-0000-0000-000000000004','September campaign','TEST Created task',
    'Prepare the campaign asset.','Final campaign link',true,current_date+7,'high','not_started','operational',true)$q$),
  'T43 [CREATE] manager can create within granted scope'
);
select extensions.ok(
  exists (select 1 from public.work_tasks where title='TEST Created task' and task_number ~ '^TASK-[0-9]{4}[0-9]{4,}$'),
  'T44 [TASK NUMBER] human-readable task number is generated'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.create_work_task(
    '00000000-0000-0000-0002-000000000002','a1000000-0000-0000-0000-000000000001',
    '71000000-0000-0000-0000-000000000008',null,'Forbidden cross-BU','Forbidden','Forbidden',true,
    current_date+7,'medium','not_started','operational',true)$q$),
  'T45 [CREATE SCOPE] manager cannot create across business unit'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.update_work_task_management(
    '72000000-0000-0000-0000-000000000002','00000000-0000-0000-0002-000000000001',
    'a0000000-0000-0000-0000-000000000002','71000000-0000-0000-0000-000000000007',
    'Design campaign','TEST Design task updated','Prepare a design asset.','Final design link',true,
    current_date+5,'urgent','operational',true)$q$),
  'T46 [MANAGEMENT UPDATE] manager can edit controlled assignment fields'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.add_managed_work_task_artifact(
    '72000000-0000-0000-0000-000000000002','reference','pc_restricted','Restricted brief','https://example.test/restricted-brief')$q$),
  'T47 [MANAGED ARTIFACT] manager can classify a restricted artifact'
);
select extensions.is(
   (select count(*)::bigint from public.work_task_artifacts where task_id='72000000-0000-0000-0000-000000000002' and label='Restricted brief'), 0::bigint,
  'T48 [P&C DEFAULT DENY] manager cannot read P&C artifact without explicit grant'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.supervise_work_task(
    '72000000-0000-0000-0000-000000000009','Internal supervisor note','Continue after review',false,false,null,false,true,true)$q$),
  'T49 [SUPERVISOR] manager can record management-only feedback'
);
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000004', 'authenticated');
select extensions.is(
  (select count(*)::bigint from public.work_task_comments where task_id='72000000-0000-0000-0000-000000000009' and audience='management_only'), 0::bigint,
  'T50 [COMMENT SENSITIVITY] intern cannot read management-only feedback'
);
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000002', 'authenticated');
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.supervise_work_task(
    '72000000-0000-0000-0000-000000000009',null,null,false,true,'Not required',true,false,true)$q$),
  'T51 [WAIVER VALIDATION] output-required task cannot be waived'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.supervise_work_task(
    '72000000-0000-0000-0000-000000000006','No file output required',null,false,true,'Verbal coordination task',true,false,true)$q$),
  'T52 [WAIVER COMPLETION] manager waiver permits no-output completion'
);
select extensions.ok(
  exists (select 1 from public.work_tasks where id='72000000-0000-0000-0000-000000000006' and status='completed' and output_waived and output_waived_by='71000000-0000-0000-0000-000000000002'),
  'T53 [WAIVER IDENTITY] waiver records authenticated manager'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.supervise_work_task(
    '72000000-0000-0000-0000-000000000001','Final output checked',null,true,false,null,false,false,true)$q$),
  'T54 [FINAL APPROVAL] manager can approve existing final evidence'
);
select extensions.ok(
  not ieos_stage1_test.probe($q$select public.grant_work_task_access(
    '72000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000002','pc_restricted')$q$),
  'T55 [P&C GRANT] manager cannot grant P&C access'
);
select extensions.ok(
  exists (select 1 from public.list_work_task_assignees() where profile_id='71000000-0000-0000-0000-000000000004'),
  'T56 [ASSIGNEES] manager sees an in-scope active intern'
);
reset role;

-- Director-equivalent global authority and explicit P&C grant.
set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000001', 'authenticated');
select extensions.ok(
  exists (select 1 from public.work_tasks where id='72000000-0000-0000-0000-000000000003')
  and exists (select 1 from public.work_tasks where id='72000000-0000-0000-0000-000000000008'),
  'T57 [DIRECTOR SELECT] Director sees cross-BU and P&C tasks'
);
select extensions.ok(
  ieos_stage1_test.execute_ok($q$select public.grant_work_task_access(
    '72000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000002','pc_restricted')$q$),
  'T58 [DIRECTOR GRANT] Director can grant task-specific P&C access'
);
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000002', 'authenticated');
select extensions.is(
  (select count(*)::bigint from public.work_task_artifacts where id='73000000-0000-0000-0000-000000000002'), 1::bigint,
  'T59 [P&C ARTIFACT] explicitly granted manager can read restricted artifact'
);
select extensions.ok(
  exists (
    select 1 from public.work_task_attention
    where id='72000000-0000-0000-0000-000000000007'
      and meaningful_working_days=3
      and 'OVERDUE'=any(attention_flags)
      and 'STUCK'=any(attention_flags)
      and 'BLOCKED'=any(attention_flags)
  )
  and exists (
    select 1 from public.work_task_attention
    where id='72000000-0000-0000-0000-000000000009'
      and 'WAITING FEEDBACK'=any(attention_flags)
  )
  and exists (
    select 1 from public.work_task_attention
    where id='72000000-0000-0000-0000-000000000010'
      and 'COMPLETED MISSING EVIDENCE'=any(attention_flags)
  ),
  'T60 [ATTENTION RULES] overdue, three-working-day stuck, blocked, waiting, and legacy evidence flags are exact'
);
reset role;

select * from extensions.finish();
rollback;

