# IE Operating System — PRD

## Problem
IETA staff lose files in scattered Google Drive folders, duplicate Canva projects, report task progress via vague WhatsApp messages, and wait for supervisors to re-explain SOPs daily. There is no single place to see who is doing what, what is delayed, what needs approval, or where every file lives.

## Target user
Director, manager, training manager, executive, marketing/content interns, design/video interns. First active users: IETA content team handling SOPs, design, video editing, social media planning.

## Core objects
- **Department** — grouping for SOPs and tasks (Marketing, Design, Video, Operations)
- **SOP** — titled procedure with a master Drive link, version, owning department
- **ContentIdea** — a content idea with platform, topic, status
- **ContentTask** — the core engine: an idea assigned to a PIC with deadline, status, work-link, approval status, posting result
- **WorkFile** — a Drive or Canva link attached to a task
- **KnowledgeItem** — reusable KB entry (title, category, body, tags)
- **Activity** — audit trail entry per task action

## MVP (v1) — must-haves
- [ ] List, create, edit, delete SOPs with master file links
- [ ] List and create content ideas (50 visible on first load via seed + user additions)
- [ ] Create, assign, update content tasks: PIC, deadline, platform, status, work link, remarks
- [ ] Submit task for review → approve/amend → mark posted (with posted URL + date)
- [ ] Dashboard: tasks by status, delayed tasks, approvals pending, who-is-doing-what
- [ ] Knowledge base: list, create, edit, delete reusable items
- [ ] Activity trail on every task status change
- [ ] All above viewable and editable without login (demo-first)

## Non-goals (v1)
No mobile app. No payroll. No full HR. No student CRM. No finance/invoice. No auto-posting to social platforms. No replacing Google Drive or Canva — app only organises links. No complex role permissions beyond simple role labels.

## Success criteria
A marketing intern opens IEOS, finds the Marketing department, locates the "Instagram Reel SOP" and its master Drive link, picks an assigned content task, attaches their Canva work link, submits for review. The manager sees the task in "Pending Approval," reviews it, marks it approved with a remark. The intern marks it posted with the live Instagram URL and date. The dashboard reflects the full pipeline: 50 ideas visible, 8 in progress, 2 pending approval, 5 posted. No WhatsApp report was sent.
