-- IEOS Stage 2: Daily Output Log.
--
-- LOCAL / REVIEW ONLY. Do not apply to hosted Supabase without a separate
-- production-change approval and verified backup/restore procedure.

alter table public.work_tasks
  add column last_activity_at timestamptz;

create table public.daily_work_updates (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.work_tasks(id),
  staff_id uuid not null references public.profiles(id),
  work_date date not null default ((timezone('Asia/Kuala_Lumpur', now()))::date),
  what_done_today text not null check (char_length(btrim(what_done_today)) between 1 and 2000),
  quantity text check (quantity is null or char_length(btrim(quantity)) between 1 and 120),
  result_or_output text not null check (char_length(btrim(result_or_output)) between 1 and 2000),
  deliverable_completed boolean not null default false,
  artifact_id uuid references public.work_task_artifacts(id),
  blocker_or_help text check (blocker_or_help is null or char_length(btrim(blocker_or_help)) between 1 and 1000),
  created_at timestamptz not null default now(),
  check (deliverable_completed = false or artifact_id is not null)
);

create table public.daily_update_reviews (
  id uuid primary key default gen_random_uuid(),
  daily_update_id uuid not null references public.daily_work_updates(id),
  reviewer_id uuid not null references public.profiles(id),
  review_status text not null check (review_status in ('checked', 'correction_required', 'approved')),
  supervisor_comment text check (
    supervisor_comment is null or char_length(btrim(supervisor_comment)) between 1 and 2000
  ),
  created_at timestamptz not null default now(),
  check (review_status <> 'correction_required' or supervisor_comment is not null)
);

create index daily_work_updates_task_date_idx
  on public.daily_work_updates (task_id, work_date, created_at desc);
create index daily_work_updates_staff_date_idx
  on public.daily_work_updates (staff_id, work_date desc, created_at desc);
create index daily_update_reviews_update_created_idx
  on public.daily_update_reviews (daily_update_id, created_at desc);

create or replace function public.validate_daily_update_artifact_link()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.artifact_id is not null and not exists (
    select 1 from public.work_task_artifacts a
    where a.id = new.artifact_id and a.task_id = new.task_id
  ) then
    raise exception using errcode = '23514', message = 'Daily update artifact must belong to the linked task.';
  end if;
  return new;
end;
$$;

create or replace function public.prevent_daily_work_update_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = '42501', message = 'Daily work updates are immutable.';
end;
$$;

create or replace function public.prevent_daily_update_review_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = '42501', message = 'Daily update reviews are append-only.';
end;
$$;

create trigger prevent_daily_work_update_mutation
before update or delete on public.daily_work_updates
for each row execute function public.prevent_daily_work_update_mutation();

create trigger validate_daily_update_artifact_link
before insert on public.daily_work_updates
for each row execute function public.validate_daily_update_artifact_link();

create trigger prevent_daily_update_review_mutation
before update or delete on public.daily_update_reviews
for each row execute function public.prevent_daily_update_review_mutation();

alter table public.daily_work_updates enable row level security;
alter table public.daily_update_reviews enable row level security;

create policy daily_work_updates_select on public.daily_work_updates
  for select to authenticated
  using (public.fn_wm_can_view_task(auth.uid(), task_id));

create policy daily_update_reviews_select on public.daily_update_reviews
  for select to authenticated
  using (
    exists (
      select 1 from public.daily_work_updates u
      where u.id = daily_update_id
        and public.fn_wm_can_view_task(auth.uid(), u.task_id)
    )
  );

alter table public.work_task_events
  drop constraint work_task_events_event_type_check;
alter table public.work_task_events
  add constraint work_task_events_event_type_check check (
    event_type in (
      'task_created', 'management_updated', 'quick_updated',
      'artifact_added', 'comment_added', 'supervisor_reviewed',
      'access_granted', 'daily_update_added', 'daily_update_reviewed'
    )
  );

