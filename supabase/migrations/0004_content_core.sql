-- IEOS Milestone 3: Content Core — campaigns, content_items (collapses
-- content_ideas + content_tasks going forward), platform_publications.
-- NOT YET APPLIED — validated in `staging` first. Do not run against
-- production until explicitly approved.
--
-- Additive: old content_ideas/content_tasks tables are left completely
-- untouched (still readable/functional for the existing /ideas, /tasks
-- screens). content_items becomes the new Planner data source. Existing
-- demo data is migrated into content_items as a SEPARATE, explicit backfill
-- step at cutover time (not part of this schema migration), matching how
-- Claire/Hailey's profile rows were backfilled after 0003.

create table campaigns (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid references business_units(id),
  department_id uuid references departments(id),
  name text not null,
  description text,
  status text not null default 'active' check (status in ('active','completed','archived')),
  start_date date,
  end_date date,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table content_items (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid references business_units(id),
  department_id uuid references departments(id),
  campaign_id uuid references campaigns(id) on delete set null,
  title text not null,
  content_type text,
  language text,
  target_audience text,
  priority text check (priority in ('low','medium','high') or priority is null),
  pic_name text,
  due_date date,
  status text not null default 'draft' check (status in (
    'draft','in_progress','awaiting_approval','revision_required',
    'approved','scheduled_publishing','published','archived'
  )),
  approval_status text check (approval_status in ('pending','approved','amend') or approval_status is null),
  approval_remarks text,
  on_screen_wording text,
  main_caption text,
  cta text,
  hashtags text,
  media_drive_link text,
  canva_link text,
  final_artwork_link text,
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

create table platform_publications (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references content_items(id) on delete cascade,
  platform text not null check (platform in ('instagram','facebook','tiktok','youtube_shorts','other')),
  status text not null default 'scheduled' check (status in ('not_required','scheduled','published')),
  intended_date date,
  published_at timestamptz,
  published_url text,
  published_by uuid references profiles(id),
  caption_override text,
  media_override_link text,
  user_id uuid,
  created_at timestamptz not null default now(),
  unique (content_item_id, platform)
);

-- ── RLS: same department/business-unit-scoped pattern as content_tasks,
--    with the "no unauthenticated access" fix applied from the start
--    (matches the fix already made to business_units/content_ideas). ───────

alter table campaigns enable row level security;
create policy "campaigns_select" on campaigns
  for select using (auth.uid() is not null and fn_has_department_access(auth.uid(), department_id));
create policy "campaigns_write" on campaigns
  for all
  using (fn_role(auth.uid()) in ('super_admin','management'))
  with check (fn_role(auth.uid()) in ('super_admin','management'));

alter table content_items enable row level security;
create policy "content_items_select" on content_items
  for select using (
    auth.uid() is not null
    and (department_id is null or fn_has_department_access(auth.uid(), department_id))
  );
create policy "content_items_insert" on content_items
  for insert with check (
    auth.uid() is not null
    and (department_id is null or fn_has_department_access(auth.uid(), department_id))
    and (fn_role(auth.uid()) != 'intern' or user_id = auth.uid())
  );
create policy "content_items_update" on content_items
  for update using (
    auth.uid() is not null
    and (department_id is null or fn_has_department_access(auth.uid(), department_id))
    and (fn_role(auth.uid()) not in ('intern') or user_id = auth.uid())
  );
create policy "content_items_delete" on content_items
  for delete using (fn_is_super_admin(auth.uid()) or fn_is_management(auth.uid()));

alter table platform_publications enable row level security;
create policy "platform_publications_select" on platform_publications
  for select using (
    auth.uid() is not null
    and fn_has_department_access(auth.uid(), (select department_id from content_items where id = content_item_id))
  );
create policy "platform_publications_write" on platform_publications
  for all
  using (
    auth.uid() is not null
    and fn_has_department_access(auth.uid(), (select department_id from content_items where id = content_item_id))
  )
  with check (
    auth.uid() is not null
    and fn_has_department_access(auth.uid(), (select department_id from content_items where id = content_item_id))
  );
