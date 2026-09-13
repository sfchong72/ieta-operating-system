-- IEOS Stage 5: Restricted Marketing Lead Register.
-- LOCAL / REVIEW ONLY. Never apply to hosted Supabase without separate approval.
-- Additive only: existing source sheets, legacy content, tasks, and files remain intact.

create sequence public.marketing_lead_number_seq as bigint start with 1;

create table public.marketing_lead_sources (
  slug text primary key check (slug ~ '^[a-z0-9]+(?:_[a-z0-9]+)*$'),
  label text not null unique check (char_length(btrim(label)) between 2 and 100),
  sort_order smallint not null default 100 check (sort_order between 1 and 1000),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.marketing_lead_sources (slug, label, sort_order) values
  ('website', 'Website', 10), ('whatsapp', 'WhatsApp', 20),
  ('walk_in', 'Walk-in', 30), ('google_ads', 'Google Ads', 40),
  ('meta_ads', 'Meta / Facebook / Instagram Ads', 50),
  ('adshelper', 'AdsHelper', 60), ('tiktok', 'TikTok', 70),
  ('xhs', 'XHS', 80), ('open_day', 'Open Day', 90),
  ('school_fair', 'School Fair', 100),
  ('education_fair', 'Education Fair', 110), ('referral', 'Referral', 120),
  ('agent', 'Agent', 130), ('school_university', 'School / University', 140),
  ('existing_student_alumni', 'Existing Student / Alumni', 150),
  ('other', 'Other', 160);

create table public.marketing_lead_settings (
  singleton boolean primary key default true check (singleton),
  initial_response_hours smallint not null default 24 check (initial_response_hours between 1 and 168),
  updated_at timestamptz not null default now()
);
insert into public.marketing_lead_settings (singleton) values (true);

create table public.marketing_lead_access_grants (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  business_unit_id uuid not null references public.business_units(id) on delete cascade,
  department_id uuid not null references public.departments(id) on delete cascade,
  can_manage boolean not null default false,
  granted_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (profile_id, business_unit_id, department_id)
);

create or replace function public.fn_ml_next_lead_number()
returns text language sql volatile security definer set search_path = '' as $$
  select 'LEAD-' || to_char(current_date, 'YYMM') || '-' ||
    lpad(nextval('public.marketing_lead_number_seq')::text, 4, '0');
$$;

create table public.marketing_leads (
  id uuid primary key default gen_random_uuid(),
  lead_number text not null unique default public.fn_ml_next_lead_number(),
  date_received timestamptz not null default now(),
  business_unit_id uuid not null references public.business_units(id),
  department_id uuid not null references public.departments(id),
  branch text not null check (char_length(btrim(branch)) between 1 and 120),
  source_slug text not null references public.marketing_lead_sources(slug) on update cascade,
  campaign_id uuid references public.campaigns(id),
  project_reference text check (project_reference is null or char_length(btrim(project_reference)) <= 160),
  name text not null check (char_length(btrim(name)) between 1 and 160),
  contact_number text not null check (char_length(btrim(contact_number)) between 5 and 50),
  email text check (email is null or (char_length(email) <= 254 and email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')),
  country text check (country is null or char_length(btrim(country)) <= 100),
  nationality text check (nationality is null or char_length(btrim(nationality)) <= 100),
  programme_interest text not null check (char_length(btrim(programme_interest)) between 1 and 200),
  assigned_to_profile_id uuid not null references public.profiles(id),
  status text not null default 'new' check (status in (
    'new','contacted','follow_up','consultation_booked','interested','application',
    'signed_up','not_suitable','no_response','withdrawn','closed_other'
  )),
  last_contact_at timestamptz,
  next_follow_up_at timestamptz,
  contact_result text check (contact_result is null or char_length(btrim(contact_result)) <= 1000),
  consultation_date timestamptz,
  final_outcome text check (final_outcome is null or char_length(btrim(final_outcome)) <= 1000),
  estimated_or_actual_value numeric(14,2) check (estimated_or_actual_value is null or estimated_or_actual_value >= 0),
  source_reference_url text check (source_reference_url is null or (char_length(source_reference_url) <= 2048 and source_reference_url ~* '^https?://[^[:space:]]+$')),
  remarks text check (remarks is null or char_length(btrim(remarks)) <= 2000),
  duplicate_of_lead_id uuid references public.marketing_leads(id),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  row_version integer not null default 1 check (row_version > 0),
  normalized_phone text generated always as (regexp_replace(lower(contact_number), '[^0-9+]', '', 'g')) stored,
  normalized_email text generated always as (lower(coalesce(email, ''))) stored,
  check (duplicate_of_lead_id is null or duplicate_of_lead_id <> id),
  check (
    last_contact_at is null
    or status in ('signed_up','not_suitable','withdrawn','closed_other')
    or next_follow_up_at is not null
  )
);

create table public.lead_interactions (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.marketing_leads(id) on delete cascade,
  interaction_at timestamptz not null default now(),
  interaction_type text not null check (interaction_type in (
    'call','whatsapp','email','consultation','walk_in','video_call','event','other'
  )),
  performed_by uuid not null references public.profiles(id),
  result text not null check (char_length(btrim(result)) between 1 and 2000),
  next_action text not null check (char_length(btrim(next_action)) between 1 and 1000),
  next_follow_up_at timestamptz,
  evidence_reference_url text check (evidence_reference_url is null or (char_length(evidence_reference_url) <= 2048 and evidence_reference_url ~* '^https?://[^[:space:]]+$')),
  created_at timestamptz not null default now()
);

create table public.marketing_lead_task_links (
  lead_id uuid not null references public.marketing_leads(id) on delete cascade,
  task_id uuid not null references public.work_tasks(id) on delete cascade,
  linked_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (lead_id, task_id)
);

create table public.marketing_lead_events (
  id bigint generated always as identity primary key,
  lead_id uuid not null references public.marketing_leads(id) on delete cascade,
  actor_id uuid not null references public.profiles(id),
  event_type text not null check (event_type in (
    'created','metadata_updated','assigned','status_changed','closed','reopened',
    'interaction_added','duplicate_marked','access_sensitive_changed','task_created'
  )),
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now()
);

create index marketing_leads_scope_idx on public.marketing_leads (business_unit_id, department_id, status);
create index marketing_leads_assignee_idx on public.marketing_leads (assigned_to_profile_id, status, next_follow_up_at);
create index marketing_leads_source_idx on public.marketing_leads (source_slug, date_received desc);
create index marketing_leads_branch_idx on public.marketing_leads (branch, status);
create index marketing_leads_campaign_idx on public.marketing_leads (campaign_id, status) where campaign_id is not null;
create index marketing_leads_programme_idx on public.marketing_leads (programme_interest, status);
create index marketing_leads_received_idx on public.marketing_leads (date_received desc);
create index marketing_leads_follow_up_idx on public.marketing_leads (next_follow_up_at, status) where next_follow_up_at is not null;
create index marketing_leads_phone_idx on public.marketing_leads (normalized_phone) where normalized_phone <> '';
create index marketing_leads_email_idx on public.marketing_leads (normalized_email) where normalized_email <> '';
create index lead_interactions_lead_idx on public.lead_interactions (lead_id, interaction_at desc, created_at desc);
create index marketing_lead_access_profile_idx on public.marketing_lead_access_grants (profile_id, business_unit_id, department_id);
create index marketing_lead_task_task_idx on public.marketing_lead_task_links (task_id, lead_id);
create index marketing_lead_events_lead_idx on public.marketing_lead_events (lead_id, created_at desc);

create or replace function public.fn_ml_has_scope_grant(subject_uid uuid, target_bu uuid, target_department uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select subject_uid = auth.uid() and public.fn_wm_is_active(subject_uid) and (
    public.fn_wm_role_of(subject_uid) = 'super_admin'
    or exists (
      select 1 from public.marketing_lead_access_grants grant_row
      where grant_row.profile_id = subject_uid
        and grant_row.business_unit_id = target_bu
        and grant_row.department_id = target_department
    )
  );
$$;

create or replace function public.fn_ml_can_access_module(subject_uid uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select subject_uid = auth.uid() and public.fn_wm_is_active(subject_uid) and (
    public.fn_wm_role_of(subject_uid) = 'super_admin'
    or exists (select 1 from public.marketing_lead_access_grants g where g.profile_id = subject_uid)
  );
$$;

create or replace function public.fn_ml_can_manage_scope(subject_uid uuid, target_bu uuid, target_department uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select subject_uid = auth.uid() and public.fn_wm_is_active(subject_uid) and (
    public.fn_wm_role_of(subject_uid) = 'super_admin'
    or exists (
      select 1 from public.marketing_lead_access_grants g
      where g.profile_id = subject_uid and g.business_unit_id = target_bu
        and g.department_id = target_department and g.can_manage
    )
  ) and public.fn_wm_role_of(subject_uid) in ('super_admin','management','staff');
$$;

create or replace function public.fn_ml_can_view_lead(subject_uid uuid, target_lead uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select subject_uid = auth.uid() and public.fn_wm_is_active(subject_uid) and exists (
    select 1 from public.marketing_leads lead
    where lead.id = target_lead and (
      public.fn_wm_role_of(subject_uid) = 'super_admin'
      or (
        public.fn_ml_has_scope_grant(subject_uid, lead.business_unit_id, lead.department_id)
        and (
          public.fn_wm_role_of(subject_uid) = 'management'
          or lead.assigned_to_profile_id = subject_uid
        )
      )
    )
  );
$$;

create or replace function public.fn_ml_can_manage_lead(subject_uid uuid, target_lead uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.marketing_leads lead
    where lead.id = target_lead
      and public.fn_ml_can_manage_scope(subject_uid, lead.business_unit_id, lead.department_id)
  );
$$;

create or replace function public.fn_ml_can_interact(subject_uid uuid, target_lead uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.fn_ml_can_view_lead(subject_uid, target_lead) and exists (
    select 1 from public.marketing_leads lead where lead.id = target_lead and (
      lead.assigned_to_profile_id = subject_uid
      or public.fn_ml_can_manage_lead(subject_uid, target_lead)
    )
  );
$$;

create or replace function public.fn_ml_initial_response_hours()
returns integer language sql stable security definer set search_path = '' as $$
  select initial_response_hours::integer from public.marketing_lead_settings where singleton;
$$;

create or replace function public.fn_ml_attention_reason(target_lead public.marketing_leads)
returns text language sql stable set search_path = '' as $$
  select case
    when target_lead.status in ('signed_up','not_suitable','withdrawn','closed_other') then null
    when target_lead.last_contact_at is null
      and target_lead.date_received + make_interval(hours => public.fn_ml_initial_response_hours()) < now()
      then 'OVERDUE INITIAL RESPONSE'
    when target_lead.next_follow_up_at < now() then 'OVERDUE FOLLOW-UP'
    when target_lead.next_follow_up_at::date = current_date then 'DUE TODAY'
    when target_lead.last_contact_at is null then 'NEW / UNCONTACTED'
    when target_lead.status = 'consultation_booked'
      and target_lead.consultation_date between now() and now() + interval '7 days'
      then 'CONSULTATION UPCOMING'
    else null
  end;
$$;

create or replace function public.validate_marketing_lead_row()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.departments d where d.id = new.department_id and d.business_unit_id = new.business_unit_id) then
    raise exception using errcode = '22023', message = 'Department must belong to the selected business unit.';
  end if;
  if not public.fn_wm_is_active(new.assigned_to_profile_id) then
    raise exception using errcode = '22023', message = 'Assigned person must be active.';
  end if;
  if public.fn_wm_role_of(new.assigned_to_profile_id) <> 'super_admin' and not exists (
    select 1 from public.marketing_lead_access_grants g
    where g.profile_id = new.assigned_to_profile_id
      and g.business_unit_id = new.business_unit_id and g.department_id = new.department_id
  ) then
    raise exception using errcode = '22023', message = 'Assigned person must have explicit Marketing Lead access for this scope.';
  end if;
  if new.last_contact_at is not null
    and new.status not in ('signed_up','not_suitable','withdrawn','closed_other')
    and new.next_follow_up_at is null then
    raise exception using errcode = '22023', message = 'Open leads require a next follow-up after first contact.';
  end if;
  return new;
end;
$$;

create or replace function public.touch_marketing_lead()
returns trigger language plpgsql security definer set search_path = '' as $$
begin new.updated_at := now(); new.row_version := old.row_version + 1; return new; end;
$$;

create or replace function public.prevent_marketing_lead_history_mutation()
returns trigger language plpgsql security definer set search_path = '' as $$
begin raise exception using errcode = '42501', message = 'Marketing Lead history is append-only.'; end;
$$;

create trigger a_validate_marketing_lead before insert or update on public.marketing_leads
for each row execute function public.validate_marketing_lead_row();
create trigger z_touch_marketing_lead before update on public.marketing_leads
for each row execute function public.touch_marketing_lead();
create trigger prevent_lead_interaction_change before update or delete on public.lead_interactions
for each row execute function public.prevent_marketing_lead_history_mutation();
create trigger prevent_marketing_lead_event_change before update or delete on public.marketing_lead_events
for each row execute function public.prevent_marketing_lead_history_mutation();

alter table public.marketing_lead_sources enable row level security;
alter table public.marketing_lead_settings enable row level security;
alter table public.marketing_lead_access_grants enable row level security;
alter table public.marketing_leads enable row level security;
alter table public.lead_interactions enable row level security;
alter table public.marketing_lead_task_links enable row level security;
alter table public.marketing_lead_events enable row level security;

create policy marketing_lead_sources_select on public.marketing_lead_sources for select to authenticated
  using (is_active and (select public.fn_ml_can_access_module(auth.uid())));
create policy marketing_lead_settings_select on public.marketing_lead_settings for select to authenticated
  using ((select public.fn_wm_role_of(auth.uid())) = 'super_admin');
create policy marketing_lead_access_select on public.marketing_lead_access_grants for select to authenticated
  using (profile_id = (select auth.uid()) or (select public.fn_wm_role_of(auth.uid())) = 'super_admin');
create policy marketing_leads_select on public.marketing_leads for select to authenticated
  using ((select public.fn_ml_can_view_lead(auth.uid(), id)));
create policy lead_interactions_select on public.lead_interactions for select to authenticated
  using ((select public.fn_ml_can_view_lead(auth.uid(), lead_id)));
create policy marketing_lead_task_links_select on public.marketing_lead_task_links for select to authenticated
  using ((select public.fn_ml_can_view_lead(auth.uid(), lead_id)) and (select public.fn_wm_can_view_task(auth.uid(), task_id)));
create policy marketing_lead_events_select on public.marketing_lead_events for select to authenticated
  using ((select public.fn_ml_can_view_lead(auth.uid(), lead_id)));

create or replace function public.search_marketing_leads(
  p_search text default null, p_assigned_to uuid default null,
  p_business_unit_id uuid default null, p_branch text default null,
  p_source_slug text default null, p_campaign_id uuid default null,
  p_status text default null, p_programme_interest text default null,
  p_follow_up_from timestamptz default null, p_follow_up_to timestamptz default null,
  p_received_from timestamptz default null, p_received_to timestamptz default null,
  p_my_leads boolean default false, p_due_only boolean default false,
  p_lead_id uuid default null, p_limit integer default 100
)
returns table (
  id uuid, lead_number text, date_received timestamptz, business_unit_id uuid,
  business_unit_name text, department_id uuid, department_name text, branch text,
  source_slug text, source_label text, campaign_id uuid, campaign_name text,
  project_reference text, name text, contact_number text, email text, country text,
  nationality text, programme_interest text, assigned_to_profile_id uuid,
  assigned_to_name text, status text, last_contact_at timestamptz,
  next_follow_up_at timestamptz, contact_result text, consultation_date timestamptz,
  final_outcome text, estimated_or_actual_value numeric, source_reference_url text,
  remarks text, duplicate_of_lead_id uuid, attention_reason text, updated_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select lead.id, lead.lead_number, lead.date_received, lead.business_unit_id,
    bu.name, lead.department_id, dept.name, lead.branch, lead.source_slug, source.label,
    lead.campaign_id, campaign.name, lead.project_reference, lead.name,
    lead.contact_number, lead.email, lead.country, lead.nationality,
    lead.programme_interest, lead.assigned_to_profile_id,
    coalesce(assignee.full_name, assignee.email), lead.status, lead.last_contact_at,
    lead.next_follow_up_at, lead.contact_result, lead.consultation_date,
    lead.final_outcome, lead.estimated_or_actual_value, lead.source_reference_url,
    lead.remarks, lead.duplicate_of_lead_id, public.fn_ml_attention_reason(lead), lead.updated_at
  from public.marketing_leads lead
  join public.business_units bu on bu.id = lead.business_unit_id
  join public.departments dept on dept.id = lead.department_id
  join public.marketing_lead_sources source on source.slug = lead.source_slug
  join public.profiles assignee on assignee.id = lead.assigned_to_profile_id
  left join public.campaigns campaign on campaign.id = lead.campaign_id
  where public.fn_ml_can_view_lead(auth.uid(), lead.id)
    and (p_lead_id is null or lead.id = p_lead_id)
    and (p_assigned_to is null or lead.assigned_to_profile_id = p_assigned_to)
    and (p_business_unit_id is null or lead.business_unit_id = p_business_unit_id)
    and (p_branch is null or lead.branch = p_branch)
    and (p_source_slug is null or lead.source_slug = p_source_slug)
    and (p_campaign_id is null or lead.campaign_id = p_campaign_id)
    and (p_status is null or lead.status = p_status)
    and (p_programme_interest is null or lead.programme_interest ilike '%' || p_programme_interest || '%')
    and (p_follow_up_from is null or lead.next_follow_up_at >= p_follow_up_from)
    and (p_follow_up_to is null or lead.next_follow_up_at <= p_follow_up_to)
    and (p_received_from is null or lead.date_received >= p_received_from)
    and (p_received_to is null or lead.date_received <= p_received_to)
    and (not p_my_leads or lead.assigned_to_profile_id = auth.uid())
    and (not p_due_only or public.fn_ml_attention_reason(lead) is not null)
    and (p_search is null or lead.lead_number ilike '%' || p_search || '%'
      or lead.name ilike '%' || p_search || '%' or lead.contact_number ilike '%' || p_search || '%'
      or coalesce(lead.email, '') ilike '%' || p_search || '%'
      or lead.programme_interest ilike '%' || p_search || '%')
  order by case public.fn_ml_attention_reason(lead)
      when 'OVERDUE INITIAL RESPONSE' then 1 when 'OVERDUE FOLLOW-UP' then 2
      when 'DUE TODAY' then 3 when 'NEW / UNCONTACTED' then 4
      when 'CONSULTATION UPCOMING' then 5 else 9 end,
    coalesce(lead.next_follow_up_at, lead.date_received), lead.date_received desc
  limit least(greatest(coalesce(p_limit, 100), 1), 200);
$$;

create or replace function public.get_marketing_lead_duplicate_warnings(p_lead_id uuid)
returns table (possible_duplicate_id uuid, lead_number text, name text, reasons text[])
language sql stable security definer set search_path = '' as $$
  select other.id, other.lead_number, other.name,
    array_remove(array[
      case when base.normalized_phone <> '' and base.normalized_phone = other.normalized_phone then 'PHONE' end,
      case when base.normalized_email <> '' and base.normalized_email = other.normalized_email then 'EMAIL' end,
      case when lower(btrim(base.name)) = lower(btrim(other.name))
        and base.normalized_phone = other.normalized_phone then 'NAME + CONTACT' end
    ], null)
  from public.marketing_leads base
  join public.marketing_leads other on other.id <> base.id and other.business_unit_id = base.business_unit_id
  where base.id = p_lead_id and public.fn_ml_can_view_lead(auth.uid(), base.id)
    and public.fn_ml_can_view_lead(auth.uid(), other.id)
    and (base.normalized_phone = other.normalized_phone and base.normalized_phone <> ''
      or base.normalized_email = other.normalized_email and base.normalized_email <> '')
  order by other.date_received desc;
$$;

create or replace function public.get_marketing_lead_summary(p_business_unit_id uuid default null)
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when public.fn_wm_role_of(auth.uid()) not in ('super_admin','management') then
    jsonb_build_object('authorised', false)
  else jsonb_build_object(
    'authorised', true,
    'new_leads', count(*) filter (where lead.status = 'new'),
    'pending_follow_up', count(*) filter (where lead.status not in ('signed_up','not_suitable','withdrawn','closed_other') and lead.next_follow_up_at is not null),
    'overdue', count(*) filter (where public.fn_ml_attention_reason(lead) in ('OVERDUE INITIAL RESPONSE','OVERDUE FOLLOW-UP')),
    'consultations_booked', count(*) filter (where lead.status = 'consultation_booked'),
    'applications', count(*) filter (where lead.status = 'application'),
    'signed_up', count(*) filter (where lead.status = 'signed_up'),
    'by_source', coalesce((select jsonb_object_agg(source_slug, source_count) from (
      select visible.source_slug, count(*) source_count from public.marketing_leads visible
      where public.fn_ml_can_view_lead(auth.uid(), visible.id)
        and (p_business_unit_id is null or visible.business_unit_id = p_business_unit_id)
      group by visible.source_slug
    ) counts), '{}'::jsonb)
  ) end
  from public.marketing_leads lead
  where public.fn_ml_can_view_lead(auth.uid(), lead.id)
    and (p_business_unit_id is null or lead.business_unit_id = p_business_unit_id);
$$;

create or replace function public.get_marketing_lead_audit(p_lead_id uuid)
returns table (event_id bigint, event_type text, actor_id uuid, actor_name text, metadata jsonb, created_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select event.id, event.event_type, event.actor_id,
    coalesce(profile.full_name, profile.email), event.metadata, event.created_at
  from public.marketing_lead_events event join public.profiles profile on profile.id = event.actor_id
  where event.lead_id = p_lead_id and public.fn_ml_can_view_lead(auth.uid(), p_lead_id)
  order by event.created_at desc, event.id desc;
$$;

create or replace function public.create_marketing_lead(
  p_date_received timestamptz, p_business_unit_id uuid, p_department_id uuid,
  p_branch text, p_source_slug text, p_campaign_id uuid, p_project_reference text,
  p_name text, p_contact_number text, p_email text, p_country text, p_nationality text,
  p_programme_interest text, p_assigned_to_profile_id uuid, p_status text,
  p_next_follow_up_at timestamptz, p_consultation_date timestamptz,
  p_estimated_or_actual_value numeric, p_source_reference_url text, p_remarks text,
  p_data_handling_confirmed boolean
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); created_id uuid;
begin
  if not coalesce(p_data_handling_confirmed, false) then
    raise exception using errcode = '22023', message = 'Confirm that lead PII is being entered only in the restricted Lead Register.';
  end if;
  if not public.fn_ml_can_manage_scope(uid, p_business_unit_id, p_department_id) then
    raise exception using errcode = '42501', message = 'Not authorised to create leads in this scope.';
  end if;
  if p_status <> 'new' then raise exception using errcode = '22023', message = 'New lead records must start as New.'; end if;
  if not exists (select 1 from public.marketing_lead_sources where slug = p_source_slug and is_active) then
    raise exception using errcode = '22023', message = 'Choose an active lead source.';
  end if;
  insert into public.marketing_leads (
    date_received,business_unit_id,department_id,branch,source_slug,campaign_id,
    project_reference,name,contact_number,email,country,nationality,programme_interest,
    assigned_to_profile_id,status,next_follow_up_at,consultation_date,
    estimated_or_actual_value,source_reference_url,remarks,created_by
  ) values (
    coalesce(p_date_received,now()),p_business_unit_id,p_department_id,btrim(p_branch),p_source_slug,p_campaign_id,
    nullif(btrim(p_project_reference),''),btrim(p_name),btrim(p_contact_number),nullif(lower(btrim(p_email)),''),
    nullif(btrim(p_country),''),nullif(btrim(p_nationality),''),btrim(p_programme_interest),
    p_assigned_to_profile_id,'new',p_next_follow_up_at,p_consultation_date,p_estimated_or_actual_value,
    nullif(btrim(p_source_reference_url),''),nullif(btrim(p_remarks),''),uid
  ) returning id into created_id;
  insert into public.marketing_lead_events (lead_id,actor_id,event_type,metadata)
    values (created_id,uid,'created',jsonb_build_object('source',p_source_slug,'assigned_to',p_assigned_to_profile_id));
  return created_id;
end;
$$;

create or replace function public.update_marketing_lead(
  p_lead_id uuid, p_business_unit_id uuid, p_department_id uuid, p_branch text,
  p_source_slug text, p_campaign_id uuid, p_project_reference text, p_name text,
  p_contact_number text, p_email text, p_country text, p_nationality text,
  p_programme_interest text, p_assigned_to_profile_id uuid, p_status text,
  p_next_follow_up_at timestamptz, p_consultation_date timestamptz,
  p_final_outcome text, p_estimated_or_actual_value numeric,
  p_source_reference_url text, p_remarks text, p_data_handling_confirmed boolean
)
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); before_row public.marketing_leads%rowtype; closed_before boolean; closed_after boolean;
begin
  if not coalesce(p_data_handling_confirmed, false) then raise exception using errcode='22023', message='Confirm restricted lead-data handling.'; end if;
  if not public.fn_ml_can_manage_lead(uid,p_lead_id) then raise exception using errcode='42501', message='Not authorised to edit this lead.'; end if;
  if not public.fn_ml_can_manage_scope(uid,p_business_unit_id,p_department_id) then raise exception using errcode='42501', message='Selected scope is outside your Lead Register access.'; end if;
  select * into strict before_row from public.marketing_leads where id=p_lead_id for update;
  closed_before := before_row.status in ('signed_up','not_suitable','withdrawn','closed_other');
  closed_after := p_status in ('signed_up','not_suitable','withdrawn','closed_other');
  update public.marketing_leads set business_unit_id=p_business_unit_id,department_id=p_department_id,
    branch=btrim(p_branch),source_slug=p_source_slug,campaign_id=p_campaign_id,
    project_reference=nullif(btrim(p_project_reference),''),name=btrim(p_name),contact_number=btrim(p_contact_number),
    email=nullif(lower(btrim(p_email)),''),country=nullif(btrim(p_country),''),nationality=nullif(btrim(p_nationality),''),
    programme_interest=btrim(p_programme_interest),assigned_to_profile_id=p_assigned_to_profile_id,status=p_status,
    next_follow_up_at=case when closed_after then null else p_next_follow_up_at end,
    consultation_date=p_consultation_date,final_outcome=nullif(btrim(p_final_outcome),''),
    estimated_or_actual_value=p_estimated_or_actual_value,source_reference_url=nullif(btrim(p_source_reference_url),''),
    remarks=nullif(btrim(p_remarks),'') where id=p_lead_id;
  insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata) values
    (p_lead_id,uid,'metadata_updated',jsonb_build_object('scope_changed',before_row.business_unit_id is distinct from p_business_unit_id or before_row.department_id is distinct from p_department_id,'pii_changed',before_row.name is distinct from btrim(p_name) or before_row.contact_number is distinct from btrim(p_contact_number) or before_row.email is distinct from nullif(lower(btrim(p_email)),'')));
  if before_row.assigned_to_profile_id is distinct from p_assigned_to_profile_id then
    insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata) values(p_lead_id,uid,'assigned',jsonb_build_object('from',before_row.assigned_to_profile_id,'to',p_assigned_to_profile_id));
  end if;
  if before_row.status is distinct from p_status then
    insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata) values(p_lead_id,uid,'status_changed',jsonb_build_object('from',before_row.status,'to',p_status));
    if not closed_before and closed_after then insert into public.marketing_lead_events(lead_id,actor_id,event_type) values(p_lead_id,uid,'closed'); end if;
    if closed_before and not closed_after then insert into public.marketing_lead_events(lead_id,actor_id,event_type) values(p_lead_id,uid,'reopened'); end if;
  end if;
end;
$$;

create or replace function public.add_lead_interaction(
  p_lead_id uuid, p_interaction_at timestamptz, p_interaction_type text,
  p_result text, p_next_action text, p_next_follow_up_at timestamptz,
  p_evidence_reference_url text, p_status text
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); interaction_id uuid; before_status text; is_closed boolean;
begin
  if not public.fn_ml_can_interact(uid,p_lead_id) then raise exception using errcode='42501', message='Not authorised to update this lead.'; end if;
  if p_interaction_type not in ('call','whatsapp','email','consultation','walk_in','video_call','event','other') then raise exception using errcode='22023', message='Choose a valid interaction type.'; end if;
  if p_status not in ('contacted','follow_up','consultation_booked','interested','application','signed_up','not_suitable','no_response','withdrawn','closed_other') then raise exception using errcode='22023', message='Choose a valid post-contact status.'; end if;
  is_closed := p_status in ('signed_up','not_suitable','withdrawn','closed_other');
  if not is_closed and p_next_follow_up_at is null then raise exception using errcode='22023', message='Open leads require a next follow-up.'; end if;
  select status into strict before_status from public.marketing_leads where id=p_lead_id for update;
  insert into public.lead_interactions(lead_id,interaction_at,interaction_type,performed_by,result,next_action,next_follow_up_at,evidence_reference_url)
    values(p_lead_id,coalesce(p_interaction_at,now()),p_interaction_type,uid,btrim(p_result),btrim(p_next_action),case when is_closed then null else p_next_follow_up_at end,nullif(btrim(p_evidence_reference_url),'')) returning id into interaction_id;
  update public.marketing_leads set last_contact_at=greatest(coalesce(last_contact_at,'-infinity'::timestamptz),coalesce(p_interaction_at,now())),
    next_follow_up_at=case when is_closed then null else p_next_follow_up_at end,contact_result=btrim(p_result),status=p_status where id=p_lead_id;
  insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata) values(p_lead_id,uid,'interaction_added',jsonb_build_object('interaction_id',interaction_id,'interaction_type',p_interaction_type,'status',p_status));
  if before_status is distinct from p_status then insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata) values(p_lead_id,uid,'status_changed',jsonb_build_object('from',before_status,'to',p_status)); end if;
  return interaction_id;
end;
$$;

create or replace function public.mark_marketing_lead_duplicate(p_duplicate_lead_id uuid,p_canonical_lead_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid:=auth.uid();
begin
  if p_duplicate_lead_id=p_canonical_lead_id then raise exception using errcode='22023', message='A lead cannot duplicate itself.'; end if;
  if not public.fn_ml_can_manage_lead(uid,p_duplicate_lead_id) or not public.fn_ml_can_manage_lead(uid,p_canonical_lead_id) then raise exception using errcode='42501', message='Not authorised to review these leads.'; end if;
  perform 1 from public.marketing_leads where id in(p_duplicate_lead_id,p_canonical_lead_id) order by id for update;
  update public.marketing_leads set duplicate_of_lead_id=p_canonical_lead_id where id=p_duplicate_lead_id;
  insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata) values(p_duplicate_lead_id,uid,'duplicate_marked',jsonb_build_object('canonical_lead_id',p_canonical_lead_id));
end;
$$;

create or replace function public.grant_marketing_lead_access(
  p_profile_id uuid,p_business_unit_id uuid,p_department_id uuid,p_can_manage boolean
)
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid:=auth.uid();
begin
  if uid is null or not public.fn_wm_is_active(uid) or public.fn_wm_role_of(uid)<>'super_admin' then raise exception using errcode='42501', message='Only the Director can grant Marketing Lead access.'; end if;
  if not public.fn_wm_is_active(p_profile_id) then raise exception using errcode='22023', message='Access requires an active profile.'; end if;
  if public.fn_wm_role_of(p_profile_id)='intern' and p_can_manage then raise exception using errcode='22023', message='Intern Lead access cannot include management.'; end if;
  if not exists(select 1 from public.departments d where d.id=p_department_id and d.business_unit_id=p_business_unit_id) then raise exception using errcode='22023', message='Department must belong to business unit.'; end if;
  insert into public.marketing_lead_access_grants(profile_id,business_unit_id,department_id,can_manage,granted_by)
    values(p_profile_id,p_business_unit_id,p_department_id,coalesce(p_can_manage,false),uid)
    on conflict(profile_id,business_unit_id,department_id) do update set can_manage=excluded.can_manage,granted_by=excluded.granted_by,created_at=now();
end;
$$;

create or replace function public.create_lead_followup_task(p_lead_id uuid,p_due_date date,p_priority text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare uid uuid:=auth.uid(); lead public.marketing_leads%rowtype; task_id uuid;
begin
  if not public.fn_ml_can_manage_lead(uid,p_lead_id) then raise exception using errcode='42501', message='Not authorised to create a task for this lead.'; end if;
  select * into strict lead from public.marketing_leads where id=p_lead_id for update;
  task_id := public.create_work_task(lead.business_unit_id,lead.department_id,lead.assigned_to_profile_id,
    lead.project_reference,'Follow up '||lead.lead_number,
    'Follow up the restricted marketing lead using the Lead Register. Do not copy contact details into this task.',
    'Record the outcome in the restricted Lead Register.',false,p_due_date,p_priority,'not_started','appointed_personnel',true);
  insert into public.marketing_lead_task_links(lead_id,task_id,linked_by) values(p_lead_id,task_id,uid);
  insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata) values(p_lead_id,uid,'task_created',jsonb_build_object('task_id',task_id));
  return task_id;
end;
$$;

revoke all on table public.marketing_lead_sources, public.marketing_lead_settings,
  public.marketing_lead_access_grants, public.marketing_leads, public.lead_interactions,
  public.marketing_lead_task_links, public.marketing_lead_events from public,anon,authenticated;
revoke all on sequence public.marketing_lead_number_seq, public.marketing_lead_events_id_seq from public,anon,authenticated;
grant select on table public.marketing_lead_sources,public.marketing_lead_settings,
  public.marketing_lead_access_grants,public.marketing_leads,public.lead_interactions,
  public.marketing_lead_task_links,public.marketing_lead_events to authenticated;

revoke all on function public.fn_ml_next_lead_number() from public,anon,authenticated;
revoke all on function public.fn_ml_has_scope_grant(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.fn_ml_can_access_module(uuid) from public,anon,authenticated;
revoke all on function public.fn_ml_can_manage_scope(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.fn_ml_can_view_lead(uuid,uuid) from public,anon,authenticated;
revoke all on function public.fn_ml_can_manage_lead(uuid,uuid) from public,anon,authenticated;
revoke all on function public.fn_ml_can_interact(uuid,uuid) from public,anon,authenticated;
revoke all on function public.fn_ml_initial_response_hours() from public,anon,authenticated;
revoke all on function public.fn_ml_attention_reason(public.marketing_leads) from public,anon,authenticated;
revoke all on function public.validate_marketing_lead_row() from public,anon,authenticated;
revoke all on function public.touch_marketing_lead() from public,anon,authenticated;
revoke all on function public.prevent_marketing_lead_history_mutation() from public,anon,authenticated;
revoke all on function public.search_marketing_leads(text,uuid,uuid,text,text,uuid,text,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,boolean,uuid,integer) from public,anon;
revoke all on function public.get_marketing_lead_duplicate_warnings(uuid) from public,anon;
revoke all on function public.get_marketing_lead_summary(uuid) from public,anon;
revoke all on function public.get_marketing_lead_audit(uuid) from public,anon;
revoke all on function public.create_marketing_lead(timestamptz,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,uuid,text,timestamptz,timestamptz,numeric,text,text,boolean) from public,anon;
revoke all on function public.update_marketing_lead(uuid,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,uuid,text,timestamptz,timestamptz,text,numeric,text,text,boolean) from public,anon;
revoke all on function public.add_lead_interaction(uuid,timestamptz,text,text,text,timestamptz,text,text) from public,anon;
revoke all on function public.mark_marketing_lead_duplicate(uuid,uuid) from public,anon;
revoke all on function public.grant_marketing_lead_access(uuid,uuid,uuid,boolean) from public,anon;
revoke all on function public.create_lead_followup_task(uuid,date,text) from public,anon;

grant execute on function public.fn_ml_can_access_module(uuid),public.fn_ml_can_manage_lead(uuid,uuid),
  public.fn_ml_can_interact(uuid,uuid),public.search_marketing_leads(text,uuid,uuid,text,text,uuid,text,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,boolean,uuid,integer),
  public.get_marketing_lead_duplicate_warnings(uuid),public.get_marketing_lead_summary(uuid),
  public.get_marketing_lead_audit(uuid),
  public.create_marketing_lead(timestamptz,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,uuid,text,timestamptz,timestamptz,numeric,text,text,boolean),
  public.update_marketing_lead(uuid,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,uuid,text,timestamptz,timestamptz,text,numeric,text,text,boolean),
  public.add_lead_interaction(uuid,timestamptz,text,text,text,timestamptz,text,text),
  public.mark_marketing_lead_duplicate(uuid,uuid),public.grant_marketing_lead_access(uuid,uuid,uuid,boolean),
  public.create_lead_followup_task(uuid,date,text) to authenticated;
