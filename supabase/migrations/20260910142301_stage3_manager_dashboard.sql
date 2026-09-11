-- IEOS Stage 3: Manager Dashboard and Needs Attention workflow.
--
-- LOCAL / REVIEW ONLY. Do not apply to hosted Supabase without a separate
-- production-change approval and verified backup/restore procedure.
--
-- This migration is additive except for replacing the canonical Stage 1/2
-- attention view and task-touch function with their Stage 3 definitions.

alter table public.work_tasks add column status_changed_at timestamptz;

update public.work_tasks
set status_changed_at = coalesce(last_activity_at, updated_at, created_at);

alter table public.work_tasks
  alter column status_changed_at set default now(),
  alter column status_changed_at set not null;

create table public.work_dashboard_settings (
  singleton boolean primary key default true check (singleton),
  supervisor_review_working_days smallint not null default 2 check (
    supervisor_review_working_days between 1 and 10
  ),
  high_active_task_threshold smallint not null default 5 check (
    high_active_task_threshold between 2 and 20
  ),
  low_active_task_threshold smallint not null default 1 check (
    low_active_task_threshold between 0 and 5
  ),
  updated_at timestamptz not null default now(),
  check (low_active_task_threshold < high_active_task_threshold)
);

insert into public.work_dashboard_settings (singleton) values (true);

