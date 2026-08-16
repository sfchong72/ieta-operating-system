# Architecture

## Stack
Next.js (App Router) + Supabase (Postgres + RLS) + Vercel.

## Build now vs later
**Now (v1):** Departments, SOPs, content ideas, content tasks with full lifecycle, work-file links, knowledge base, activity trail, dashboard. Viewable without login.
**Later:** Auth + per-user RLS, smart auto-tagging & priority scoring, agentic draft actions (auto-fill remarks, suggest PIC), PLC team expansion, posting integrations.

## Key user-action flow (the core engine)
1. Intern opens Dashboard → sees "Pending Tasks" for their name
2. Opens a content task → views linked SOP + master file
3. Attaches Canva/Drive work link → status moves to `in_progress`
4. Submits for review → status `submitted` → activity logged
5. Manager sees task in "Pending Approval" → approves or sends back with remarks
6. Intern marks posted → enters live URL + posted date → status `posted` → activity logged
7. Dashboard updates counts instantly

## Responsive nav shell
Persistent left sidebar on desktop (Dashboard, SOPs, Content Ideas, Tasks, Knowledge Base). Collapses to hamburger menu on mobile. Current section highlighted. Keyboard accessible.

## Layer plan
1. **Data layer** — Supabase tables, RLS (permissive v1), data-access module (`lib/data/`) handling all reads/writes
2. **App logic** — server actions for task lifecycle transitions, validation, activity logging
3. **Smart features** — auto-tagging ideas, priority scoring (rule-based first, AI later) in `lib/ai/`

## Why the core runs without AI
Task lifecycle, SOP retrieval, file linking, approvals, and dashboard are pure database CRUD + server logic. Smart features are additive — the app is fully functional with them disabled.

## Repo structure
```
app/                    # routes & UI
  dashboard/
  sops/
  ideas/
  tasks/
  knowledge/
components/             # shared UI
lib/data/               # ALL Supabase queries (single data-access layer)
lib/actions/            # server actions (task transitions, CRUD)
lib/ai/                 # tagging, scoring (later)
__tests__/              # tests beside features
```

## Module map
| Module | Responsibility | Owns | Build order |
|---|---|---|---|
| data | All DB reads/writes | Supabase client, typed queries | 1st |
| sops | SOP CRUD + file links | sops table | 2nd |
| content | Ideas + tasks + lifecycle + approvals | content_ideas, content_tasks, work_files, activities | 3rd (core engine) |
| knowledge | KB CRUD | knowledge_items | 4th |
| dashboard | Aggregated views + filters | reads from all tables | 5th |
| ai | Auto-tag, priority score | (later) | 6th |
