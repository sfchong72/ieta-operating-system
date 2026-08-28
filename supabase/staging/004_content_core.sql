-- STAGING ONLY. See supabase/staging/README.md.
-- Milestone 3: Content Core — campaigns, content_items (collapses
-- content_ideas + content_tasks), platform_publications.
-- Old content_ideas/content_tasks tables are left untouched (additive-only
-- convention) but content_items becomes the primary Planner data source.

create table staging.campaigns (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid references staging.business_units(id),
  department_id uuid references staging.departments(id),
  name text not null,
  description text,
  status text not null default 'active' check (status in ('active','completed','archived')),
  start_date date,
  end_date date,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.content_items (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid references staging.business_units(id),
  department_id uuid references staging.departments(id),
  campaign_id uuid references staging.campaigns(id) on delete set null,

  -- basic info
  title text not null,
  content_type text,
  language text,
  target_audience text,
  priority text check (priority in ('low','medium','high') or priority is null),
  pic_name text,
  due_date date,

  -- workflow
  status text not null default 'draft' check (status in (
    'draft','in_progress','awaiting_approval','revision_required',
    'approved','scheduled_publishing','published','archived'
  )),
  approval_status text check (approval_status in ('pending','approved','amend') or approval_status is null),
  approval_remarks text,

  -- creative content
  on_screen_wording text,
  main_caption text,
  cta text,
  hashtags text,
  media_drive_link text,
  canva_link text,
  final_artwork_link text,

  -- rule-based AI fields, carried over from content_ideas/content_tasks
  suggested_tags text,
  tags_source text,
  tags_confidence numeric,
  tags_review_status text default 'unreviewed',
  priority_score numeric,
  priority_source text,
  priority_confidence numeric,
  priority_review_status text default 'unreviewed',

  remarks text,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table staging.platform_publications (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references staging.content_items(id) on delete cascade,
  platform text not null check (platform in ('instagram','facebook','tiktok','youtube_shorts','other')),
  status text not null default 'scheduled' check (status in ('not_required','scheduled','published')),
  intended_date date,
  published_at timestamptz,
  published_url text,
  published_by uuid references staging.profiles(id),
  caption_override text,
  media_override_link text,
  user_id uuid,
  created_at timestamptz not null default now(),
  unique (content_item_id, platform)
);

-- ── RLS: same department/business-unit-scoped pattern as content_tasks ──────

alter table staging.campaigns enable row level security;
create policy "staging_campaigns_select" on staging.campaigns
  for select using (staging.fn_has_department_access(auth.uid(), department_id));
create policy "staging_campaigns_write" on staging.campaigns
  for all
  using (staging.fn_role(auth.uid()) in ('super_admin','management'))
  with check (staging.fn_role(auth.uid()) in ('super_admin','management'));

alter table staging.content_items enable row level security;
create policy "staging_content_items_select" on staging.content_items
  for select using (
    auth.uid() is not null
    and (department_id is null or staging.fn_has_department_access(auth.uid(), department_id))
  );
create policy "staging_content_items_insert" on staging.content_items
  for insert with check (
    auth.uid() is not null
    and (department_id is null or staging.fn_has_department_access(auth.uid(), department_id))
    and (staging.fn_role(auth.uid()) != 'intern' or user_id = auth.uid())
  );
create policy "staging_content_items_update" on staging.content_items
  for update using (
    auth.uid() is not null
    and (department_id is null or staging.fn_has_department_access(auth.uid(), department_id))
    and (staging.fn_role(auth.uid()) not in ('intern') or user_id = auth.uid())
  );
create policy "staging_content_items_delete" on staging.content_items
  for delete using (staging.fn_is_super_admin(auth.uid()) or staging.fn_is_management(auth.uid()));

alter table staging.platform_publications enable row level security;
create policy "staging_platform_publications_select" on staging.platform_publications
  for select using (
    staging.fn_has_department_access(auth.uid(), (select department_id from staging.content_items where id = content_item_id))
  );
create policy "staging_platform_publications_write" on staging.platform_publications
  for all
  using (
    staging.fn_has_department_access(auth.uid(), (select department_id from staging.content_items where id = content_item_id))
  )
  with check (
    staging.fn_has_department_access(auth.uid(), (select department_id from staging.content_items where id = content_item_id))
  );