create table public.work_dashboard_access_grants (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  granted_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create index work_tasks_dashboard_status_changed_idx
  on public.work_tasks (status, status_changed_at)
  include (assigned_to, business_unit_id, department_id, due_date);

create index work_task_artifacts_completion_idx
  on public.work_task_artifacts (task_id, artifact_type)
  where artifact_type in ('final', 'evidence');

create index daily_work_updates_date_task_idx
  on public.daily_work_updates (work_date, task_id)
  include (staff_id, deliverable_completed, artifact_id);

create or replace function public.fn_wm_previous_working_day(reference_date date)
returns date
language plpgsql
immutable
set search_path = ''
as $$
declare
  candidate date := reference_date - 1;
begin
  while extract(isodow from candidate) not between 1 and 5 loop
    candidate := candidate - 1;
  end loop;
  return candidate;
end;
$$;

create or replace function public.fn_wm_business_date()
returns date
language sql
stable
set search_path = ''
as $$
  select (timezone('Asia/Kuala_Lumpur', now()))::date;
$$;

create or replace function public.fn_wm_working_days_elapsed(start_date date, end_date date)
returns integer
language sql
immutable
set search_path = ''
as $$
  select count(*)::integer
  from generate_series(start_date + 1, end_date, interval '1 day') as day_value
  where extract(isodow from day_value) between 1 and 5;
$$;

create or replace function public.fn_wm_can_view_dashboard(subject_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and (
      public.fn_wm_role_of(subject_uid) in ('super_admin', 'management')
      or exists (
        select 1 from public.work_dashboard_access_grants grant_row
        where grant_row.profile_id = subject_uid
      )
    );
$$;

create or replace function public.fn_wm_supervisor_review_threshold()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select supervisor_review_working_days::integer
  from public.work_dashboard_settings
  where singleton = true;
$$;

create or replace function public.fn_wm_can_audit_dashboard_grants(subject_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and public.fn_wm_role_of(subject_uid) = 'super_admin';
$$;

create or replace function public.touch_work_task()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.row_version := old.row_version + 1;
  if new.status is distinct from old.status then
    new.status_changed_at := now();
  else
    new.status_changed_at := old.status_changed_at;
  end if;
  return new;
end;
$$;

alter table public.work_dashboard_settings enable row level security;
alter table public.work_dashboard_access_grants enable row level security;

create policy work_dashboard_settings_select on public.work_dashboard_settings
  for select to authenticated
  using (public.fn_wm_can_view_dashboard((select auth.uid())));

create policy work_dashboard_access_grants_select on public.work_dashboard_access_grants
  for select to authenticated
  using (
    profile_id = (select auth.uid())
    or public.fn_wm_can_audit_dashboard_grants((select auth.uid()))
  );

drop view public.work_task_attention;
create view public.work_task_attention
with (security_invoker = true)
as
select
  t.id,
  t.task_number,
  t.title,
  t.assigned_to,
  t.business_unit_id,
  t.department_id,
  t.project_reference,
  t.priority,
  t.status,
  t.progress_percent,
  t.current_blocker,
  t.due_date,
  t.output_required,
  t.task_sensitivity,
  t.last_activity_at,
  t.status_changed_at,
  coalesce(activity.activity_days, 0)::integer as meaningful_working_days,
  coalesce(artifacts.has_work_artifact, false) as has_work_artifact,
  coalesce(artifacts.has_completion_artifact, false) as has_completion_artifact,
  case
    when coalesce(artifacts.has_completion_artifact, false) then 'final_or_evidence'
    when coalesce(artifacts.has_work_artifact, false) then 'working'
    else 'none'
  end as artifact_indicator,
  case when t.status = 'waiting_feedback' then
    public.fn_wm_working_days_elapsed(
      (timezone('Asia/Kuala_Lumpur', t.status_changed_at))::date,
      (timezone('Asia/Kuala_Lumpur', now()))::date
    )
  else 0 end as supervisor_wait_working_days,
  case
    when t.due_date < public.fn_wm_business_date() and t.status not in ('completed', 'cancelled') then 1
    when coalesce(activity.activity_days, 0) >= 3
      and t.status not in ('completed', 'cancelled')
      and not coalesce(artifacts.has_completion_artifact, false) then 2
    when t.status = 'completed' and t.output_required
      and not coalesce(artifacts.has_completion_artifact, false) then 3
    when t.status = 'blocked' and nullif(btrim(t.current_blocker), '') is not null then 4
    when t.status = 'waiting_feedback' then 5
    when t.status = 'in_progress'
      and (timezone('Asia/Kuala_Lumpur', t.status_changed_at))::date
        <= public.fn_wm_previous_working_day(public.fn_wm_business_date())
      and not exists (
        select 1 from public.daily_work_updates previous_update
        where previous_update.task_id = t.id
          and previous_update.work_date = public.fn_wm_previous_working_day(public.fn_wm_business_date())
      ) then 6
    else null
  end::smallint as attention_rank,
  array_remove(array[
    case when t.due_date < public.fn_wm_business_date() and t.status not in ('completed', 'cancelled') then 'OVERDUE' end,
    case when coalesce(activity.activity_days, 0) >= 3
      and t.status not in ('completed', 'cancelled')
      and not coalesce(artifacts.has_completion_artifact, false) then 'STUCK' end,
    case when t.status = 'completed' and t.output_required
      and not coalesce(artifacts.has_completion_artifact, false) then 'COMPLETED MISSING EVIDENCE' end,
    case when t.status = 'blocked' and nullif(btrim(t.current_blocker), '') is not null then 'BLOCKED' end,
    case when t.status = 'waiting_feedback' then 'WAITING FEEDBACK' end,
    case when t.status = 'in_progress'
      and (timezone('Asia/Kuala_Lumpur', t.status_changed_at))::date
        <= public.fn_wm_previous_working_day(public.fn_wm_business_date())
      and not exists (
        select 1 from public.daily_work_updates previous_update
        where previous_update.task_id = t.id
          and previous_update.work_date = public.fn_wm_previous_working_day(public.fn_wm_business_date())
      ) then 'NO UPDATE PREVIOUS WORKDAY' end,
    case when t.status = 'waiting_feedback'
      and public.fn_wm_working_days_elapsed(
        (timezone('Asia/Kuala_Lumpur', t.status_changed_at))::date,
        (timezone('Asia/Kuala_Lumpur', now()))::date
      ) > public.fn_wm_supervisor_review_threshold()
      then 'SUPERVISOR BOTTLENECK' end
  ], null)::text[] as attention_flags
from public.work_tasks t
left join lateral (
  select count(distinct daily_update.work_date) as activity_days
  from public.daily_work_updates daily_update
  where daily_update.task_id = t.id
    and extract(isodow from daily_update.work_date) between 1 and 5
) activity on true
left join lateral (
  select
    count(*) > 0 as has_work_artifact,
    count(*) filter (where artifact.artifact_type in ('final', 'evidence')) > 0
      as has_completion_artifact
  from public.work_task_artifacts artifact
  where artifact.task_id = t.id
) artifacts on true;

create view public.work_dashboard_attention
with (security_invoker = true)
as
select attention.*
from public.work_task_attention attention
where public.fn_wm_can_view_dashboard((select auth.uid()));

create view public.work_dashboard_daily_updates
with (security_invoker = true)
as
select
  daily_update.id,
  daily_update.task_id,
  daily_update.staff_id,
  daily_update.work_date,
  daily_update.what_done_today,
  daily_update.quantity,
  daily_update.result_or_output,
  daily_update.deliverable_completed,
  daily_update.blocker_or_help,
  daily_update.created_at,
  task.task_number,
  task.title as task_title,
  task.business_unit_id,
  task.department_id,
  task.project_reference,
  task.status as task_status,
  exists (
    select 1 from public.work_task_artifacts artifact
    where artifact.id = daily_update.artifact_id
  ) as has_visible_artifact,
  not exists (
    select 1 from public.daily_update_reviews review
    where review.daily_update_id = daily_update.id
  ) as awaiting_supervisor_review
from public.daily_work_updates daily_update
join public.work_tasks task on task.id = daily_update.task_id
where public.fn_wm_can_view_dashboard((select auth.uid()));

create or replace function public.get_work_dashboard_team_workload(
  p_business_unit_id uuid default null,
  p_department_id uuid default null,
  p_assigned_to uuid default null,
  p_project_reference text default null,
  p_status text default null,
  p_attention_flag text default null,
  p_date_from date default null,
  p_date_to date default null
)
returns table (
  assigned_to uuid,
  active_tasks bigint,
  overdue_tasks bigint,
  stuck_tasks bigint,
  waiting_feedback bigint,
  completed_this_week bigint,
  updates_this_week bigint,
  workload_signal text
)
language sql
stable
security invoker
set search_path = ''
as $$
  with filtered_tasks as (
    select task.*, attention.attention_flags
    from public.work_tasks task
    join public.work_task_attention attention on attention.id = task.id
    where public.fn_wm_can_view_dashboard((select auth.uid()))
      and (p_business_unit_id is null or task.business_unit_id = p_business_unit_id)
      and (p_department_id is null or task.department_id = p_department_id)
      and (p_assigned_to is null or task.assigned_to = p_assigned_to)
      and (p_project_reference is null or task.project_reference = p_project_reference)
      and (p_status is null or task.status = p_status)
      and (p_attention_flag is null or p_attention_flag = any(attention.attention_flags))
      and (p_date_from is null or task.due_date >= p_date_from)
      and (p_date_to is null or task.due_date <= p_date_to)
  ),
  task_totals as (
    select
      task.assigned_to,
      count(*) filter (where task.status in ('not_started', 'in_progress', 'waiting_feedback', 'blocked')) as active_tasks,
      count(*) filter (where 'OVERDUE' = any(task.attention_flags)) as overdue_tasks,
      count(*) filter (where 'STUCK' = any(task.attention_flags)) as stuck_tasks,
      count(*) filter (where task.status = 'waiting_feedback') as waiting_feedback,
      count(*) filter (
        where task.status = 'completed'
          and task.completed_at >= date_trunc('week', timezone('Asia/Kuala_Lumpur', now()))
      ) as completed_this_week
    from filtered_tasks task
    group by task.assigned_to
  ),
  update_totals as (
    select task.assigned_to, count(daily_update.id) as updates_this_week
    from filtered_tasks task
    join public.daily_work_updates daily_update on daily_update.task_id = task.id
    where daily_update.work_date >= date_trunc('week', public.fn_wm_business_date()::timestamp)::date
    group by task.assigned_to
  )
  select
    task_totals.assigned_to,
    task_totals.active_tasks,
    task_totals.overdue_tasks,
    task_totals.stuck_tasks,
    task_totals.waiting_feedback,
    task_totals.completed_this_week,
    coalesce(update_totals.updates_this_week, 0)::bigint,
    case
      when task_totals.active_tasks >= settings.high_active_task_threshold then 'high_active_load'
      when task_totals.active_tasks <= settings.low_active_task_threshold then 'light_active_load'
      else 'balanced_active_load'
    end
  from task_totals
  cross join public.work_dashboard_settings settings
  left join update_totals using (assigned_to)
  where settings.singleton = true
  order by task_totals.active_tasks desc, task_totals.assigned_to;
$$;

create or replace function public.get_work_dashboard_missing_updates_today(
  p_business_unit_id uuid default null,
  p_department_id uuid default null,
  p_assigned_to uuid default null,
  p_project_reference text default null
)
returns table (assigned_to uuid, active_task_count bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  select task.assigned_to, count(*)::bigint
  from public.work_tasks task
  where public.fn_wm_can_view_dashboard((select auth.uid()))
    and task.status = 'in_progress'
    and (timezone('Asia/Kuala_Lumpur', task.status_changed_at))::date <= public.fn_wm_business_date()
    and (p_business_unit_id is null or task.business_unit_id = p_business_unit_id)
    and (p_department_id is null or task.department_id = p_department_id)
    and (p_assigned_to is null or task.assigned_to = p_assigned_to)
    and (p_project_reference is null or task.project_reference = p_project_reference)
    and not exists (
      select 1 from public.daily_work_updates daily_update
      where daily_update.task_id = task.id and daily_update.work_date = public.fn_wm_business_date()
    )
  group by task.assigned_to
  order by task.assigned_to;
$$;

create or replace function public.list_work_dashboard_projects()
returns table (project_reference text)
language sql
stable
security invoker
set search_path = ''
as $$
  select distinct task.project_reference
  from public.work_tasks task
  where public.fn_wm_can_view_dashboard((select auth.uid()))
    and task.project_reference is not null
    and nullif(btrim(task.project_reference), '') is not null
  order by task.project_reference;
$$;

create or replace function public.list_work_task_assignees()
returns table (profile_id uuid, full_name text, role text, department_id uuid)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if not public.fn_wm_can_view_dashboard(uid) then
    raise exception using errcode = '42501', message = 'Not authorised to list task assignees.';
  end if;

  return query
  select distinct profile.id, coalesce(profile.full_name, 'Unnamed user'), role_row.role, department_access.department_id
  from public.profiles profile
  join public.user_role_assignment role_row on role_row.profile_id = profile.id
  join public.user_department_access department_access on department_access.profile_id = profile.id
  join public.departments department on department.id = department_access.department_id
  where profile.is_active = true
    and (
      public.fn_wm_role_of(uid) = 'super_admin'
      or (
        public.fn_wm_role_of(uid) = 'management'
        and public.fn_wm_subject_has_business_unit_access(uid, department.business_unit_id)
        and public.fn_wm_subject_has_department_access(uid, department.id)
      )
      or profile.id = uid
    )
  order by coalesce(profile.full_name, 'Unnamed user'), department_access.department_id;
end;
$$;

revoke all on table public.work_dashboard_settings from public, anon, authenticated;
revoke all on table public.work_dashboard_access_grants from public, anon, authenticated;
revoke all on table public.work_task_attention from public, anon, authenticated;
revoke all on table public.work_dashboard_attention from public, anon, authenticated;
revoke all on table public.work_dashboard_daily_updates from public, anon, authenticated;

grant select on table public.work_dashboard_settings to authenticated;
grant select on table public.work_dashboard_access_grants to authenticated;
grant select on table public.work_task_attention to authenticated;
grant select on table public.work_dashboard_attention to authenticated;
grant select on table public.work_dashboard_daily_updates to authenticated;

revoke all on function public.fn_wm_previous_working_day(date) from public, anon, authenticated;
revoke all on function public.fn_wm_business_date() from public, anon, authenticated;
revoke all on function public.fn_wm_working_days_elapsed(date, date) from public, anon, authenticated;
revoke all on function public.fn_wm_can_view_dashboard(uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_supervisor_review_threshold() from public, anon, authenticated;
revoke all on function public.fn_wm_can_audit_dashboard_grants(uuid) from public, anon, authenticated;
revoke all on function public.get_work_dashboard_team_workload(uuid, uuid, uuid, text, text, text, date, date) from public, anon;
revoke all on function public.get_work_dashboard_missing_updates_today(uuid, uuid, uuid, text) from public, anon;
revoke all on function public.list_work_dashboard_projects() from public, anon;

grant execute on function public.fn_wm_previous_working_day(date) to authenticated;
grant execute on function public.fn_wm_business_date() to authenticated;
grant execute on function public.fn_wm_working_days_elapsed(date, date) to authenticated;
grant execute on function public.fn_wm_can_view_dashboard(uuid) to authenticated;
grant execute on function public.fn_wm_supervisor_review_threshold() to authenticated;
grant execute on function public.fn_wm_can_audit_dashboard_grants(uuid) to authenticated;
grant execute on function public.get_work_dashboard_team_workload(uuid, uuid, uuid, text, text, text, date, date) to authenticated;
grant execute on function public.get_work_dashboard_missing_updates_today(uuid, uuid, uuid, text) to authenticated;
grant execute on function public.list_work_dashboard_projects() to authenticated;
