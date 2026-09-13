-- IEOS Stage 4: Master File Register and external-link governance.
--
-- LOCAL / REVIEW ONLY. Do not apply to hosted Supabase without a separate
-- production-change approval and verified backup/restore procedure.
--
-- This migration is additive. It does not alter legacy work_files,
-- content_tasks, content_items, or task artifact history.

create sequence public.master_file_number_seq as bigint start with 1;

create table public.master_file_categories (
  slug text primary key check (slug ~ '^[a-z0-9]+(?:_[a-z0-9]+)*$'),
  label text not null unique check (char_length(btrim(label)) between 2 and 80),
  sort_order smallint not null default 100 check (sort_order between 1 and 1000),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.master_file_categories (slug, label, sort_order) values
  ('sop', 'SOP', 10),
  ('template', 'Template', 20),
  ('form', 'Form', 30),
  ('proposal', 'Proposal', 40),
  ('brochure', 'Brochure', 50),
  ('marketing', 'Marketing', 60),
  ('content_planner', 'Content Planner', 70),
  ('design_artwork', 'Design / Artwork', 80),
  ('video', 'Video', 90),
  ('photo', 'Photo', 100),
  ('research', 'Research', 110),
  ('hr', 'HR', 120),
  ('student_affairs', 'Student Affairs', 130),
  ('training_material', 'Training Material', 140),
  ('government_licensing', 'Government / Licensing', 150),
  ('finance_accounts', 'Finance / Accounts', 160),
  ('lead_source', 'Lead Source', 170),
  ('project', 'Project', 180),
  ('other', 'Other', 190);

create table public.master_file_settings (
  singleton boolean primary key default true check (singleton),
  verification_stale_days smallint not null default 90
    check (verification_stale_days between 30 and 730),
  updated_at timestamptz not null default now()
);

insert into public.master_file_settings (singleton) values (true);

create or replace function public.fn_mf_next_file_number()
returns text
language sql
volatile
security definer
set search_path = ''
as $$
  select 'MF-' || lpad(nextval('public.master_file_number_seq')::text, 6, '0');
$$;

create or replace function public.fn_mf_infer_source_system(target_url text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when target_url ~* '^https?://docs\.google\.com/document/' then 'google_docs'
    when target_url ~* '^https?://docs\.google\.com/spreadsheets/' then 'google_sheets'
    when target_url ~* '^https?://docs\.google\.com/presentation/' then 'google_slides'
    when target_url ~* '^https?://(?:drive|docs)\.google\.com/' then 'google_drive'
    when target_url ~* '^https?://(?:www\.)?canva\.com/' then 'canva'
    when target_url ~* '^https?://(?:www\.)?notion\.(?:so|site)/' then 'notion'
    else 'other_url'
  end;
$$;

create table public.master_files (
  id uuid primary key default gen_random_uuid(),
  file_number text not null unique default public.fn_mf_next_file_number(),
  file_name text not null check (char_length(btrim(file_name)) between 2 and 200),
  business_unit_id uuid not null references public.business_units(id),
  department_id uuid not null references public.departments(id),
  project_reference text check (project_reference is null or char_length(project_reference) <= 160),
  category_slug text not null references public.master_file_categories(slug) on update cascade,
  description text check (description is null or char_length(description) <= 2000),
  owner_profile_id uuid not null references public.profiles(id),
  access_level text not null default 'operational' check (access_level in (
    'operational', 'appointed_personnel', 'full_time_only',
    'management_only', 'pc_restricted'
  )),
  status text not null default 'under_review' check (status in (
    'current', 'under_review', 'superseded', 'archived'
  )),
  master_url text check (
    master_url is null or (
      master_url ~* '^https?://[^[:space:]]+$' and char_length(master_url) <= 2048
    )
  ),
  folder_url text check (
    folder_url is null or (
      folder_url ~* '^https?://[^[:space:]]+$' and char_length(folder_url) <= 2048
    )
  ),
  source_system text not null default 'other_url' check (source_system in (
    'google_drive', 'google_docs', 'google_sheets', 'google_slides',
    'canva', 'notion', 'website', 'other_url'
  )),
  supersedes_file_id uuid references public.master_files(id),
  duplicate_of_file_id uuid references public.master_files(id),
  password_reference boolean not null default false,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_verified_at timestamptz,
  archive_date date,
  remarks text check (remarks is null or char_length(remarks) <= 2000),
  row_version integer not null default 1 check (row_version > 0),
  status_rank smallint generated always as (
    case status
      when 'current' then 1
      when 'under_review' then 2
      when 'superseded' then 3
      else 4
    end
  ) stored,
  search_document tsvector generated always as (
    setweight(to_tsvector('simple'::regconfig, coalesce(file_number, '')), 'A') ||
    setweight(to_tsvector('simple'::regconfig, coalesce(file_name, '')), 'A') ||
    setweight(to_tsvector('simple'::regconfig, coalesce(category_slug, '')), 'B') ||
    setweight(to_tsvector('simple'::regconfig, coalesce(project_reference, '')), 'B') ||
    setweight(to_tsvector('simple'::regconfig, coalesce(description, '')), 'C') ||
    setweight(to_tsvector('simple'::regconfig, coalesce(remarks, '')), 'D')
  ) stored,
  check (supersedes_file_id is null or supersedes_file_id <> id),
  check (duplicate_of_file_id is null or duplicate_of_file_id <> id),
  check (not (supersedes_file_id is not null and duplicate_of_file_id is not null)),
  check (status <> 'current' or master_url is not null),
  check (duplicate_of_file_id is null or status = 'archived'),
  check (
    (status = 'archived' and archive_date is not null)
    or (status <> 'archived' and archive_date is null)
  ),
  check (not password_reference or (access_level = 'pc_restricted' and master_url is not null))
);

create table public.master_file_access_grants (
  master_file_id uuid not null references public.master_files(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  grant_type text not null check (grant_type in ('appointed_personnel', 'pc_restricted')),
  grant_reason text not null default 'explicit' check (grant_reason in ('owner', 'explicit')),
  granted_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (master_file_id, profile_id, grant_type)
);

create table public.master_file_tasks (
  master_file_id uuid not null references public.master_files(id) on delete cascade,
  task_id uuid not null references public.work_tasks(id) on delete cascade,
  linked_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (master_file_id, task_id)
);

create table public.master_file_artifacts (
  master_file_id uuid not null references public.master_files(id) on delete cascade,
  task_artifact_id uuid not null references public.work_task_artifacts(id) on delete cascade,
  linked_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (master_file_id, task_artifact_id)
);

create table public.master_file_events (
  id bigint generated always as identity primary key,
  master_file_id uuid not null references public.master_files(id) on delete cascade,
  actor_id uuid not null references public.profiles(id),
  event_type text not null check (event_type in (
    'created', 'metadata_updated', 'status_changed', 'verified',
    'superseded', 'duplicate_marked', 'access_granted', 'access_revoked',
    'task_linked', 'artifact_linked'
  )),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index master_files_business_unit_idx on public.master_files (business_unit_id, status_rank, updated_at desc);
create index master_files_department_idx on public.master_files (department_id, status_rank, updated_at desc);
create index master_files_category_idx on public.master_files (category_slug, status_rank, updated_at desc);
create index master_files_status_idx on public.master_files (status, updated_at desc);
create index master_files_owner_idx on public.master_files (owner_profile_id, status_rank, updated_at desc);
create index master_files_project_idx on public.master_files (project_reference, status_rank, updated_at desc)
  where project_reference is not null;
create index master_files_access_level_idx on public.master_files (access_level, status_rank, updated_at desc);
create index master_files_search_idx on public.master_files using gin (search_document);
create unique index master_files_one_current_purpose_idx
  on public.master_files (
    business_unit_id, department_id, category_slug, lower(btrim(file_name))
  )
  where status = 'current' and duplicate_of_file_id is null;
create index master_file_access_profile_idx on public.master_file_access_grants (profile_id, master_file_id, grant_type);
create index master_file_tasks_task_idx on public.master_file_tasks (task_id, master_file_id);
create index master_file_artifacts_artifact_idx on public.master_file_artifacts (task_artifact_id, master_file_id);
create index master_file_events_file_created_idx on public.master_file_events (master_file_id, created_at desc);

create or replace function public.fn_mf_can_use(subject_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid() and public.fn_wm_is_active(subject_uid);
$$;

create or replace function public.fn_mf_can_manage_settings(subject_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and public.fn_wm_role_of(subject_uid) in ('super_admin', 'management');
$$;

create or replace function public.fn_mf_subject_in_scope(
  subject_uid uuid,
  target_business_unit uuid,
  target_department uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and exists (
      select 1 from public.departments department
      where department.id = target_department
        and department.business_unit_id = target_business_unit
    )
    and public.fn_wm_subject_has_business_unit_access(subject_uid, target_business_unit)
    and public.fn_wm_subject_has_department_access(subject_uid, target_department);
$$;

create or replace function public.fn_mf_has_access_grant(
  subject_uid uuid,
  target_file uuid,
  requested_grant text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.master_file_access_grants access_grant
    where access_grant.master_file_id = target_file
      and access_grant.profile_id = subject_uid
      and access_grant.grant_type = requested_grant
  );
$$;

create or replace function public.fn_mf_can_manage_scope(
  subject_uid uuid,
  target_business_unit uuid,
  target_department uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and (
      public.fn_wm_role_of(subject_uid) = 'super_admin'
      or (
        public.fn_wm_role_of(subject_uid) = 'management'
        and public.fn_mf_subject_in_scope(subject_uid, target_business_unit, target_department)
      )
    );
$$;

create or replace function public.fn_mf_can_manage_file(subject_uid uuid, target_file uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and exists (
      select 1 from public.master_files master_file
      where master_file.id = target_file
        and (
          public.fn_wm_role_of(subject_uid) = 'super_admin'
          or (
            public.fn_wm_role_of(subject_uid) = 'management'
            and master_file.access_level <> 'pc_restricted'
            and (
              master_file.access_level <> 'appointed_personnel'
              or public.fn_mf_has_access_grant(
                subject_uid, master_file.id, 'appointed_personnel'
              )
            )
            and public.fn_mf_subject_in_scope(
              subject_uid, master_file.business_unit_id, master_file.department_id
            )
          )
        )
    );
$$;

create or replace function public.fn_mf_can_view_file(subject_uid uuid, target_file uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select subject_uid = auth.uid()
    and public.fn_wm_is_active(subject_uid)
    and exists (
      select 1 from public.master_files master_file
      where master_file.id = target_file
        and (
          public.fn_wm_role_of(subject_uid) = 'super_admin'
          or (
            public.fn_mf_subject_in_scope(
              subject_uid, master_file.business_unit_id, master_file.department_id
            )
            and case master_file.access_level
              when 'pc_restricted' then
                public.fn_mf_has_access_grant(subject_uid, master_file.id, 'pc_restricted')
              when 'management_only' then
                public.fn_wm_role_of(subject_uid) = 'management'
              when 'full_time_only' then
                public.fn_wm_role_of(subject_uid) in ('management', 'staff')
              when 'appointed_personnel' then
                public.fn_mf_has_access_grant(subject_uid, master_file.id, 'appointed_personnel')
              else public.fn_wm_role_of(subject_uid) in ('management', 'staff', 'intern')
            end
          )
        )
    );
$$;

create or replace function public.fn_mf_verification_stale_days()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select verification_stale_days::integer
  from public.master_file_settings
  where singleton = true;
$$;

create or replace function public.validate_master_file_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.departments department
    where department.id = new.department_id
      and department.business_unit_id = new.business_unit_id
  ) then
    raise exception using errcode = '22023', message = 'Department must belong to the selected business unit.';
  end if;

  if new.file_name ~* '(^|[[:space:]_-])(new[[:space:]_-]+final|final[0-9]*|latest)([[:space:]_-]|$)' then
    raise exception using errcode = '22023', message = 'Use a stable file name; Current/Superseded status replaces FINAL or LATEST naming.';
  end if;

  if concat_ws(' ', new.description, new.remarks) ~* '(password|passcode|otp)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' then
    raise exception using errcode = '22023', message = 'Actual passwords, passcodes and OTPs must not be stored in IEOS.';
  end if;

  if new.password_reference and new.access_level <> 'pc_restricted' then
    raise exception using errcode = '22023', message = 'Password-storage references must be P&C restricted.';
  end if;

  if new.source_system is null or new.source_system = '' then
    new.source_system := public.fn_mf_infer_source_system(new.master_url);
  end if;

  if new.status = 'current' and new.last_verified_at is null then
    new.last_verified_at := now();
  end if;

  if new.status = 'archived' then
    new.archive_date := coalesce(new.archive_date, current_date);
  else
    new.archive_date := null;
  end if;

  return new;
end;
$$;

create or replace function public.touch_master_file()
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

create or replace function public.prevent_master_file_event_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception using errcode = '42501', message = 'Master file audit events are immutable.';
end;
$$;

create trigger a_validate_master_file
before insert or update on public.master_files
for each row execute function public.validate_master_file_row();

create trigger z_touch_master_file
before update on public.master_files
for each row execute function public.touch_master_file();

create trigger prevent_master_file_event_change
before update or delete on public.master_file_events
for each row execute function public.prevent_master_file_event_mutation();

alter table public.master_file_categories enable row level security;
alter table public.master_file_settings enable row level security;
alter table public.master_files enable row level security;
alter table public.master_file_access_grants enable row level security;
alter table public.master_file_tasks enable row level security;
alter table public.master_file_artifacts enable row level security;
alter table public.master_file_events enable row level security;

create policy master_file_categories_select on public.master_file_categories
  for select to authenticated
  using (is_active and (select public.fn_mf_can_use(auth.uid())));

create policy master_file_settings_select on public.master_file_settings
  for select to authenticated
  using ((select public.fn_mf_can_manage_settings(auth.uid())));

create policy master_files_select on public.master_files
  for select to authenticated
  using ((select public.fn_mf_can_view_file(auth.uid(), id)));

create policy master_file_access_grants_select on public.master_file_access_grants
  for select to authenticated
  using (
    profile_id = (select auth.uid())
    or (select public.fn_mf_can_manage_file(auth.uid(), master_file_id))
  );

create policy master_file_tasks_select on public.master_file_tasks
  for select to authenticated
  using (
    (select public.fn_mf_can_view_file(auth.uid(), master_file_id))
    and (select public.fn_wm_can_view_task(auth.uid(), task_id))
  );

create policy master_file_artifacts_select on public.master_file_artifacts
  for select to authenticated
  using (
    (select public.fn_mf_can_view_file(auth.uid(), master_file_id))
    and (select public.fn_wm_can_view_artifact(auth.uid(), task_artifact_id))
  );

create policy master_file_events_select on public.master_file_events
  for select to authenticated
  using ((select public.fn_mf_can_view_file(auth.uid(), master_file_id)));

create view public.master_file_review
with (security_invoker = true)
as
select
  master_file.id,
  array_remove(array[
    case when master_file.status in ('current', 'under_review')
      and master_file.master_url is null then 'MISSING MASTER LINK' end,
    case when master_file.status in ('current', 'under_review') and exists (
      select 1 from public.master_files possible_duplicate
      where possible_duplicate.id <> master_file.id
        and public.fn_mf_can_view_file(auth.uid(), possible_duplicate.id)
        and possible_duplicate.status in ('current', 'under_review')
        and possible_duplicate.business_unit_id = master_file.business_unit_id
        and possible_duplicate.department_id = master_file.department_id
        and (
          (
            possible_duplicate.master_url is not null
            and lower(possible_duplicate.master_url) = lower(master_file.master_url)
          )
          or (
            possible_duplicate.category_slug = master_file.category_slug
            and lower(btrim(possible_duplicate.file_name)) = lower(btrim(master_file.file_name))
          )
        )
    ) then 'DUPLICATE CANDIDATE' end,
    case when master_file.status = 'current' and exists (
      select 1 from public.master_files replacement
      where replacement.supersedes_file_id = master_file.id
        and public.fn_mf_can_view_file(auth.uid(), replacement.id)
        and replacement.status = 'current'
    ) then 'SUPERSEDED FILE STILL CURRENT' end,
    case when master_file.status = 'current'
      and (
        master_file.last_verified_at is null
        or master_file.last_verified_at < now() - make_interval(days => public.fn_mf_verification_stale_days())
      ) then 'NOT VERIFIED' end
  ], null)::text[] as review_flags
from public.master_files master_file;

create or replace function public.search_master_files(
  p_search text default null,
  p_business_unit_id uuid default null,
  p_department_id uuid default null,
  p_category_slug text default null,
  p_owner_profile_id uuid default null,
  p_project_reference text default null,
  p_status text default null,
  p_access_level text default null,
  p_include_history boolean default false,
  p_review_only boolean default false,
  p_file_id uuid default null,
  p_limit integer default 50
)
returns table (
  id uuid,
  file_number text,
  file_name text,
  business_unit_id uuid,
  business_unit_name text,
  department_id uuid,
  department_name text,
  category_slug text,
  category_label text,
  owner_profile_id uuid,
  owner_name text,
  access_level text,
  status text,
  master_url text,
  folder_url text,
  source_system text,
  project_reference text,
  last_verified_at timestamptz,
  updated_at timestamptz,
  review_flags text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    master_file.id,
    master_file.file_number,
    master_file.file_name,
    master_file.business_unit_id,
    business_unit.name,
    master_file.department_id,
    department.name,
    master_file.category_slug,
    category.label,
    master_file.owner_profile_id,
    coalesce(owner_profile.full_name, owner_profile.email),
    master_file.access_level,
    master_file.status,
    master_file.master_url,
    master_file.folder_url,
    master_file.source_system,
    master_file.project_reference,
    master_file.last_verified_at,
    master_file.updated_at,
    coalesce(review.review_flags, array[]::text[])
  from public.master_files master_file
  join public.business_units business_unit on business_unit.id = master_file.business_unit_id
  join public.departments department on department.id = master_file.department_id
  join public.master_file_categories category on category.slug = master_file.category_slug
  join public.profiles owner_profile on owner_profile.id = master_file.owner_profile_id
  left join public.master_file_review review on review.id = master_file.id
  where public.fn_mf_can_view_file(auth.uid(), master_file.id)
    and (p_file_id is null or master_file.id = p_file_id)
    and (p_business_unit_id is null or master_file.business_unit_id = p_business_unit_id)
    and (p_department_id is null or master_file.department_id = p_department_id)
    and (p_category_slug is null or master_file.category_slug = p_category_slug)
    and (p_owner_profile_id is null or master_file.owner_profile_id = p_owner_profile_id)
    and (p_project_reference is null or master_file.project_reference = p_project_reference)
    and (p_status is null or master_file.status = p_status)
    and (p_access_level is null or master_file.access_level = p_access_level)
    and (
      coalesce(p_include_history, false)
      or master_file.status in ('current', 'under_review')
    )
    and (
      not coalesce(p_review_only, false)
      or cardinality(coalesce(review.review_flags, array[]::text[])) > 0
    )
    and (
      nullif(btrim(p_search), '') is null
      or master_file.search_document @@ websearch_to_tsquery('simple'::regconfig, p_search)
      or master_file.file_number ilike btrim(p_search) || '%'
      or master_file.master_url ilike '%' || btrim(p_search) || '%'
    )
  order by
    master_file.status_rank,
    case when nullif(btrim(p_search), '') is null then 0::real
      else ts_rank(master_file.search_document, websearch_to_tsquery('simple'::regconfig, p_search))
    end desc,
    master_file.updated_at desc,
    master_file.file_number
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

create or replace function public.get_master_file_audit(p_master_file_id uuid)
returns table (
  event_id bigint,
  event_type text,
  actor_id uuid,
  actor_name text,
  metadata jsonb,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    event.id,
    event.event_type,
    event.actor_id,
    coalesce(actor.full_name, actor.email),
    event.metadata,
    event.created_at
  from public.master_file_events event
  join public.profiles actor on actor.id = event.actor_id
  where event.master_file_id = p_master_file_id
    and public.fn_mf_can_view_file(auth.uid(), event.master_file_id)
  order by event.created_at desc, event.id desc;
$$;

create or replace function public.create_master_file(
  p_file_name text,
  p_business_unit_id uuid,
  p_department_id uuid,
  p_category_slug text,
  p_description text,
  p_owner_profile_id uuid,
  p_access_level text,
  p_status text,
  p_master_url text,
  p_folder_url text,
  p_source_system text,
  p_project_reference text,
  p_password_reference boolean,
  p_remarks text,
  p_related_task_id uuid,
  p_data_handling_confirmed boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  new_file_id uuid;
  effective_source text;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that no password or unauthorised personal data is stored.';
  end if;
  if not public.fn_mf_can_manage_scope(uid, p_business_unit_id, p_department_id) then
    raise exception using errcode = '42501', message = 'Not authorised to create a file record in this scope.';
  end if;
  if p_access_level not in (
    'operational', 'appointed_personnel', 'full_time_only', 'management_only', 'pc_restricted'
  ) then
    raise exception using errcode = '22023', message = 'Invalid access level.';
  end if;
  if p_access_level = 'pc_restricted' and public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can create a P&C restricted file record.';
  end if;
  if p_status not in ('current', 'under_review') then
    raise exception using errcode = '22023', message = 'New records must start as Current or Under Review.';
  end if;
  if not exists (
    select 1 from public.master_file_categories category
    where category.slug = p_category_slug and category.is_active
  ) then
    raise exception using errcode = '22023', message = 'Choose an active file category.';
  end if;
  if not public.fn_wm_is_active(p_owner_profile_id)
    or not public.fn_wm_subject_has_department_access(p_owner_profile_id, p_department_id) then
    raise exception using errcode = '22023', message = 'Owner must be active and permitted in the selected department.';
  end if;
  if p_related_task_id is not null and not public.fn_wm_can_manage_task(uid, p_related_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to link the selected task.';
  end if;

  effective_source := coalesce(nullif(btrim(p_source_system), ''), public.fn_mf_infer_source_system(p_master_url));

  insert into public.master_files (
    file_name, business_unit_id, department_id, project_reference,
    category_slug, description, owner_profile_id, access_level, status,
    master_url, folder_url, source_system, password_reference, created_by, remarks
  ) values (
    btrim(p_file_name), p_business_unit_id, p_department_id,
    nullif(btrim(p_project_reference), ''), p_category_slug,
    nullif(btrim(p_description), ''), p_owner_profile_id, p_access_level, p_status,
    nullif(btrim(p_master_url), ''), nullif(btrim(p_folder_url), ''),
    effective_source, coalesce(p_password_reference, false), uid,
    nullif(btrim(p_remarks), '')
  ) returning id into new_file_id;

  if p_access_level in ('appointed_personnel', 'pc_restricted') then
    insert into public.master_file_access_grants (
      master_file_id, profile_id, grant_type, grant_reason, granted_by
    ) values (
      new_file_id, p_owner_profile_id, p_access_level, 'owner', uid
    );
  end if;

  if p_access_level = 'appointed_personnel' and uid <> p_owner_profile_id then
    insert into public.master_file_access_grants (
      master_file_id, profile_id, grant_type, grant_reason, granted_by
    ) values (
      new_file_id, uid, 'appointed_personnel', 'explicit', uid
    ) on conflict do nothing;
  end if;

  if p_related_task_id is not null then
    insert into public.master_file_tasks (master_file_id, task_id, linked_by)
    values (new_file_id, p_related_task_id, uid);
  end if;

  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (
    new_file_id, uid, 'created',
    jsonb_build_object(
      'status', p_status,
      'access_level', p_access_level,
      'category', p_category_slug,
      'owner_profile_id', p_owner_profile_id,
      'source_system', effective_source,
      'task_linked', p_related_task_id is not null
    )
  );

  return new_file_id;
end;
$$;

create or replace function public.update_master_file_metadata(
  p_master_file_id uuid,
  p_file_name text,
  p_business_unit_id uuid,
  p_department_id uuid,
  p_category_slug text,
  p_description text,
  p_owner_profile_id uuid,
  p_access_level text,
  p_master_url text,
  p_folder_url text,
  p_source_system text,
  p_project_reference text,
  p_password_reference boolean,
  p_remarks text,
  p_data_handling_confirmed boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  before_file public.master_files%rowtype;
  effective_source text;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that no password or unauthorised personal data is stored.';
  end if;
  select * into strict before_file from public.master_files
  where id = p_master_file_id for update;
  if not public.fn_mf_can_manage_file(uid, p_master_file_id)
    or not public.fn_mf_can_manage_scope(uid, p_business_unit_id, p_department_id) then
    raise exception using errcode = '42501', message = 'Not authorised to edit this file record or target scope.';
  end if;
  if (before_file.access_level = 'pc_restricted' or p_access_level = 'pc_restricted')
    and public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can change P&C restricted metadata.';
  end if;
  if p_access_level not in (
    'operational', 'appointed_personnel', 'full_time_only', 'management_only', 'pc_restricted'
  ) then
    raise exception using errcode = '22023', message = 'Invalid access level.';
  end if;
  if not exists (
    select 1 from public.master_file_categories category
    where category.slug = p_category_slug and category.is_active
  ) then
    raise exception using errcode = '22023', message = 'Choose an active file category.';
  end if;
  if not public.fn_wm_is_active(p_owner_profile_id)
    or not public.fn_wm_subject_has_department_access(p_owner_profile_id, p_department_id) then
    raise exception using errcode = '22023', message = 'Owner must be active and permitted in the selected department.';
  end if;

  effective_source := coalesce(nullif(btrim(p_source_system), ''), public.fn_mf_infer_source_system(p_master_url));

  delete from public.master_file_access_grants
  where master_file_id = p_master_file_id
    and grant_reason = 'owner'
    and (profile_id <> p_owner_profile_id or grant_type <> p_access_level);

  update public.master_files
  set file_name = btrim(p_file_name),
      business_unit_id = p_business_unit_id,
      department_id = p_department_id,
      category_slug = p_category_slug,
      description = nullif(btrim(p_description), ''),
      owner_profile_id = p_owner_profile_id,
      access_level = p_access_level,
      master_url = nullif(btrim(p_master_url), ''),
      folder_url = nullif(btrim(p_folder_url), ''),
      source_system = effective_source,
      project_reference = nullif(btrim(p_project_reference), ''),
      password_reference = coalesce(p_password_reference, false),
      remarks = nullif(btrim(p_remarks), '')
  where id = p_master_file_id;

  if p_access_level in ('appointed_personnel', 'pc_restricted') then
    insert into public.master_file_access_grants (
      master_file_id, profile_id, grant_type, grant_reason, granted_by
    ) values (
      p_master_file_id, p_owner_profile_id, p_access_level, 'owner', uid
    ) on conflict (master_file_id, profile_id, grant_type) do update
      set grant_reason = 'owner', granted_by = excluded.granted_by, created_at = now();
  end if;

  if p_access_level = 'appointed_personnel' then
    insert into public.master_file_access_grants (
      master_file_id, profile_id, grant_type, grant_reason, granted_by
    ) values (
      p_master_file_id, uid, 'appointed_personnel', 'explicit', uid
    ) on conflict do nothing;
  end if;

  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (
    p_master_file_id, uid, 'metadata_updated',
    jsonb_build_object(
      'business_unit_changed', before_file.business_unit_id is distinct from p_business_unit_id,
      'department_changed', before_file.department_id is distinct from p_department_id,
      'category_changed', before_file.category_slug is distinct from p_category_slug,
      'owner_changed', before_file.owner_profile_id is distinct from p_owner_profile_id,
      'access_level_changed', before_file.access_level is distinct from p_access_level,
      'master_link_changed', before_file.master_url is distinct from nullif(btrim(p_master_url), ''),
      'folder_link_changed', before_file.folder_url is distinct from nullif(btrim(p_folder_url), '')
    )
  );
end;
$$;

create or replace function public.set_master_file_status(
  p_master_file_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  before_status text;
begin
  if p_status not in ('current', 'under_review', 'archived') then
    raise exception using errcode = '22023', message = 'Use the dedicated supersede action for Superseded status.';
  end if;
  if not public.fn_mf_can_manage_file(uid, p_master_file_id) then
    raise exception using errcode = '42501', message = 'Not authorised to change this file status.';
  end if;
  select status into strict before_status from public.master_files
  where id = p_master_file_id for update;

  update public.master_files set status = p_status where id = p_master_file_id;
  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (
    p_master_file_id, uid, 'status_changed',
    jsonb_build_object('from', before_status, 'to', p_status)
  );
end;
$$;

create or replace function public.verify_master_file(p_master_file_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare uid uuid := auth.uid();
begin
  if not public.fn_mf_can_manage_file(uid, p_master_file_id) then
    raise exception using errcode = '42501', message = 'Not authorised to verify this file record.';
  end if;
  update public.master_files set last_verified_at = now() where id = p_master_file_id;
  insert into public.master_file_events (master_file_id, actor_id, event_type)
  values (p_master_file_id, uid, 'verified');
end;
$$;

create or replace function public.supersede_master_file(
  p_old_file_id uuid,
  p_replacement_file_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  old_file public.master_files%rowtype;
  replacement public.master_files%rowtype;
begin
  if p_old_file_id = p_replacement_file_id then
    raise exception using errcode = '22023', message = 'A file cannot supersede itself.';
  end if;
  perform 1 from public.master_files
  where id in (p_old_file_id, p_replacement_file_id)
  order by id for update;
  select * into strict old_file from public.master_files where id = p_old_file_id;
  select * into strict replacement from public.master_files where id = p_replacement_file_id;
  if not public.fn_mf_can_manage_file(uid, old_file.id)
    or not public.fn_mf_can_manage_file(uid, replacement.id) then
    raise exception using errcode = '42501', message = 'Not authorised to supersede these file records.';
  end if;
  if old_file.business_unit_id <> replacement.business_unit_id
    or old_file.department_id <> replacement.department_id
    or old_file.category_slug <> replacement.category_slug then
    raise exception using errcode = '22023', message = 'Replacement must use the same business unit, department and category.';
  end if;
  if replacement.master_url is null or replacement.duplicate_of_file_id is not null
    or replacement.status in ('superseded', 'archived') then
    raise exception using errcode = '22023', message = 'Replacement must be active, unique and have a usable master link.';
  end if;

  update public.master_files set status = 'superseded' where id = old_file.id;
  update public.master_files
  set status = 'current', supersedes_file_id = old_file.id
  where id = replacement.id;

  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata) values
    (old_file.id, uid, 'superseded', jsonb_build_object('replacement_file_id', replacement.id)),
    (replacement.id, uid, 'superseded', jsonb_build_object('supersedes_file_id', old_file.id));
end;
$$;

create or replace function public.mark_master_file_duplicate(
  p_duplicate_file_id uuid,
  p_canonical_file_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  duplicate_file public.master_files%rowtype;
  canonical_file public.master_files%rowtype;
begin
  if p_duplicate_file_id = p_canonical_file_id then
    raise exception using errcode = '22023', message = 'A file cannot duplicate itself.';
  end if;
  perform 1 from public.master_files
  where id in (p_duplicate_file_id, p_canonical_file_id)
  order by id for update;
  select * into strict duplicate_file from public.master_files where id = p_duplicate_file_id;
  select * into strict canonical_file from public.master_files where id = p_canonical_file_id;
  if not public.fn_mf_can_manage_file(uid, duplicate_file.id)
    or not public.fn_mf_can_manage_file(uid, canonical_file.id) then
    raise exception using errcode = '42501', message = 'Not authorised to mark these file records as duplicates.';
  end if;
  if duplicate_file.business_unit_id <> canonical_file.business_unit_id then
    raise exception using errcode = '22023', message = 'Duplicate and canonical records must share a business unit.';
  end if;
  if canonical_file.status not in ('current', 'under_review')
    or canonical_file.duplicate_of_file_id is not null then
    raise exception using errcode = '22023', message = 'Canonical record must be active and not itself a duplicate.';
  end if;

  update public.master_files
  set status = 'archived', duplicate_of_file_id = canonical_file.id,
      supersedes_file_id = null
  where id = duplicate_file.id;

  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (
    duplicate_file.id, uid, 'duplicate_marked',
    jsonb_build_object('canonical_file_id', canonical_file.id)
  );
end;
$$;

create or replace function public.grant_master_file_access(
  p_master_file_id uuid,
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
  target_file public.master_files%rowtype;
begin
  select * into strict target_file from public.master_files
  where id = p_master_file_id for update;
  if not public.fn_mf_can_manage_file(uid, p_master_file_id) then
    raise exception using errcode = '42501', message = 'Not authorised to grant file access.';
  end if;
  if p_grant_type <> target_file.access_level
    or p_grant_type not in ('appointed_personnel', 'pc_restricted') then
    raise exception using errcode = '22023', message = 'Grant type must match the restricted file access level.';
  end if;
  if p_grant_type = 'pc_restricted' and public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can grant P&C access.';
  end if;
  if not public.fn_wm_is_active(p_profile_id)
    or not public.fn_wm_subject_has_department_access(p_profile_id, target_file.department_id) then
    raise exception using errcode = '22023', message = 'Access can only be granted to active personnel in scope.';
  end if;
  if p_grant_type = 'pc_restricted' and public.fn_wm_role_of(p_profile_id) = 'intern' then
    raise exception using errcode = '22023', message = 'Interns cannot receive P&C restricted access.';
  end if;

  insert into public.master_file_access_grants (
    master_file_id, profile_id, grant_type, grant_reason, granted_by
  ) values (
    p_master_file_id, p_profile_id, p_grant_type, 'explicit', uid
  ) on conflict (master_file_id, profile_id, grant_type) do nothing;

  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (
    p_master_file_id, uid, 'access_granted',
    jsonb_build_object('profile_id', p_profile_id, 'grant_type', p_grant_type)
  );
end;
$$;

create or replace function public.revoke_master_file_access(
  p_master_file_id uuid,
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
  affected integer;
begin
  if not public.fn_mf_can_manage_file(uid, p_master_file_id) then
    raise exception using errcode = '42501', message = 'Not authorised to revoke file access.';
  end if;
  if p_grant_type = 'pc_restricted' and public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can revoke P&C access.';
  end if;

  delete from public.master_file_access_grants
  where master_file_id = p_master_file_id
    and profile_id = p_profile_id
    and grant_type = p_grant_type
    and grant_reason = 'explicit';
  get diagnostics affected = row_count;
  if affected = 0 then
    raise exception using errcode = '22023', message = 'Only an explicit access grant can be revoked here.';
  end if;

  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (
    p_master_file_id, uid, 'access_revoked',
    jsonb_build_object('profile_id', p_profile_id, 'grant_type', p_grant_type)
  );
end;
$$;

create or replace function public.link_master_file_task(
  p_master_file_id uuid,
  p_task_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare uid uuid := auth.uid();
begin
  if not public.fn_mf_can_manage_file(uid, p_master_file_id)
    or not public.fn_wm_can_manage_task(uid, p_task_id) then
    raise exception using errcode = '42501', message = 'Not authorised to link this task.';
  end if;
  insert into public.master_file_tasks (master_file_id, task_id, linked_by)
  values (p_master_file_id, p_task_id, uid)
  on conflict do nothing;
  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (p_master_file_id, uid, 'task_linked', jsonb_build_object('task_id', p_task_id));
end;
$$;

create or replace function public.link_master_file_artifact(
  p_master_file_id uuid,
  p_task_artifact_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare uid uuid := auth.uid();
begin
  if not public.fn_mf_can_manage_file(uid, p_master_file_id)
    or not public.fn_wm_can_view_artifact(uid, p_task_artifact_id) then
    raise exception using errcode = '42501', message = 'Not authorised to link this task artifact.';
  end if;
  insert into public.master_file_artifacts (master_file_id, task_artifact_id, linked_by)
  values (p_master_file_id, p_task_artifact_id, uid)
  on conflict do nothing;
  insert into public.master_file_events (master_file_id, actor_id, event_type, metadata)
  values (
    p_master_file_id, uid, 'artifact_linked',
    jsonb_build_object('task_artifact_id', p_task_artifact_id)
  );
end;
$$;

create or replace function public.upsert_master_file_category(
  p_slug text,
  p_label text,
  p_sort_order smallint,
  p_is_active boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare uid uuid := auth.uid();
begin
  if uid is null or not public.fn_wm_is_active(uid)
    or public.fn_wm_role_of(uid) <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Only the Director can configure file categories.';
  end if;
  insert into public.master_file_categories (slug, label, sort_order, is_active)
  values (p_slug, btrim(p_label), p_sort_order, p_is_active)
  on conflict (slug) do update
    set label = excluded.label,
        sort_order = excluded.sort_order,
        is_active = excluded.is_active,
        updated_at = now();
end;
$$;

revoke all on table public.master_file_categories from public, anon, authenticated;
revoke all on table public.master_file_settings from public, anon, authenticated;
revoke all on table public.master_files from public, anon, authenticated;
revoke all on table public.master_file_access_grants from public, anon, authenticated;
revoke all on table public.master_file_tasks from public, anon, authenticated;
revoke all on table public.master_file_artifacts from public, anon, authenticated;
revoke all on table public.master_file_events from public, anon, authenticated;
revoke all on table public.master_file_review from public, anon, authenticated;
revoke all on sequence public.master_file_number_seq from public, anon, authenticated;
revoke all on sequence public.master_file_events_id_seq from public, anon, authenticated;

grant select on table public.master_file_categories to authenticated;
grant select on table public.master_file_settings to authenticated;
grant select on table public.master_files to authenticated;
grant select on table public.master_file_access_grants to authenticated;
grant select on table public.master_file_tasks to authenticated;
grant select on table public.master_file_artifacts to authenticated;
grant select on table public.master_file_events to authenticated;
grant select on table public.master_file_review to authenticated;

revoke all on function public.fn_mf_next_file_number() from public, anon, authenticated;
revoke all on function public.fn_mf_infer_source_system(text) from public, anon, authenticated;
revoke all on function public.fn_mf_can_use(uuid) from public, anon, authenticated;
revoke all on function public.fn_mf_can_manage_settings(uuid) from public, anon, authenticated;
revoke all on function public.fn_mf_subject_in_scope(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_mf_has_access_grant(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.fn_mf_can_manage_scope(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_mf_can_manage_file(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_mf_can_view_file(uuid, uuid) from public, anon, authenticated;
revoke all on function public.fn_mf_verification_stale_days() from public, anon, authenticated;
revoke all on function public.validate_master_file_row() from public, anon, authenticated;
revoke all on function public.touch_master_file() from public, anon, authenticated;
revoke all on function public.prevent_master_file_event_mutation() from public, anon, authenticated;

revoke all on function public.search_master_files(text, uuid, uuid, text, uuid, text, text, text, boolean, boolean, uuid, integer) from public, anon;
revoke all on function public.get_master_file_audit(uuid) from public, anon;
revoke all on function public.create_master_file(text, uuid, uuid, text, text, uuid, text, text, text, text, text, text, boolean, text, uuid, boolean) from public, anon;
revoke all on function public.update_master_file_metadata(uuid, text, uuid, uuid, text, text, uuid, text, text, text, text, text, boolean, text, boolean) from public, anon;
revoke all on function public.set_master_file_status(uuid, text) from public, anon;
revoke all on function public.verify_master_file(uuid) from public, anon;
revoke all on function public.supersede_master_file(uuid, uuid) from public, anon;
revoke all on function public.mark_master_file_duplicate(uuid, uuid) from public, anon;
revoke all on function public.grant_master_file_access(uuid, uuid, text) from public, anon;
revoke all on function public.revoke_master_file_access(uuid, uuid, text) from public, anon;
revoke all on function public.link_master_file_task(uuid, uuid) from public, anon;
revoke all on function public.link_master_file_artifact(uuid, uuid) from public, anon;
revoke all on function public.upsert_master_file_category(text, text, smallint, boolean) from public, anon;

grant execute on function public.fn_mf_can_use(uuid) to authenticated;
grant execute on function public.fn_mf_can_manage_settings(uuid) to authenticated;
grant execute on function public.fn_mf_can_manage_file(uuid, uuid) to authenticated;
grant execute on function public.fn_mf_can_view_file(uuid, uuid) to authenticated;
grant execute on function public.fn_mf_verification_stale_days() to authenticated;
grant execute on function public.search_master_files(text, uuid, uuid, text, uuid, text, text, text, boolean, boolean, uuid, integer) to authenticated;
grant execute on function public.get_master_file_audit(uuid) to authenticated;
grant execute on function public.create_master_file(text, uuid, uuid, text, text, uuid, text, text, text, text, text, text, boolean, text, uuid, boolean) to authenticated;
grant execute on function public.update_master_file_metadata(uuid, text, uuid, uuid, text, text, uuid, text, text, text, text, text, boolean, text, boolean) to authenticated;
grant execute on function public.set_master_file_status(uuid, text) to authenticated;
grant execute on function public.verify_master_file(uuid) to authenticated;
grant execute on function public.supersede_master_file(uuid, uuid) to authenticated;
grant execute on function public.mark_master_file_duplicate(uuid, uuid) to authenticated;
grant execute on function public.grant_master_file_access(uuid, uuid, text) to authenticated;
grant execute on function public.revoke_master_file_access(uuid, uuid, text) to authenticated;
grant execute on function public.link_master_file_task(uuid, uuid) to authenticated;
grant execute on function public.link_master_file_artifact(uuid, uuid) to authenticated;
grant execute on function public.upsert_master_file_category(text, text, smallint, boolean) to authenticated;
