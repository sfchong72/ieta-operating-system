-- IEOS Stage 1: generic work-management foundation.
--
-- LOCAL / REVIEW ONLY. Do not apply to hosted Supabase without a separate
-- production-change approval and verified backup/restore procedure.
--
-- This migration is additive. It does not rename, repurpose, migrate, or
-- delete content_tasks, content_items, activities, work_files, or their data.

alter table public.profiles
  add column if not exists is_active boolean not null default true;

create sequence public.work_task_number_seq;

create table public.work_tasks (
  id uuid primary key default gen_random_uuid(),
  task_number text not null unique,
  business_unit_id uuid not null references public.business_units(id),
  department_id uuid not null references public.departments(id),
  assigned_to uuid not null references public.profiles(id),
  assigned_by uuid not null references public.profiles(id),
  created_by uuid not null references public.profiles(id),
  project_reference text,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  instructions text not null check (char_length(btrim(instructions)) between 1 and 4000),
  expected_final_output text check (
    expected_final_output is null
    or char_length(btrim(expected_final_output)) between 1 and 1000
  ),
  output_required boolean not null default true,
  priority text not null default 'medium' check (
    priority in ('urgent', 'high', 'medium', 'low')
  ),
  status text not null default 'not_started' check (
    status in (
      'backlog', 'not_started', 'in_progress', 'waiting_feedback',
      'blocked', 'on_hold', 'completed', 'cancelled'
    )
  ),
  progress_percent smallint not null default 0 check (
    progress_percent between 0 and 100
  ),
  current_blocker text check (
    current_blocker is null or char_length(btrim(current_blocker)) between 1 and 1000
  ),
  next_action text check (
    next_action is null or char_length(btrim(next_action)) between 1 and 1000
  ),
  task_sensitivity text not null default 'operational' check (
    task_sensitivity in (
      'operational', 'appointed_personnel', 'full_time_only',
      'management_only', 'pc_restricted'
    )
  ),
  due_date date,
  completed_at timestamptz,
  output_waived boolean not null default false,
  output_waiver_reason text check (
    output_waiver_reason is null
    or char_length(btrim(output_waiver_reason)) between 1 and 1000
  ),
  output_waived_by uuid references public.profiles(id),
  output_waived_at timestamptz,
  final_approved_by uuid references public.profiles(id),
  final_approved_at timestamptz,
  row_version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (output_waived = false and output_waiver_reason is null and output_waived_by is null and output_waived_at is null)
    or
    (output_waived = true and output_required = false and output_waiver_reason is not null and output_waived_by is not null and output_waived_at is not null)
  ),
  check (
    (status = 'completed' and completed_at is not null and progress_percent = 100)
    or
    (status <> 'completed' and completed_at is null)
  )
);