create or replace function public.submit_daily_work_update(
  p_task_id uuid,
  p_what_done_today text,
  p_quantity text,
  p_result_or_output text,
  p_deliverable_completed boolean,
  p_evidence_url text,
  p_blocker_or_help text,
  p_data_handling_confirmed boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target_task public.work_tasks%rowtype;
  new_artifact_id uuid;
  new_update_id uuid;
  cleaned_url text := nullif(btrim(p_evidence_url), '');
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that this update contains no sensitive personal data.';
  end if;
  if not public.fn_wm_can_update_task(uid, p_task_id)
    or not public.fn_wm_can_view_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to submit an update for this task.';
  end if;
  if nullif(btrim(p_what_done_today), '') is null
    or nullif(btrim(p_result_or_output), '') is null then
    raise exception using errcode = '22023', message = 'Work completed and result/output are required.';
  end if;
  if char_length(btrim(p_what_done_today)) > 2000
    or char_length(btrim(p_result_or_output)) > 2000
    or char_length(coalesce(btrim(p_quantity), '')) > 120
    or char_length(coalesce(btrim(p_blocker_or_help), '')) > 1000 then
    raise exception using errcode = '22023', message = 'Daily update text exceeds the permitted length.';
  end if;
  if coalesce(p_deliverable_completed, false) and cleaned_url is null then
    raise exception using errcode = '22023', message = 'Completed deliverables require an evidence link.';
  end if;
  if cleaned_url is not null
    and (cleaned_url !~* '^https?://[^[:space:]]+$' or char_length(cleaned_url) > 2048) then
    raise exception using errcode = '22023', message = 'A valid http/https evidence link is required.';
  end if;

  select * into strict target_task
  from public.work_tasks where id = p_task_id for update;

  if cleaned_url is not null then
    insert into public.work_task_artifacts (
      task_id, added_by, artifact_type, artifact_sensitivity, label, url
    ) values (
      p_task_id,
      uid,
      case when coalesce(p_deliverable_completed, false) then 'evidence' else 'working' end,
      target_task.task_sensitivity,
      case when coalesce(p_deliverable_completed, false) then 'Daily update evidence' else 'Daily update work link' end,
      cleaned_url
    ) returning id into new_artifact_id;
  end if;

  insert into public.daily_work_updates (
    task_id, staff_id, what_done_today, quantity, result_or_output,
    deliverable_completed, artifact_id, blocker_or_help
  ) values (
    p_task_id, uid, btrim(p_what_done_today), nullif(btrim(p_quantity), ''),
    btrim(p_result_or_output), coalesce(p_deliverable_completed, false),
    new_artifact_id, nullif(btrim(p_blocker_or_help), '')
  ) returning id into new_update_id;

  update public.work_tasks
  set last_activity_at = now(),
      current_blocker = case
        when nullif(btrim(p_blocker_or_help), '') is not null then btrim(p_blocker_or_help)
        else current_blocker
      end
  where id = p_task_id;

  if new_artifact_id is not null then
    insert into public.work_task_events (
      task_id, actor_id, event_type, metadata, counts_as_activity
    ) values (
      p_task_id, uid, 'artifact_added',
      jsonb_build_object(
        'artifact_id', new_artifact_id,
        'artifact_type', case when coalesce(p_deliverable_completed, false) then 'evidence' else 'working' end,
        'sensitivity', target_task.task_sensitivity
      ), false
    );
  end if;

  insert into public.work_task_events (
    task_id, actor_id, event_type, metadata, counts_as_activity
  ) values (
    p_task_id, uid, 'daily_update_added',
    jsonb_build_object(
      'daily_update_id', new_update_id,
      'work_date', (timezone('Asia/Kuala_Lumpur', now()))::date,
      'deliverable_completed', coalesce(p_deliverable_completed, false),
      'artifact_id', new_artifact_id
    ), true
  );

  return new_update_id;
end;
$$;

create or replace function public.review_daily_work_update(
  p_daily_update_id uuid,
  p_review_status text,
  p_supervisor_comment text,
  p_data_handling_confirmed boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target_update public.daily_work_updates%rowtype;
  new_review_id uuid;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that this review contains no sensitive personal data.';
  end if;
  select * into strict target_update
  from public.daily_work_updates where id = p_daily_update_id;
  if not public.fn_wm_can_manage_task(uid, target_update.task_id)
    or not public.fn_wm_can_view_task(uid, target_update.task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to review this daily update.';
  end if;
  if p_review_status not in ('checked', 'correction_required', 'approved') then
    raise exception using errcode = '22023', message = 'Invalid review status.';
  end if;
  if p_review_status = 'correction_required'
    and nullif(btrim(p_supervisor_comment), '') is null then
    raise exception using errcode = '22023', message = 'A correction comment is required.';
  end if;
  if char_length(coalesce(btrim(p_supervisor_comment), '')) > 2000 then
    raise exception using errcode = '22023', message = 'Supervisor comment exceeds the permitted length.';
  end if;

  insert into public.daily_update_reviews (
    daily_update_id, reviewer_id, review_status, supervisor_comment
  ) values (
    p_daily_update_id, uid, p_review_status, nullif(btrim(p_supervisor_comment), '')
  ) returning id into new_review_id;

  insert into public.work_task_events (task_id, actor_id, event_type, metadata)
  values (
    target_update.task_id, uid, 'daily_update_reviewed',
    jsonb_build_object(
      'daily_update_id', p_daily_update_id,
      'review_id', new_review_id,
      'review_status', p_review_status
    )
  );

  return new_review_id;
end;
$$;

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
  t.priority,
  t.status,
  t.progress_percent,
  t.current_blocker,
  t.due_date,
  t.output_required,
  t.task_sensitivity,
  coalesce(activity.activity_days, 0)::integer as meaningful_working_days,
  array_remove(array[
    case when t.due_date < current_date and t.status not in ('completed', 'cancelled') then 'OVERDUE' end,
    case when coalesce(activity.activity_days, 0) >= 3
      and t.status not in ('completed', 'cancelled')
      and not public.fn_wm_task_has_completion_artifact(t.id) then 'STUCK' end,
    case when t.status = 'completed' and t.output_required = true
      and not public.fn_wm_task_has_completion_artifact(t.id) then 'COMPLETED MISSING EVIDENCE' end,
    case when t.status = 'waiting_feedback' then 'WAITING FEEDBACK' end,
    case when t.status = 'blocked' and nullif(btrim(t.current_blocker), '') is not null then 'BLOCKED' end
  ], null)::text[] as attention_flags
from public.work_tasks t
left join lateral (
  select count(distinct u.work_date) as activity_days
  from public.daily_work_updates u
  where u.task_id = t.id
    and extract(isodow from u.work_date) between 1 and 5
) activity on true;

revoke all on table public.daily_work_updates from public, anon, authenticated;
revoke all on table public.daily_update_reviews from public, anon, authenticated;
revoke all on table public.work_task_attention from public, anon, authenticated;
revoke all on function public.prevent_daily_work_update_mutation() from public, anon, authenticated;
revoke all on function public.prevent_daily_update_review_mutation() from public, anon, authenticated;
revoke all on function public.validate_daily_update_artifact_link() from public, anon, authenticated;
revoke all on function public.submit_daily_work_update(uuid, text, text, text, boolean, text, text, boolean) from public, anon;
revoke all on function public.review_daily_work_update(uuid, text, text, boolean) from public, anon;

grant select on table public.daily_work_updates to authenticated;
grant select on table public.daily_update_reviews to authenticated;
grant select on table public.work_task_attention to authenticated;
grant execute on function public.submit_daily_work_update(uuid, text, text, text, boolean, text, text, boolean) to authenticated;
grant execute on function public.review_daily_work_update(uuid, text, text, boolean) to authenticated;
