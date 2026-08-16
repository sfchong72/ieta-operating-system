create table if not exists departments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists sops (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  department_id uuid references departments(id) on delete set null,
  master_drive_link text,
  version text default 'v1',
  content text,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists content_ideas (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  platform text,
  topic text,
  status text default 'idea',
  suggested_tags text,
  tags_source text,
  tags_confidence numeric,
  tags_review_status text default 'unreviewed',
  user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists content_tasks (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid references content_ideas(id) on delete set null,
  title text not null,
  department_id uuid references departments(id) on delete set null,
  pic_name text not null,
  platform text,
  deadline date,
  status text not null default 'assigned',
  work_link text,
  approval_status text,
  approval_remarks text,
  posted_url text,
  posted_date date,
  remarks text,
  priority_score numeric,
  priority_source text,
  priority_confidence numeric,
  priority_review_status text default 'unreviewed',
  user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists work_files (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references content_tasks(id) on delete cascade,
  label text,
  url text not null,
  file_type text,
  user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists knowledge_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,
  body text,
  tags text[],
  user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists activities (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references content_tasks(id) on delete cascade,
  action text not null,
  actor_name text,
  detail text,
  user_id uuid,
  created_at timestamptz not null default now()
);

alter table departments enable row level security;
drop policy if exists "departments_v1_read" on departments;
create policy "departments_v1_read" on departments for select using (true);
drop policy if exists "departments_v1_write" on departments;
create policy "departments_v1_write" on departments for all using (true) with check (true);

alter table sops enable row level security;
drop policy if exists "sops_v1_read" on sops;
create policy "sops_v1_read" on sops for select using (true);
drop policy if exists "sops_v1_write" on sops;
create policy "sops_v1_write" on sops for all using (true) with check (true);

alter table content_ideas enable row level security;
drop policy if exists "content_ideas_v1_read" on content_ideas;
create policy "content_ideas_v1_read" on content_ideas for select using (true);
drop policy if exists "content_ideas_v1_write" on content_ideas;
create policy "content_ideas_v1_write" on content_ideas for all using (true) with check (true);

alter table content_tasks enable row level security;
drop policy if exists "content_tasks_v1_read" on content_tasks;
create policy "content_tasks_v1_read" on content_tasks for select using (true);
drop policy if exists "content_tasks_v1_write" on content_tasks;
create policy "content_tasks_v1_write" on content_tasks for all using (true) with check (true);

alter table work_files enable row level security;
drop policy if exists "work_files_v1_read" on work_files;
create policy "work_files_v1_read" on work_files for select using (true);
drop policy if exists "work_files_v1_write" on work_files;
create policy "work_files_v1_write" on work_files for all using (true) with check (true);

alter table knowledge_items enable row level security;
drop policy if exists "knowledge_items_v1_read" on knowledge_items;
create policy "knowledge_items_v1_read" on knowledge_items for select using (true);
drop policy if exists "knowledge_items_v1_write" on knowledge_items;
create policy "knowledge_items_v1_write" on knowledge_items for all using (true) with check (true);

alter table activities enable row level security;
drop policy if exists "activities_v1_read" on activities;
create policy "activities_v1_read" on activities for select using (true);
drop policy if exists "activities_v1_write" on activities;
create policy "activities_v1_write" on activities for all using (true) with check (true);

insert into departments (id, name, slug) values
  ('a0000000-0000-0000-0000-000000000001', 'Marketing', 'marketing'),
  ('a0000000-0000-0000-0000-000000000002', 'Design', 'design'),
  ('a0000000-0000-0000-0000-000000000003', 'Video', 'video'),
  ('a0000000-0000-0000-0000-000000000004', 'Operations', 'operations')
on conflict do nothing;

insert into sops (id, title, department_id, master_drive_link, version, content) values
  ('b0000000-0000-0000-0000-000000000001', 'Instagram Reel Production SOP', 'a0000000-0000-0000-0000-000000000001', 'https://drive.google.com/drive/folders/reel-sop-master', 'v2', 'Steps: 1) Script 2) Record 3) Edit in Canva 4) Caption 5) Submit for approval 6) Post'),
  ('b0000000-0000-0000-0000-000000000002', 'Canva Poster Design SOP', 'a0000000-0000-0000-0000-000000000002', 'https://drive.google.com/drive/folders/poster-sop-master', 'v1', 'Steps: 1) Get brief 2) Open Canva template 3) Apply brand kit 4) Export PNG 5) Submit link'),
  ('b0000000-0000-0000-0000-000000000003', 'TikTok Video Editing SOP', 'a0000000-0000-0000-0000-000000000003', 'https://drive.google.com/drive/folders/tiktok-sop-master', 'v1', 'Steps: 1) Raw footage 2) CapCut edit 3) Add captions 4) Sound 5) Export 6) Submit')
on conflict do nothing;

insert into content_ideas (id, title, platform, topic, status, suggested_tags, tags_source, tags_confidence, tags_review_status) values
  ('c0000000-0000-0000-0000-000000000001', 'IETA Welcome Day Reel', 'Instagram', 'onboarding', 'tasked', 'welcome,reel,onboarding', 'rule', 0.85, 'unreviewed'),
  ('c0000000-0000-0000-0000-000000000002', 'Student Testimonial TikTok', 'TikTok', 'testimonial', 'tasked', 'testimonial,student,tiktok', 'rule', 0.80, 'unreviewed'),
  ('c0000000-0000-0000-0000-000000000003', 'PLC Program Launch Poster', 'Facebook', 'announcement', 'idea', 'launch,poster,announcement', 'rule', 0.75, 'unreviewed'),
  ('c0000000-0000-0000-0000-000000000004', 'Behind the Scenes Video', 'YouTube', 'culture', 'idea', 'bts,culture,youtube', 'rule', 0.70, 'unreviewed'),
  ('c0000000-0000-0000-0000-000000000005', 'Weekly Tips Carousel', 'Instagram', 'educational', 'idea', 'tips,carousel,educational', 'rule', 0.72, 'unreviewed')
on conflict do nothing;

insert into content_tasks (id, idea_id, title, department_id, pic_name, platform, deadline, status, work_link, approval_status, approval_remarks, posted_url, posted_date, remarks, priority_score, priority_source, priority_confidence, priority_review_status) values
  ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'IETA Welcome Day Reel', 'a0000000-0000-0000-0000-000000000001', 'Aisyah', 'Instagram', '2025-01-20', 'in_progress', 'https://canva.com/design/welcome-reel-draft', null, null, null, null, 'Draft in progress', 0.82, 'rule', 0.90, 'unreviewed'),
  ('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000002', 'Student Testimonial TikTok', 'a0000000-0000-0000-0000-000000000003', 'Hafiz', 'TikTok', '2025-01-18', 'submitted', 'https://drive.google.com/file/testimonial-edit', 'pending', null, null, null, 'Ready for review', 0.88, 'rule', 0.92, 'unreviewed'),
  ('d0000000-0000-0000-0000-000000000003', null, 'Monthly Newsletter Poster', 'a0000000-0000-0000-0000-000000000002', 'Nadia', 'Facebook', '2025-01-25', 'assigned', null, null, null, null, null, 'Need brief from manager', 0.50, 'rule', 0.70, 'unreviewed'),
  ('d0000000-0000-0000-0000-000000000004', null, 'Open Day Promo Video', 'a0000000-0000-0000-0000-000000000003', 'Hafiz', 'YouTube', '2025-01-15', 'posted', 'https://drive.google.com/file/openday-final', 'approved', 'Good work, posted as is', 'https://youtube.com/shorts/openday2025', '2025-01-14', 'Posted successfully', 0.95, 'rule', 0.95, 'unreviewed'),
  ('d0000000-0000-0000-0000-000000000005', null, 'CNY Greeting Poster', 'a0000000-0000-0000-0000-000000000002', 'Nadia', 'Instagram', '2025-01-22', 'amendment', 'https://canva.com/design/cny-poster-v2', 'amend', 'Change red to brand red, not bright red', null, null, 'Revision needed', 0.78, 'rule', 0.88, 'unreviewed')
on conflict do nothing;

insert into work_files (id, task_id, label, url, file_type) values
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'Welcome Reel Draft', 'https://canva.com/design/welcome-reel-draft', 'canva'),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000002', 'Testimonial Edit', 'https://drive.google.com/file/testimonial-edit', 'drive'),
  ('e0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000004', 'Open Day Final', 'https://drive.google.com/file/openday-final', 'drive')
on conflict do nothing;

insert into knowledge_items (id, title, category, body, tags) values
  ('f0000000-0000-0000-0000-000000000001', 'IETA Brand Colors', 'Branding', 'Primary: #1a5632, Secondary: #f0a500, Accent: #ffffff. Use across all Canva templates.', array['branding','colors','canva']),
  ('f0000000-0000-0000-0000-000000000002', 'Instagram Caption Guide', 'Copywriting', 'Keep captions under 125 chars in first line. Use 3-5 hashtags. End with a CTA question.', array['instagram','caption','copywriting']),
  ('f0000000-0000-0000-0000-000000000003', 'Video Export Settings', 'Technical', 'Reels: 1080x1920, 30fps, H.264. TikTok: same. YouTube Shorts: 1080x1920, 60fps.', array['video','export','settings'])
on conflict do nothing;

insert into activities (id, task_id, action, actor_name, detail) values
  ('1e000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'created', 'Aisyah', 'Task created from idea: IETA Welcome Day Reel'),
  ('1e000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000001', 'link_attached', 'Aisyah', 'Canva link attached'),
  ('1e000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000002', 'created', 'Hafiz', 'Task created from idea: Student Testimonial TikTok'),
  ('1e000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000002', 'submitted', 'Hafiz', 'Submitted for review'),
  ('1e000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000004', 'approved', 'Manager Siti', 'Approved with no changes'),
  ('1e000000-0000-0000-0000-000000000006', 'd0000000-0000-0000-0000-000000000004', 'posted', 'Hafiz', 'Posted to YouTube Shorts')
on conflict do nothing;