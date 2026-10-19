-- STAGING ONLY. See supabase/staging/README.md.
-- Adds Edit support across content_tasks, content_items, sops,
-- content_ideas, knowledge_items, and work_files.

-- 1. approval_action gets a new 'edited' action type (content_items audit trail).
alter table staging.approval_action drop constraint approval_action_action_check;
alter table staging.approval_action add constraint approval_action_action_check
  check (action in ('submitted','approved','revision_requested','comment','edited'));

-- 2. record_edit_log: generic edit audit trail for sops/content_ideas/
--    knowledge_items, which have no per-record activity table of their own
--    (unlike content_tasks -> activities, content_items -> approval_action).
create table staging.record_edit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null check (table_name in ('sops','content_ideas','knowledge_items')),
  record_id uuid not null,
  actor_id uuid references staging.profiles(id),
  summary text not null,
  created_at timestamptz not null default now()
);

alter table staging.record_edit_log enable row level security;
create policy "staging_record_edit_log_select" on staging.record_edit_log
  for select using (auth.uid() is not null);
create policy "staging_record_edit_log_insert" on staging.record_edit_log
  for insert with check (auth.uid() is not null and actor_id = auth.uid());

-- 3. work_files needs an UPDATE policy — it currently only has select/insert,
--    so "correct a work link after the fact" is blocked at the DB level
--    even once the UI exists. Same department-scoping as its own select policy.
create policy "staging_work_files_update" on staging.work_files
  for update using (
    staging.fn_has_department_access(auth.uid(), staging.fn_task_department(task_id))
  );

-- 4. staging_approval_action_insert is a hard allow-list of action types
--    (submitted / approved / revision_requested / comment) — extending the
--    CHECK constraint to allow 'edited' isn't enough on its own, this policy
--    also has to explicitly admit it, or every edit is silently RLS-blocked
--    even though it passes the table's own CHECK. Same rule as 'submitted':
--    anyone with department access, intern restricted to their own item —
--    i.e. the same people who can write to content_items at all can log
--    an edit to it.
drop policy "staging_approval_action_insert" on staging.approval_action;
create policy "staging_approval_action_insert" on staging.approval_action
  for insert with check (
    auth.uid() is not null
    and (
      (select department_id from staging.content_items where id = content_item_id) is null
      or staging.fn_has_department_access(auth.uid(), (select department_id from staging.content_items where id = content_item_id))
    )
    and (
      -- Anyone with access can submit/resubmit; intern restricted to own item.
      (action in ('submitted', 'edited') and (
        staging.fn_role(auth.uid()) != 'intern'
        or (select user_id from staging.content_items where id = content_item_id) = auth.uid()
      ))
      -- Approve/revision-request/comment: Super Admin or Management only.
      or (action in ('approved', 'revision_requested', 'comment')
          and staging.fn_role(auth.uid()) in ('super_admin', 'management'))
    )
  );
