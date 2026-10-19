-- Local-only behavioural security and correctness gate for IEOS Stage 3.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(60);

set local role anon;
select ieos_stage1_test.claim(null, 'anon');
select extensions.ok(not ieos_stage1_test.probe('select count(*) from public.work_dashboard_attention'), 'T01 [ANON] dashboard attention is denied');
select extensions.ok(not has_function_privilege('anon', 'public.get_work_dashboard_team_workload(uuid,uuid,uuid,text,text,text,date,date)', 'EXECUTE'), 'T02 [ANON] workload RPC is denied');
select extensions.ok(not has_function_privilege('anon', 'public.get_work_dashboard_missing_updates_today(uuid,uuid,uuid,text)', 'EXECUTE'), 'T03 [ANON] missing-update RPC is denied');
reset role;

select extensions.ok(has_function_privilege('authenticated', 'public.get_work_dashboard_team_workload(uuid,uuid,uuid,text,text,text,date,date)', 'EXECUTE'), 'T04 [GRANTS] authenticated workload signature is reviewed');
select extensions.ok(has_function_privilege('authenticated', 'public.get_work_dashboard_missing_updates_today(uuid,uuid,uuid,text)', 'EXECUTE'), 'T05 [GRANTS] authenticated missing-update signature is reviewed');

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000002', 'authenticated');
select extensions.ok(public.fn_wm_can_view_dashboard(auth.uid()), 'T06 [MANAGER] scoped manager can open dashboard');
select extensions.ok((select count(*) > 0 from public.work_dashboard_attention), 'T07 [MANAGER] scoped dashboard returns visible tasks');
select extensions.is((select count(*)::bigint from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000003'), 0::bigint, 'T08 [CROSS BU] foreign task is absent');
select extensions.is((select count(*)::bigint from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000008'), 0::bigint, 'T09 [P&C] restricted task is absent');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000007' and 'OVERDUE'=any(attention_flags)), 'T10 [OVERDUE] canonical flag is present');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000007' and 'STUCK'=any(attention_flags)), 'T11 [STUCK] canonical flag is present');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000007' and 'BLOCKED'=any(attention_flags)), 'T12 [BLOCKED] canonical flag is present');
select extensions.is((select meaningful_working_days from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000007'), 3, 'T13 [WORKING DAYS] duplicates and weekend remain excluded');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000010' and 'COMPLETED MISSING EVIDENCE'=any(attention_flags)), 'T14 [MISSING EVIDENCE] legacy anomaly is detected');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000009' and 'WAITING FEEDBACK'=any(attention_flags)), 'T15 [WAITING] waiting-feedback flag is present');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000009' and 'SUPERVISOR BOTTLENECK'=any(attention_flags)), 'T16 [BOTTLENECK] review-window breach is flagged');
select extensions.ok(not exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000009' and 'NO UPDATE PREVIOUS WORKDAY'=any(attention_flags)), 'T17 [FALSE POSITIVE] waiting feedback is not blamed on assignee');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000002' and 'NO UPDATE PREVIOUS WORKDAY'=any(attention_flags)), 'T18 [NO UPDATE] genuinely active task is flagged');
select extensions.ok(not exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000001' and 'NO UPDATE PREVIOUS WORKDAY'=any(attention_flags)), 'T19 [FALSE POSITIVE] not-started task is excluded');
select extensions.ok(not exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000007' and 'NO UPDATE PREVIOUS WORKDAY'=any(attention_flags)), 'T20 [FALSE POSITIVE] blocked task is excluded');
select extensions.ok(not exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000005' and 'NO UPDATE PREVIOUS WORKDAY'=any(attention_flags)), 'T21 [PREVIOUS UPDATE] prior workday activity suppresses alert');
select extensions.ok(not exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000006' and 'NO UPDATE PREVIOUS WORKDAY'=any(attention_flags)), 'T22 [RECENT ACTIVE] newly active task is not falsely flagged');
select extensions.is(public.fn_wm_previous_working_day('2026-09-07'::date), '2026-09-04'::date, 'T23 [MONDAY] previous working day is Friday');
select extensions.is(public.fn_wm_working_days_elapsed('2026-09-04'::date, '2026-09-07'::date), 1, 'T24 [WEEKEND] elapsed count excludes weekend');
select extensions.is(public.fn_wm_supervisor_review_threshold(), 2, 'T25 [CONFIG] review threshold comes from one setting');
select extensions.is((select count(*)::bigint from public.work_dashboard_daily_updates where task_id='72000000-0000-0000-0000-000000000003'), 0::bigint, 'T26 [DAILY CROSS BU] foreign updates are absent');
select extensions.is((select count(*)::bigint from public.work_dashboard_daily_updates where task_id='72000000-0000-0000-0000-000000000008'), 0::bigint, 'T27 [DAILY P&C] restricted task updates are absent');
select extensions.ok(exists(select 1 from public.work_dashboard_daily_updates where id='75000000-0000-0000-0000-000000000004' and has_visible_artifact=false), 'T28 [ARTIFACT PRIVACY] restricted artifact indicator remains hidden');
select extensions.is((select count(*)::bigint from public.get_work_dashboard_team_workload() where assigned_to='71000000-0000-0000-0000-000000000008'), 0::bigint, 'T29 [AGGREGATE CROSS BU] foreign assignee count is absent');
select extensions.is((select active_tasks from public.get_work_dashboard_team_workload() where assigned_to='71000000-0000-0000-0000-000000000003'), 1::bigint, 'T30 [AGGREGATE P&C] hidden restricted task does not inflate count');
select extensions.is((select workload_signal from public.get_work_dashboard_team_workload() where assigned_to='71000000-0000-0000-0000-000000000004'), 'high_active_load'::text, 'T31 [WORKLOAD] high load is neutral configurable context');
select extensions.ok(exists(select 1 from public.get_work_dashboard_team_workload(p_project_reference=>'Stage 3 Campaign')), 'T32 [PROJECT FILTER] project filter is server-side');
select extensions.ok(exists(select 1 from public.get_work_dashboard_team_workload(p_attention_flag=>'SUPERVISOR BOTTLENECK') where assigned_to='71000000-0000-0000-0000-000000000004'), 'T33 [FLAG FILTER] attention filter is server-side');
select extensions.is((select count(*)::bigint from public.get_work_dashboard_team_workload(p_business_unit_id=>'00000000-0000-0000-0002-000000000002')), 0::bigint, 'T34 [BU FILTER] inaccessible scope returns no aggregate rows');
select extensions.is((select count(*)::bigint from public.get_work_dashboard_team_workload(p_date_to=>public.fn_wm_business_date()-1)), 1::bigint, 'T35 [DATE FILTER] due-date filter is applied before aggregation');
select extensions.ok(exists(select 1 from public.work_dashboard_daily_updates where id='75000000-0000-0000-0000-000000000003' and awaiting_supervisor_review), 'T36 [PENDING REVIEW] unreviewed update is identified');
select extensions.ok(exists(select 1 from public.work_dashboard_daily_updates where id='75000000-0000-0000-0000-000000000002' and not awaiting_supervisor_review), 'T37 [REVIEWED] reviewed update is not pending');
select extensions.ok(exists(select 1 from public.get_work_dashboard_missing_updates_today() where assigned_to='71000000-0000-0000-0000-000000000007'), 'T38 [MISSING TODAY] active assignee without update is listed');
select extensions.ok(not exists(select 1 from public.get_work_dashboard_missing_updates_today() where assigned_to='71000000-0000-0000-0000-000000000008'), 'T39 [MISSING LEAK] foreign assignee is absent');
select extensions.ok(not exists(select 1 from public.get_work_dashboard_missing_updates_today() where assigned_to='71000000-0000-0000-0000-000000000004' and active_task_count > 2), 'T40 [STATUS FILTER] waiting/not-started/blocked tasks do not inflate missing updates');
select extensions.is((select attention_rank from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000007'), 1::smallint, 'T41 [SORT] overdue has highest priority');
select extensions.is((select attention_rank from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000010'), 3::smallint, 'T42 [SORT] missing evidence priority is stable');
select extensions.is((select attention_rank from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000009'), 5::smallint, 'T43 [SORT] waiting feedback precedes bottleneck secondary flag');
select extensions.is((select attention_rank from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000002'), 6::smallint, 'T44 [SORT] no-update priority is stable');
select extensions.is((select count(*)::bigint from information_schema.columns where table_schema='public' and table_name='work_dashboard_daily_updates' and column_name in ('url','artifact_id')), 0::bigint, 'T45 [METADATA] daily aggregate exposes no artifact URL or identifier');
select extensions.ok((select reloptions @> array['security_invoker=true'] from pg_class where oid='public.work_dashboard_attention'::regclass), 'T46 [VIEW SECURITY] attention view is security invoker');
select extensions.ok((select reloptions @> array['security_invoker=true'] from pg_class where oid='public.work_dashboard_daily_updates'::regclass), 'T47 [VIEW SECURITY] daily view is security invoker');
select extensions.is((select count(*)::bigint from public.work_dashboard_settings), 1::bigint, 'T48 [SETTINGS] manager can read one bounded configuration row');
select extensions.is((select count(*)::bigint from public.work_dashboard_access_grants), 0::bigint, 'T49 [GRANT PRIVACY] manager cannot inspect dashboard grants');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000003', 'authenticated');
select extensions.ok(public.fn_wm_can_view_dashboard(auth.uid()), 'T50 [STAFF GRANT] appointed full-time user can open dashboard');
select extensions.is((select count(*)::bigint from public.work_dashboard_attention), 1::bigint, 'T51 [STAFF SCOPE] appointed staff sees only own permitted task');
select extensions.is((select count(*)::bigint from public.get_work_dashboard_team_workload()), 1::bigint, 'T52 [STAFF AGGREGATE] appointed staff sees only own aggregate');
select extensions.ok(not exists(select 1 from public.get_work_dashboard_team_workload() where assigned_to='71000000-0000-0000-0000-000000000004'), 'T53 [STAFF LEAK] coworker aggregate is absent');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000004', 'authenticated');
select extensions.ok(not public.fn_wm_can_view_dashboard(auth.uid()), 'T54 [INTERN] unappointed intern cannot open dashboard');
select extensions.is((select count(*)::bigint from public.work_dashboard_attention), 0::bigint, 'T55 [INTERN] dashboard rows are hidden');
select extensions.is((select count(*)::bigint from public.get_work_dashboard_team_workload()), 0::bigint, 'T56 [INTERN] aggregate rows are hidden');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000006', 'authenticated');
select extensions.ok(not public.fn_wm_can_view_dashboard(auth.uid()), 'T57 [INACTIVE] grant cannot reactivate an inactive user');
reset role;

set local role authenticated;
select ieos_stage1_test.claim('71000000-0000-0000-0000-000000000001', 'authenticated');
select extensions.ok(public.fn_wm_can_view_dashboard(auth.uid()), 'T58 [DIRECTOR] Director can open global operational dashboard');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000003'), 'T59 [DIRECTOR] foreign business-unit task is visible globally');
select extensions.ok(exists(select 1 from public.work_dashboard_attention where id='72000000-0000-0000-0000-000000000008') and (select count(*)=2 from public.work_dashboard_access_grants), 'T60 [DIRECTOR] P&C task and access-grant audit are visible');
reset role;

select * from extensions.finish();
rollback;
