# Data Model

## departments
- `id` uuid PK
- `name` text not null
- `slug` text unique
- `created_at` timestamptz default now()
- `user_id` uuid nullable

## sops
- `id` uuid PK
- `title` text not null
- `department_id` uuid → departments.id
- `master_drive_link` text
- `version` text default 'v1'
- `content` text
- `created_at` timestamptz default now()
- `user_id` uuid nullable

## content_ideas
- `id` uuid PK
- `title` text not null
- `platform` text (Instagram, TikTok, YouTube, Facebook)
- `topic` text
- `status` text default 'idea' (idea, selected, tasked, archived)
- `suggested_tags` text  — AI field
- `tags_source` text — AI field
- `tags_confidence` numeric — AI field
- `tags_review_status` text default 'unreviewed' — AI field
- `created_at` timestamptz default now()
- `user_id` uuid nullable

## content_tasks (core engine)
- `id` uuid PK
- `idea_id` uuid nullable → content_ideas.id
- `title` text not null
- `department_id` uuid → departments.id
- `pic_name` text not null
- `platform` text
- `deadline` date
- `status` text not null default 'assigned'
  (assigned → in_progress → submitted → approved → amendment → posted)
- `work_link` text
- `approval_status` text (pending, approved, amend)
- `approval_remarks` text
- `posted_url` text
- `posted_date` date
- `remarks` text
- `priority_score` numeric — AI field
- `priority_source` text — AI field
- `priority_confidence` numeric — AI field
- `priority_review_status` text default 'unreviewed' — AI field
- `created_at` timestamptz default now()
- `user_id` uuid nullable

## work_files
- `id` uuid PK
- `task_id` uuid → content_tasks.id
- `label` text
- `url` text not null
- `file_type` text (drive, canva, other)
- `created_at` timestamptz default now()
- `user_id` uuid nullable

## knowledge_items
- `id` uuid PK
- `title` text not null
- `category` text
- `body` text
- `tags` text[]
- `created_at` timestamptz default now()
- `user_id` uuid nullable

## activities
- `id` uuid PK
- `task_id` uuid → content_tasks.id
- `action` text not null (created, status_changed, link_attached, approved, posted)
- `actor_name` text
- `detail` text
- `created_at` timestamptz default now()
- `user_id` uuid nullable

## RLS notes
All tables have RLS enabled. v1: permissive read/write for demo without login. Lock-down sprint: `auth.uid() = user_id` scoped policies.