create table public.work_task_updates (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.work_tasks(id) on delete cascade,
  created_by uuid not null references public.profiles(id),
  status text not null check (
    status in (
      'backlog', 'not_started', 'in_progress', 'waiting_feedback',
      'blocked', 'on_hold', 'completed', 'cancelled'
    )
  ),
  progress_percent smallint not null check (progress_percent between 0 and 100),
  blocker_or_help text check (
    blocker_or_help is null or char_length(btrim(blocker_or_help)) between 1 and 1000
  ),
  is_meaningful boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.work_task_comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.work_tasks(id) on delete cascade,
  author_id uuid not null references public.profiles(id),
  comment_kind text not null default 'comment' check (
    comment_kind in ('comment', 'supervisor_feedback')
  ),
  audience text not null default 'participants' check (
    audience in ('participants', 'management_only')
  ),
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table public.work_task_artifacts (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.work_tasks(id) on delete cascade,
  added_by uuid not null references public.profiles(id),
  artifact_type text not null check (
    artifact_type in ('working', 'final', 'evidence', 'reference')
  ),
  artifact_sensitivity text not null default 'operational' check (
    artifact_sensitivity in (
      'operational', 'appointed_personnel', 'full_time_only',
      'management_only', 'pc_restricted'
    )
  ),
  label text check (label is null or char_length(btrim(label)) between 1 and 160),
  url text not null check (
    char_length(url) <= 2048 and url ~* '^https?://[^[:space:]]+$'
  ),
  created_at timestamptz not null default now()
);

create table public.work_task_access_grants (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.work_tasks(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  grant_type text not null check (grant_type in ('task_view', 'pc_restricted')),
  granted_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (task_id, profile_id, grant_type)
);

create table public.work_task_events (
  id bigint generated always as identity primary key,
  task_id uuid not null references public.work_tasks(id) on delete cascade,
  actor_id uuid not null references public.profiles(id),
  event_type text not null check (
    event_type in (
      'task_created', 'management_updated', 'quick_updated',
      'artifact_added', 'comment_added', 'supervisor_reviewed',
      'access_granted'
    )
  ),
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  counts_as_activity boolean not null default false,
  created_at timestamptz not null default now()
);

create index work_tasks_assigned_to_idx on public.work_tasks (assigned_to, status);
create index work_tasks_scope_idx on public.work_tasks (business_unit_id, department_id, status);
create index work_tasks_due_idx on public.work_tasks (due_date) where due_date is not null;
create index work_task_updates_task_created_idx on public.work_task_updates (task_id, created_at desc);
create index work_task_comments_task_created_idx on public.work_task_comments (task_id, created_at desc);
create index work_task_artifacts_task_created_idx on public.work_task_artifacts (task_id, created_at desc);
create index work_task_events_task_created_idx on public.work_task_events (task_id, created_at desc);
create index work_task_events_meaningful_idx on public.work_task_events (task_id, created_at)
  where counts_as_activity = true;

create or replace function public.fn_wm_role_of(subject_uid uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case when count(*) = 1 then min(ura.role) end
  from public.user_role_assignment ura
  where ura.profile_id = subject_uid;
$$;

create or replace function public.fn_wm_is_active(subject_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = subject_uid and p.is_active = true
  );
$$;

create or replace function public.fn_wm_subject_has_business_unit_access(subject_uid uuid, target_bu uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.fn_wm_is_active(subject_uid)
    and (
      public.fn_wm_role_of(subject_uid) = 'super_admin'
      or exists (
        select 1 from public.user_business_unit_access uba
        where uba.profile_id = subject_uid and uba.business_unit_id = target_bu
      )
    );
$$;

create or replace function public.fn_wm_subject_has_department_access(subject_uid uuid, target_department uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.fn_wm_is_active(subject_uid)
    and (
      public.fn_wm_role_of(subject_uid) = 'super_admin'
      or (
        public.fn_wm_role_of(subject_uid) = 'management'
        and exists (
          select 1 from public.departments d
          where d.id = target_department
            and public.fn_wm_subject_has_business_unit_access(subject_uid, d.business_unit_id)
        )
      )
      or (
        public.fn_wm_role_of(subject_uid) in ('staff', 'intern')
        and exists (
          select 1 from public.user_department_access uda
          where uda.profile_id = subject_uid and uda.department_id = target_department
        )
      )
    );
$$;

create or replace function public.fn_wm_has_grant(subject_uid uuid, target_task uuid, requested_grant text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.work_task_access_grants g
    where g.task_id = target_task
      and g.profile_id = subject_uid
      and g.grant_type = requested_grant
  );
$$;

create or replace function public.fn_wm_can_manage_task(subject_uid uuid, target_task uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and exists (
      select 1 from public.work_tasks t
      where t.id = target_task
        and (
          public.fn_wm_role_of(subject_uid) = 'super_admin'
          or (
            public.fn_wm_role_of(subject_uid) = 'management'
            and public.fn_wm_subject_has_business_unit_access(subject_uid, t.business_unit_id)
            and public.fn_wm_subject_has_department_access(subject_uid, t.department_id)
          )
        )
    );
$$;

create or replace function public.fn_wm_can_view_task(subject_uid uuid, target_task uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and exists (
      select 1 from public.work_tasks t
      where t.id = target_task
        and case t.task_sensitivity
          when 'pc_restricted' then
            public.fn_wm_role_of(subject_uid) = 'super_admin'
            or public.fn_wm_has_grant(subject_uid, t.id, 'pc_restricted')
          when 'management_only' then
            public.fn_wm_can_manage_task(subject_uid, t.id)
          when 'full_time_only' then
            public.fn_wm_role_of(subject_uid) in ('super_admin', 'management')
            and public.fn_wm_can_manage_task(subject_uid, t.id)
            or (
              public.fn_wm_role_of(subject_uid) = 'staff'
              and t.assigned_to = subject_uid
              and public.fn_wm_subject_has_department_access(subject_uid, t.department_id)
            )
          when 'appointed_personnel' then
            public.fn_wm_can_manage_task(subject_uid, t.id)
            or (
              t.assigned_to = subject_uid
              and public.fn_wm_subject_has_department_access(subject_uid, t.department_id)
            )
            or public.fn_wm_has_grant(subject_uid, t.id, 'task_view')
          else
            public.fn_wm_can_manage_task(subject_uid, t.id)
            or (
              t.assigned_to = subject_uid
              and public.fn_wm_subject_has_department_access(subject_uid, t.department_id)
            )
            or public.fn_wm_has_grant(subject_uid, t.id, 'task_view')
        end
    );
$$;

create or replace function public.fn_wm_can_update_task(subject_uid uuid, target_task uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.fn_wm_can_manage_task(subject_uid, target_task)
    or exists (
      select 1 from public.work_tasks t
      where t.id = target_task
        and t.assigned_to = subject_uid
        and public.fn_wm_can_view_task(subject_uid, target_task)
        and public.fn_wm_role_of(subject_uid) in ('staff', 'intern')
    );
$$;

create or replace function public.fn_wm_can_view_artifact(subject_uid uuid, target_artifact uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.work_task_artifacts a
    join public.work_tasks t on t.id = a.task_id
    where a.id = target_artifact
      and public.fn_wm_can_view_task(subject_uid, t.id)
      and case a.artifact_sensitivity
        when 'pc_restricted' then
          public.fn_wm_role_of(subject_uid) = 'super_admin'
          or public.fn_wm_has_grant(subject_uid, t.id, 'pc_restricted')
        when 'management_only' then public.fn_wm_can_manage_task(subject_uid, t.id)
        when 'full_time_only' then public.fn_wm_role_of(subject_uid) in ('super_admin', 'management', 'staff')
        when 'appointed_personnel' then
          public.fn_wm_can_manage_task(subject_uid, t.id)
          or t.assigned_to = subject_uid
          or a.added_by = subject_uid
          or public.fn_wm_has_grant(subject_uid, t.id, 'task_view')
        else true
      end
  );
$$;

create or replace function public.fn_wm_task_has_completion_artifact(target_task uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.fn_wm_can_view_task(auth.uid(), target_task)
    and exists (
    select 1 from public.work_task_artifacts a
    where a.task_id = target_task and a.artifact_type in ('final', 'evidence')
  );
$$;

create or replace function public.fn_wm_next_task_number()
returns text
language sql
volatile
security definer
set search_path = ''
as $$
  select 'TASK-' || to_char(current_date, 'YYMM') ||
    lpad(nextval('public.work_task_number_seq')::text, 4, '0');
$$;

alter table public.work_tasks
  alter column task_number set default public.fn_wm_next_task_number();

create or replace function public.validate_work_task_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.departments d
    where d.id = new.department_id and d.business_unit_id = new.business_unit_id
  ) then
    raise exception using errcode = '23514', message = 'Department does not belong to the selected business unit.';
  end if;

  if not public.fn_wm_is_active(new.assigned_to)
    or not public.fn_wm_subject_has_department_access(new.assigned_to, new.department_id) then
    raise exception using errcode = '23514', message = 'Assignee is inactive or outside the selected department.';
  end if;

  return new;
end;
$$;

create or replace function public.guard_work_task_completion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  has_evidence boolean;
begin
  if new.status = 'completed' then
    select exists (
      select 1 from public.work_task_artifacts a
      where a.task_id = new.id and a.artifact_type in ('final', 'evidence')
    ) into has_evidence;

    if not has_evidence and not (
      new.output_required = false
      and new.output_waived = true
      and new.output_waiver_reason is not null
      and new.output_waived_by is not null
      and new.output_waived_at is not null
    ) then
      raise exception using errcode = '23514', message = 'Completion requires final evidence or a manager-approved no-output waiver.';
    end if;
  end if;

  return new;
end;
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
  return new;
end;
$$;

create or replace function public.prevent_work_task_event_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = '42501', message = 'Work-task audit events are immutable.';
end;
$$;

create trigger validate_work_task_scope
before insert or update on public.work_tasks
for each row execute function public.validate_work_task_scope();

create trigger guard_work_task_completion
before insert or update on public.work_tasks
for each row execute function public.guard_work_task_completion();

create trigger touch_work_task
before update on public.work_tasks
for each row execute function public.touch_work_task();

create trigger prevent_work_task_event_mutation
before update or delete on public.work_task_events
for each row execute function public.prevent_work_task_event_mutation();

alter table public.work_tasks enable row level security;
alter table public.work_task_updates enable row level security;
alter table public.work_task_comments enable row level security;
alter table public.work_task_artifacts enable row level security;
alter table public.work_task_access_grants enable row level security;
alter table public.work_task_events enable row level security;

create policy work_tasks_select on public.work_tasks
  for select to authenticated
  using (public.fn_wm_can_view_task(auth.uid(), id));

create policy work_task_updates_select on public.work_task_updates
  for select to authenticated
  using (public.fn_wm_can_view_task(auth.uid(), task_id));

create policy work_task_comments_select on public.work_task_comments
  for select to authenticated
  using (
    public.fn_wm_can_view_task(auth.uid(), task_id)
    and (audience = 'participants' or public.fn_wm_can_manage_task(auth.uid(), task_id))
  );

create policy work_task_artifacts_select on public.work_task_artifacts
  for select to authenticated
  using (public.fn_wm_can_view_artifact(auth.uid(), id));

create policy work_task_access_grants_select on public.work_task_access_grants
  for select to authenticated
  using (
    profile_id = auth.uid()
    or public.fn_wm_can_manage_task(auth.uid(), task_id)
  );

create policy work_task_events_select on public.work_task_events
  for select to authenticated
  using (
    public.fn_wm_can_manage_task(auth.uid(), task_id)
    or (
      public.fn_wm_can_view_task(auth.uid(), task_id)
      and event_type <> 'artifact_added'
    )
    or (
      event_type = 'artifact_added'
      and public.fn_wm_can_view_artifact(auth.uid(), (metadata ->> 'artifact_id')::uuid)
    )
  );

create or replace function public.create_work_task(
  p_business_unit_id uuid,
  p_department_id uuid,
  p_assigned_to uuid,
  p_project_reference text,
  p_title text,
  p_instructions text,
  p_expected_final_output text,
  p_output_required boolean,
  p_due_date date,
  p_priority text,
  p_initial_status text,
  p_task_sensitivity text,
  p_data_handling_confirmed boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  created_task public.work_tasks%rowtype;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that generic task text contains no sensitive personal data.';
  end if;
  if not public.fn_wm_is_active(uid)
    or public.fn_wm_role_of(uid) not in ('super_admin', 'management') then
    raise exception using errcode = '42501', message = 'Only an authorised manager can create tasks.';
  end if;
  if public.fn_wm_role_of(uid) = 'management' and not (
    public.fn_wm_subject_has_business_unit_access(uid, p_business_unit_id)
    and public.fn_wm_subject_has_department_access(uid, p_department_id)
  ) then
    raise exception using errcode = '42501', message = 'Selected scope is outside your access.';
  end if;
  if p_task_sensitivity = 'pc_restricted' and public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can create a P&C-restricted task.';
  end if;
  if p_initial_status not in ('backlog', 'not_started') then
    raise exception using errcode = '22023', message = 'New tasks must start as backlog or not started.';
  end if;

  insert into public.work_tasks (
    business_unit_id, department_id, assigned_to, assigned_by, created_by,
    project_reference, title, instructions, expected_final_output,
    output_required, due_date, priority, status, task_sensitivity
  ) values (
    p_business_unit_id, p_department_id, p_assigned_to, uid, uid,
    nullif(btrim(p_project_reference), ''), btrim(p_title), btrim(p_instructions),
    nullif(btrim(p_expected_final_output), ''), coalesce(p_output_required, true),
    p_due_date, p_priority, p_initial_status, p_task_sensitivity
  ) returning * into created_task;

  insert into public.work_task_events (task_id, actor_id, event_type, metadata)
  values (
    created_task.id, uid, 'task_created',
    jsonb_build_object('task_number', created_task.task_number)
  );

  return created_task.id;
end;
$$;

create or replace function public.update_work_task_management(
  p_task_id uuid,
  p_business_unit_id uuid,
  p_department_id uuid,
  p_assigned_to uuid,
  p_project_reference text,
  p_title text,
  p_instructions text,
  p_expected_final_output text,
  p_output_required boolean,
  p_due_date date,
  p_priority text,
  p_task_sensitivity text,
  p_data_handling_confirmed boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  before_task public.work_tasks%rowtype;
  changed_fields text[];
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that generic task text contains no sensitive personal data.';
  end if;
  if not public.fn_wm_can_manage_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to edit task management fields.';
  end if;
  if public.fn_wm_role_of(uid) = 'management' and not (
    public.fn_wm_subject_has_business_unit_access(uid, p_business_unit_id)
    and public.fn_wm_subject_has_department_access(uid, p_department_id)
  ) then
    raise exception using errcode = '42501', message = 'Selected scope is outside your access.';
  end if;

  select * into strict before_task from public.work_tasks where id = p_task_id for update;

  if p_task_sensitivity = 'pc_restricted'
    and before_task.task_sensitivity <> 'pc_restricted'
    and public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can classify a task as P&C restricted.';
  end if;

  changed_fields := array_remove(array[
    case when before_task.business_unit_id is distinct from p_business_unit_id then 'business_unit_id' end,
    case when before_task.department_id is distinct from p_department_id then 'department_id' end,
    case when before_task.assigned_to is distinct from p_assigned_to then 'assigned_to' end,
    case when before_task.project_reference is distinct from nullif(btrim(p_project_reference), '') then 'project_reference' end,
    case when before_task.title is distinct from btrim(p_title) then 'title' end,
    case when before_task.instructions is distinct from btrim(p_instructions) then 'instructions' end,
    case when before_task.expected_final_output is distinct from nullif(btrim(p_expected_final_output), '') then 'expected_final_output' end,
    case when before_task.output_required is distinct from p_output_required then 'output_required' end,
    case when before_task.due_date is distinct from p_due_date then 'due_date' end,
    case when before_task.priority is distinct from p_priority then 'priority' end,
    case when before_task.task_sensitivity is distinct from p_task_sensitivity then 'task_sensitivity' end
  ], null);

  update public.work_tasks
  set business_unit_id = p_business_unit_id,
      department_id = p_department_id,
      assigned_to = p_assigned_to,
      project_reference = nullif(btrim(p_project_reference), ''),
      title = btrim(p_title),
      instructions = btrim(p_instructions),
      expected_final_output = nullif(btrim(p_expected_final_output), ''),
      output_required = p_output_required,
      due_date = p_due_date,
      priority = p_priority,
      task_sensitivity = p_task_sensitivity
  where id = p_task_id;

  if cardinality(changed_fields) > 0 then
    insert into public.work_task_events (task_id, actor_id, event_type, metadata)
    values (p_task_id, uid, 'management_updated', jsonb_build_object('fields', to_jsonb(changed_fields)));
  end if;
end;
$$;

create or replace function public.quick_update_work_task(
  p_task_id uuid,
  p_status text,
  p_progress_percent integer,
  p_blocker_or_help text,
  p_data_handling_confirmed boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  before_task public.work_tasks%rowtype;
  meaningful boolean;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that this update contains no sensitive personal data.';
  end if;
  if not public.fn_wm_can_update_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to update this task.';
  end if;
  if p_status not in (
    'backlog', 'not_started', 'in_progress', 'waiting_feedback',
    'blocked', 'on_hold', 'completed', 'cancelled'
  ) then
    raise exception using errcode = '22023', message = 'Invalid task status.';
  end if;
  if p_progress_percent < 0 or p_progress_percent > 100 then
    raise exception using errcode = '22023', message = 'Progress must be between 0 and 100.';
  end if;
  if p_status = 'blocked' and nullif(btrim(p_blocker_or_help), '') is null then
    raise exception using errcode = '22023', message = 'Blocked tasks require current blocker information.';
  end if;

  select * into strict before_task from public.work_tasks where id = p_task_id for update;
  meaningful := before_task.status is distinct from p_status
    or before_task.progress_percent is distinct from p_progress_percent
    or before_task.current_blocker is distinct from nullif(btrim(p_blocker_or_help), '');

  update public.work_tasks
  set status = p_status,
      progress_percent = case when p_status = 'completed' then 100 else p_progress_percent end,
      current_blocker = nullif(btrim(p_blocker_or_help), ''),
      completed_at = case when p_status = 'completed' then now() else null end
  where id = p_task_id;

  insert into public.work_task_updates (
    task_id, created_by, status, progress_percent, blocker_or_help, is_meaningful
  ) values (
    p_task_id, uid, p_status,
    case when p_status = 'completed' then 100 else p_progress_percent end,
    nullif(btrim(p_blocker_or_help), ''), meaningful
  );

  insert into public.work_task_events (
    task_id, actor_id, event_type, metadata, counts_as_activity
  ) values (
    p_task_id, uid, 'quick_updated',
    jsonb_build_object(
      'status', p_status,
      'progress_percent', case when p_status = 'completed' then 100 else p_progress_percent end,
      'blocker_present', nullif(btrim(p_blocker_or_help), '') is not null
    ),
    meaningful
  );
end;
$$;

create or replace function public.add_work_task_artifact(
  p_task_id uuid,
  p_artifact_type text,
  p_label text,
  p_url text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  artifact_id uuid;
begin
  if not public.fn_wm_can_update_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to add an artifact to this task.';
  end if;
  if p_artifact_type not in ('working', 'final', 'evidence', 'reference') then
    raise exception using errcode = '22023', message = 'Invalid artifact type.';
  end if;
  if p_url is null or p_url !~* '^https?://[^[:space:]]+$' or char_length(p_url) > 2048 then
    raise exception using errcode = '22023', message = 'A valid http/https link is required.';
  end if;

  insert into public.work_task_artifacts (
    task_id, added_by, artifact_type, artifact_sensitivity, label, url
  ) values (
    p_task_id, uid, p_artifact_type, 'operational', nullif(btrim(p_label), ''), p_url
  ) returning id into artifact_id;

  insert into public.work_task_events (
    task_id, actor_id, event_type, metadata, counts_as_activity
  ) values (
    p_task_id, uid, 'artifact_added',
    jsonb_build_object('artifact_id', artifact_id, 'artifact_type', p_artifact_type, 'sensitivity', 'operational'),
    true
  );

  return artifact_id;
end;
$$;

create or replace function public.add_managed_work_task_artifact(
  p_task_id uuid,
  p_artifact_type text,
  p_artifact_sensitivity text,
  p_label text,
  p_url text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  artifact_id uuid;
begin
  if not public.fn_wm_can_manage_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to add a managed artifact.';
  end if;
  if p_artifact_type not in ('working', 'final', 'evidence', 'reference') then
    raise exception using errcode = '22023', message = 'Invalid artifact type.';
  end if;
  if p_artifact_sensitivity not in (
    'operational', 'appointed_personnel', 'full_time_only',
    'management_only', 'pc_restricted'
  ) then
    raise exception using errcode = '22023', message = 'Invalid artifact sensitivity.';
  end if;
  if p_artifact_sensitivity = 'pc_restricted'
    and public.fn_wm_role_of(uid) <> 'super_admin'
    and not public.fn_wm_has_grant(uid, p_task_id, 'pc_restricted') then
    raise exception using errcode = '42501', message = 'P&C artifact access is required before adding this link.';
  end if;
  if p_url is null or p_url !~* '^https?://[^[:space:]]+$' or char_length(p_url) > 2048 then
    raise exception using errcode = '22023', message = 'A valid http/https link is required.';
  end if;

  insert into public.work_task_artifacts (
    task_id, added_by, artifact_type, artifact_sensitivity, label, url
  ) values (
    p_task_id, uid, p_artifact_type, p_artifact_sensitivity,
    nullif(btrim(p_label), ''), p_url
  ) returning id into artifact_id;

  insert into public.work_task_events (
    task_id, actor_id, event_type, metadata, counts_as_activity
  ) values (
    p_task_id, uid, 'artifact_added',
    jsonb_build_object('artifact_id', artifact_id, 'artifact_type', p_artifact_type, 'sensitivity', p_artifact_sensitivity),
    true
  );

  return artifact_id;
end;
$$;

create or replace function public.add_work_task_comment(
  p_task_id uuid,
  p_body text,
  p_data_handling_confirmed boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  comment_id uuid;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that this comment contains no sensitive personal data.';
  end if;
  if not public.fn_wm_can_update_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to comment on this task.';
  end if;
  if nullif(btrim(p_body), '') is null then
    raise exception using errcode = '22023', message = 'Comment cannot be empty.';
  end if;

  insert into public.work_task_comments (task_id, author_id, body)
  values (p_task_id, uid, btrim(p_body)) returning id into comment_id;

  insert into public.work_task_events (task_id, actor_id, event_type, metadata)
  values (p_task_id, uid, 'comment_added', jsonb_build_object('comment_id', comment_id));

  return comment_id;
end;
$$;

create or replace function public.supervise_work_task(
  p_task_id uuid,
  p_feedback text,
  p_next_action text,
  p_approve_final boolean,
  p_waive_output boolean,
  p_waiver_reason text,
  p_complete_task boolean,
  p_feedback_management_only boolean,
  p_data_handling_confirmed boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target_task public.work_tasks%rowtype;
  has_evidence boolean;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that supervisor text contains no sensitive personal data.';
  end if;
  if not public.fn_wm_can_manage_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to supervise this task.';
  end if;

  select * into strict target_task from public.work_tasks where id = p_task_id for update;
  select exists (
    select 1 from public.work_task_artifacts a
    where a.task_id = p_task_id
      and a.artifact_type in ('final', 'evidence')
      and public.fn_wm_can_view_artifact(uid, a.id)
  ) into has_evidence;

  if p_waive_output and target_task.output_required then
    raise exception using errcode = '22023', message = 'Mark output as not required before approving a waiver.';
  end if;
  if p_waive_output and nullif(btrim(p_waiver_reason), '') is null then
    raise exception using errcode = '22023', message = 'A waiver reason is required.';
  end if;
  if p_approve_final and not has_evidence and not p_waive_output and not target_task.output_waived then
    raise exception using errcode = '22023', message = 'Final approval requires final evidence or an approved waiver.';
  end if;

  if nullif(btrim(p_feedback), '') is not null then
    insert into public.work_task_comments (
      task_id, author_id, comment_kind, audience, body
    ) values (
      p_task_id, uid, 'supervisor_feedback',
      case when p_feedback_management_only then 'management_only' else 'participants' end,
      btrim(p_feedback)
    );
  end if;

  update public.work_tasks
  set next_action = nullif(btrim(p_next_action), ''),
      output_waived = case when p_waive_output then true else output_waived end,
      output_waiver_reason = case when p_waive_output then btrim(p_waiver_reason) else output_waiver_reason end,
      output_waived_by = case when p_waive_output then uid else output_waived_by end,
      output_waived_at = case when p_waive_output then now() else output_waived_at end,
      final_approved_by = case when p_approve_final then uid else final_approved_by end,
      final_approved_at = case when p_approve_final then now() else final_approved_at end,
      status = case when p_complete_task then 'completed' else status end,
      progress_percent = case when p_complete_task then 100 else progress_percent end,
      completed_at = case when p_complete_task then now() else completed_at end
  where id = p_task_id;

  insert into public.work_task_events (task_id, actor_id, event_type, metadata)
  values (
    p_task_id, uid, 'supervisor_reviewed',
    jsonb_build_object(
      'feedback_added', nullif(btrim(p_feedback), '') is not null,
      'next_action_set', nullif(btrim(p_next_action), '') is not null,
      'final_approved', p_approve_final,
      'output_waived', p_waive_output,
      'completed', p_complete_task
    )
  );
end;
$$;

create or replace function public.grant_work_task_access(
  p_task_id uuid,
  p_profile_id uuid,
  p_grant_type text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if not public.fn_wm_can_manage_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to grant task access.';
  end if;
  if p_grant_type not in ('task_view', 'pc_restricted') then
    raise exception using errcode = '22023', message = 'Invalid task grant type.';
  end if;
  if p_grant_type = 'pc_restricted' and public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can grant P&C access.';
  end if;
  if not public.fn_wm_is_active(p_profile_id) then
    raise exception using errcode = '22023', message = 'Access can only be granted to an active profile.';
  end if;

  insert into public.work_task_access_grants (task_id, profile_id, grant_type, granted_by)
  values (p_task_id, p_profile_id, p_grant_type, uid)
  on conflict (task_id, profile_id, grant_type) do nothing;

  insert into public.work_task_events (task_id, actor_id, event_type, metadata)
  values (
    p_task_id, uid, 'access_granted',
    jsonb_build_object('profile_id', p_profile_id, 'grant_type', p_grant_type)
  );
end;
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
  if not public.fn_wm_is_active(uid)
    or public.fn_wm_role_of(uid) not in ('super_admin', 'management') then
    raise exception using errcode = '42501', message = 'Not authorised to list task assignees.';
  end if;

  return query
  select distinct p.id, coalesce(p.full_name, 'Unnamed user'), ura.role, uda.department_id
  from public.profiles p
  join public.user_role_assignment ura on ura.profile_id = p.id
  join public.user_department_access uda on uda.profile_id = p.id
  join public.departments d on d.id = uda.department_id
  where p.is_active = true
    and (
      public.fn_wm_role_of(uid) = 'super_admin'
      or (
        public.fn_wm_subject_has_business_unit_access(uid, d.business_unit_id)
        and public.fn_wm_subject_has_department_access(uid, d.id)
      )
    )
  order by coalesce(p.full_name, 'Unnamed user'), uda.department_id;
end;
$$;

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
  select count(distinct (e.created_at at time zone 'Asia/Kuala_Lumpur')::date) as activity_days
  from public.work_task_events e
  where e.task_id = t.id
    and e.counts_as_activity = true
    and extract(isodow from e.created_at at time zone 'Asia/Kuala_Lumpur') between 1 and 5
) activity on true;

revoke all on table public.work_tasks from public, anon, authenticated;
revoke all on table public.work_task_updates from public, anon, authenticated;
revoke all on table public.work_task_comments from public, anon, authenticated;
revoke all on table public.work_task_artifacts from public, anon, authenticated;
revoke all on table public.work_task_access_grants from public, anon, authenticated;
revoke all on table public.work_task_events from public, anon, authenticated;
revoke all on table public.work_task_attention from public, anon, authenticated;
revoke all on sequence public.work_task_number_seq from public, anon, authenticated;
revoke all on sequence public.work_task_events_id_seq from public, anon, authenticated;

grant select on table public.work_tasks to authenticated;
grant select on table public.work_task_updates to authenticated;
grant select on table public.work_task_comments to authenticated;
grant select on table public.work_task_artifacts to authenticated;
grant select on table public.work_task_access_grants to authenticated;
grant select on table public.work_task_events to authenticated;
grant select on table public.work_task_attention to authenticated;

revoke all on function public.fn_wm_role_of(uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_is_active(uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_subject_has_business_unit_access(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_subject_has_department_access(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_has_grant(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.fn_wm_can_manage_task(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_can_view_task(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_can_update_task(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_can_view_artifact(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_task_has_completion_artifact(uuid) from public, anon, authenticated;
revoke all on function public.fn_wm_next_task_number() from public, anon, authenticated;
revoke all on function public.validate_work_task_scope() from public, anon, authenticated;
revoke all on function public.guard_work_task_completion() from public, anon, authenticated;
revoke all on function public.touch_work_task() from public, anon, authenticated;
revoke all on function public.prevent_work_task_event_mutation() from public, anon, authenticated;

revoke all on function public.create_work_task(uuid, uuid, uuid, text, text, text, text, boolean, date, text, text, text, boolean) from public, anon;
revoke all on function public.update_work_task_management(uuid, uuid, uuid, uuid, text, text, text, text, boolean, date, text, text, boolean) from public, anon;
revoke all on function public.quick_update_work_task(uuid, text, integer, text, boolean) from public, anon;
revoke all on function public.add_work_task_artifact(uuid, text, text, text) from public, anon;
revoke all on function public.add_managed_work_task_artifact(uuid, text, text, text, text) from public, anon;
revoke all on function public.add_work_task_comment(uuid, text, boolean) from public, anon;
revoke all on function public.supervise_work_task(uuid, text, text, boolean, boolean, text, boolean, boolean, boolean) from public, anon;
revoke all on function public.grant_work_task_access(uuid, uuid, text) from public, anon;
revoke all on function public.list_work_task_assignees() from public, anon;

-- These four predicates are called by RLS/view expressions under the
-- authenticated role. Their subject is bound to auth.uid() (directly or via
-- fn_wm_can_view_task), so exposing boolean results does not bypass scope.
grant execute on function public.fn_wm_can_manage_task(uuid, uuid) to authenticated;
grant execute on function public.fn_wm_can_view_task(uuid, uuid) to authenticated;
grant execute on function public.fn_wm_can_view_artifact(uuid, uuid) to authenticated;
grant execute on function public.fn_wm_task_has_completion_artifact(uuid) to authenticated;

grant execute on function public.create_work_task(uuid, uuid, uuid, text, text, text, text, boolean, date, text, text, text, boolean) to authenticated;
grant execute on function public.update_work_task_management(uuid, uuid, uuid, uuid, text, text, text, text, boolean, date, text, text, boolean) to authenticated;
grant execute on function public.quick_update_work_task(uuid, text, integer, text, boolean) to authenticated;
grant execute on function public.add_work_task_artifact(uuid, text, text, text) to authenticated;
grant execute on function public.add_managed_work_task_artifact(uuid, text, text, text, text) to authenticated;
grant execute on function public.add_work_task_comment(uuid, text, boolean) to authenticated;
grant execute on function public.supervise_work_task(uuid, text, text, boolean, boolean, text, boolean, boolean, boolean) to authenticated;
grant execute on function public.grant_work_task_access(uuid, uuid, text) to authenticated;
grant execute on function public.list_work_task_assignees() to authenticated;
