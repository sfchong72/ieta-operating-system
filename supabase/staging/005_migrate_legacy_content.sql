-- STAGING ONLY. See supabase/staging/README.md.
-- Backfills content_ideas + content_tasks into content_items +
-- platform_publications, preserving them as visible sample content rather
-- than leaving them orphaned. Old tables are untouched (read-only source).
--
-- Mapping:
--   content_task WITH idea_id  -> one content_item, merging task (primary)
--                                  + idea (tags) data
--   content_task WITHOUT idea_id (standalone) -> one content_item from task
--   content_idea NOT referenced by any content_task -> one content_item,
--                                  status 'draft', no PIC yet
-- Status mapping: assigned->in_progress, in_progress->in_progress,
--   submitted->awaiting_approval, approved->approved,
--   amendment->revision_required, posted->published

-- Step 1: content_items from every content_task (merged with its idea's
-- tags when linked), tracking old_task_id/old_idea_id for the platform_publications pass.
create temp table _migration_map (
  content_item_id uuid,
  old_task_id uuid,
  old_idea_id uuid,
  platform text,
  status text,
  work_link text,
  posted_url text,
  posted_date date
);

insert into _migration_map (content_item_id, old_task_id, old_idea_id, platform, status, work_link, posted_url, posted_date)
select
  gen_random_uuid(),
  t.id,
  t.idea_id,
  t.platform,
  t.status,
  t.work_link,
  t.posted_url,
  t.posted_date
from staging.content_tasks t;

insert into staging.content_items (
  id, department_id, title, pic_name, due_date, status,
  approval_status, approval_remarks, canva_link, media_drive_link,
  suggested_tags, tags_source, tags_confidence, tags_review_status,
  priority_score, priority_source, priority_confidence, priority_review_status,
  remarks, created_at
)
select
  m.content_item_id,
  t.department_id,
  t.title,
  t.pic_name,
  t.deadline,
  case t.status
    when 'assigned' then 'in_progress'
    when 'in_progress' then 'in_progress'
    when 'submitted' then 'awaiting_approval'
    when 'approved' then 'approved'
    when 'amendment' then 'revision_required'
    when 'posted' then 'published'
    else 'draft'
  end,
  t.approval_status,
  t.approval_remarks,
  case when t.work_link ilike '%canva.com%' then t.work_link end,
  case when t.work_link ilike '%drive.google.com%' then t.work_link end,
  i.suggested_tags, i.tags_source, i.tags_confidence, i.tags_review_status,
  t.priority_score, t.priority_source, t.priority_confidence, t.priority_review_status,
  t.remarks,
  t.created_at
from staging.content_tasks t
join _migration_map m on m.old_task_id = t.id
left join staging.content_ideas i on i.id = t.idea_id;

-- Step 2: content_items from content_ideas that were never turned into a task.
insert into staging.content_items (
  id, title, status, suggested_tags, tags_source, tags_confidence, tags_review_status, created_at
)
select gen_random_uuid(), i.title, 'draft', i.suggested_tags, i.tags_source, i.tags_confidence, i.tags_review_status, i.created_at
from staging.content_ideas i
where not exists (select 1 from staging.content_tasks t where t.idea_id = i.id);

-- Step 3: one platform_publications row per migrated task-derived content_item.
insert into staging.platform_publications (content_item_id, platform, status, intended_date, published_at, published_url)
select
  m.content_item_id,
  case m.platform
    when 'Instagram' then 'instagram'
    when 'TikTok' then 'tiktok'
    when 'Facebook' then 'facebook'
    when 'YouTube' then 'youtube_shorts'
    else 'other'
  end,
  case when m.status = 'posted' then 'published' else 'scheduled' end,
  case when m.status != 'posted' then (select due_date from staging.content_items where id = m.content_item_id) end,
  case when m.status = 'posted' then m.posted_date::timestamptz end,
  m.posted_url
from _migration_map m
where m.platform is not null;

drop table _migration_map;
