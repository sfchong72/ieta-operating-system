-- Local-only behavioural security gate for staging approval/edit work.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(35);

-- Staff: own department edit/submit succeeds; workflow and history cannot be forged.
set local role authenticated;
select ieos_test.claim('99999999-aaaa-0000-0000-000000000003', 'authenticated');
select extensions.is(
  (select count(*)::bigint from staging.content_items where id = '88888888-0000-0000-0000-000000000001'),
  1::bigint,
  '[STAFF SELECT] own-department item is visible'
);
select extensions.is(
  (select count(*)::bigint from staging.content_items where id = '88888888-0000-0000-0000-000000000003'),
  0::bigint,
  '[CROSS DEPARTMENT SELECT] foreign-department item is hidden'
);
select extensions.is(
  ieos_test.affected_rows($q$update staging.content_items set title='TEST — Routine Edited' where id='88888888-0000-0000-0000-000000000001'$q$),
  1::bigint,
  '[STAFF UPDATE] own-department draft is editable'
);
select extensions.is(
  (select count(*)::bigint from staging.approval_action where content_item_id='88888888-0000-0000-0000-000000000001' and action='edited'),
  1::bigint,
  '[AUDIT] content edit creates one atomic edited event'
);
select extensions.is(
  ieos_test.affected_rows($q$update staging.content_items set status='approved' where id='88888888-0000-0000-0000-000000000001'$q$),
  (-1)::bigint,
  '[WORKFLOW GUARD] direct approval status write is denied'
);
select extensions.ok(
  not ieos_test.probe($q$insert into staging.approval_action(content_item_id,actor_id,action) values('88888888-0000-0000-0000-000000000001','99999999-aaaa-0000-0000-000000000003','approved')$q$),
  '[AUDIT] direct forged approval event is denied'
);
select extensions.ok(
  ieos_test.execute_ok($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000001')$q$),
  '[STAFF RPC] own-department draft can be submitted'
);
select extensions.ok(
  (select status='awaiting_approval' and approval_status='pending' from staging.content_items where id='88888888-0000-0000-0000-000000000001')
  and (select count(*)=1 from staging.approval_action where content_item_id='88888888-0000-0000-0000-000000000001' and action='submitted'),
  '[ATOMIC SUBMIT] state and submitted history are both present'
);
select extensions.ok(
  not ieos_test.probe($q$select staging.review_content_item('88888888-0000-0000-0000-000000000001','approved',null)$q$),
  '[STAFF RPC] staff cannot approve'
);
select extensions.is(
  ieos_test.affected_rows($q$update staging.content_items set title='Forbidden' where id='88888888-0000-0000-0000-000000000003'$q$),
  0::bigint,
  '[CROSS DEPARTMENT UPDATE] foreign-department item cannot be edited'
);
select extensions.ok(
  not ieos_test.probe($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000003')$q$),
  '[CROSS DEPARTMENT RPC] foreign-department item cannot be submitted'
);
select extensions.is(
  (select count(*)::bigint from staging.content_items where id='88888888-0000-0000-0000-000000000005'),
  0::bigint,
  '[NULL DEPARTMENT] unscoped item is hidden from staff'
);
select extensions.ok(
  not ieos_test.probe($q$insert into staging.content_items(id,business_unit_id,department_id,title,status,user_id) values('88888888-0000-0000-0000-000000000099','99999999-0000-0000-0002-000000000002','99999999-0000-0000-0003-000000000001','Invalid scope','draft','99999999-aaaa-0000-0000-000000000003')$q$),
  '[EDGE SCOPE] mismatched business unit and department are rejected'
);
reset role;

-- Intern: own work only.
set local role authenticated;
select ieos_test.claim('99999999-aaaa-0000-0000-000000000004', 'authenticated');
select extensions.is(
  ieos_test.affected_rows($q$update staging.content_items set title='TEST — Intern Edited' where id='88888888-0000-0000-0000-000000000004'$q$),
  1::bigint,
  '[INTERN UPDATE] own item is editable'
);
select extensions.is(
  ieos_test.affected_rows($q$update staging.content_items set title='Forbidden' where id='88888888-0000-0000-0000-000000000002'$q$),
  0::bigint,
  '[INTERN UPDATE] another user item is denied'
);
select extensions.ok(
  ieos_test.execute_ok($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000004')$q$),
  '[INTERN RPC] own item can be submitted'
);
select extensions.ok(
  not ieos_test.probe($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000002')$q$),
  '[INTERN RPC] another user item cannot be submitted'
);
reset role;

-- Management handles routine work, not escalated work.
set local role authenticated;
select ieos_test.claim('99999999-aaaa-0000-0000-000000000002', 'authenticated');
select extensions.ok(
  ieos_test.execute_ok($q$select staging.comment_on_content_item('88888888-0000-0000-0000-000000000001','Looks ready')$q$),
  '[MANAGEMENT RPC] routine approver can comment'
);
select extensions.ok(
  ieos_test.execute_ok($q$select staging.review_content_item('88888888-0000-0000-0000-000000000001','approved','Approved by management')$q$),
  '[MANAGEMENT RPC] routine approver can approve'
);
select extensions.ok(
  (select status='approved' and approval_status='approved' from staging.content_items where id='88888888-0000-0000-0000-000000000001')
  and (select count(*)=1 from staging.approval_action where content_item_id='88888888-0000-0000-0000-000000000001' and action='approved'),
  '[ATOMIC APPROVE] approved state and history are both present'
);
select extensions.ok(
  not ieos_test.probe($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000001')$q$),
  '[INVALID TRANSITION] approved item cannot be resubmitted'
);
select extensions.ok(
  ieos_test.execute_ok($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000002')$q$),
  '[MANAGEMENT RPC] accessible escalated draft can be submitted'
);
select extensions.ok(
  not ieos_test.probe($q$select staging.review_content_item('88888888-0000-0000-0000-000000000002','approved',null)$q$),
  '[ROUTING] Management cannot approve escalated content'
);
select extensions.ok(
  not ieos_test.probe($q$select staging.review_content_item('88888888-0000-0000-0000-000000000004','revision_requested','')$q$),
  '[VALIDATION] revision request requires a comment'
);
reset role;

-- Super Admin handles escalated work, while routine routing stays explicit.
set local role authenticated;
select ieos_test.claim('99999999-aaaa-0000-0000-000000000001', 'authenticated');
select extensions.ok(
  not ieos_test.probe($q$select staging.review_content_item('88888888-0000-0000-0000-000000000004','approved',null)$q$),
  '[ROUTING] Super Admin does not bypass the routine Management queue'
);
select extensions.ok(
  ieos_test.execute_ok($q$select staging.comment_on_content_item('88888888-0000-0000-0000-000000000002','Strategic review complete')$q$),
  '[SUPER ADMIN RPC] escalated approver can comment'
);
select extensions.ok(
  ieos_test.execute_ok($q$select staging.review_content_item('88888888-0000-0000-0000-000000000002','approved','Approved by Claire-equivalent')$q$),
  '[SUPER ADMIN RPC] escalated approver can approve'
);
select extensions.ok(
  (select status='approved' from staging.content_items where id='88888888-0000-0000-0000-000000000002')
  and (select count(*)=1 from staging.approval_action where content_item_id='88888888-0000-0000-0000-000000000002' and action='approved'),
  '[ATOMIC ESCALATED APPROVE] state and history are both present'
);
select extensions.ok(
  -- RLS-denied UPDATE/DELETE statements complete successfully but affect zero
  -- rows. Assert the row counts as well as the durable audit state instead of
  -- incorrectly requiring PostgreSQL to raise an exception.
  ieos_test.affected_rows($q$update staging.approval_action set comment='tampered' where content_item_id='88888888-0000-0000-0000-000000000002'$q$) = 0
  and ieos_test.affected_rows($q$delete from staging.approval_action where content_item_id='88888888-0000-0000-0000-000000000002'$q$) = 0
  and (
    select count(*) = 1
      and max(comment) = 'Approved by Claire-equivalent'
    from staging.approval_action
    where content_item_id='88888888-0000-0000-0000-000000000002'
      and action='approved'
  ),
  '[IMMUTABILITY] approval history cannot be updated or deleted'
);
select extensions.ok(
  not ieos_test.probe($q$insert into staging.user_role_assignment(profile_id,role) values('99999999-aaaa-0000-0000-000000000003','management')$q$),
  '[ROLE MODEL] one profile cannot receive contradictory multiple roles'
);
reset role;

-- Authenticated but unassigned, and anonymous callers, have no workflow path.
set local role authenticated;
select ieos_test.claim('99999999-aaaa-0000-0000-000000000005', 'authenticated');
select extensions.is(
  (select count(*)::bigint from staging.content_items),
  0::bigint,
  '[UNAUTHORISED SELECT] unassigned user sees no content items'
);
select extensions.ok(
  not ieos_test.probe($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000003')$q$),
  '[UNAUTHORISED RPC] unassigned user cannot submit'
);
reset role;

set local role anon;
select ieos_test.claim(null, 'anon');
select extensions.ok(
  not ieos_test.probe($q$select * from staging.content_items$q$)
  and not ieos_test.probe($q$select staging.submit_content_item_for_review('88888888-0000-0000-0000-000000000001')$q$)
  and not ieos_test.probe($q$select staging.review_content_item('88888888-0000-0000-0000-000000000002','approved',null)$q$),
  '[ANON] tables and privileged workflow RPCs are denied'
);
reset role;

select extensions.ok(
  not has_function_privilege('anon', 'staging.submit_content_item_for_review(uuid)', 'execute')
  and not has_function_privilege('anon', 'staging.review_content_item(uuid,text,text)', 'execute')
  and not has_function_privilege('anon', 'staging.comment_on_content_item(uuid,text)', 'execute'),
  '[GRANTS] anon has no workflow RPC execution'
);
select extensions.ok(
  exists (
    select 1
    from pg_indexes
    where schemaname='staging'
      and tablename='user_role_assignment'
      and indexname='user_role_assignment_one_role_per_profile'
  ),
  '[ROLE MODEL] database enforces one effective role per profile'
);

select * from extensions.finish();
rollback;
