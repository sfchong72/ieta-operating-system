# Test Plan

## v1 success scenario (manual)
1. Open app without login → Dashboard renders with seed data (ideas, tasks, SOPs visible)
2. Navigate to SOPs → see seeded SOPs → click one → master Drive link opens
3. Navigate to Content Ideas → see seeded ideas → click "New Idea" → enter title + platform → save → appears in list
4. Navigate to Tasks → see seeded tasks → click "New Task" → select idea, enter PIC name, deadline, platform → save
5. Open the new task → attach Canva link → status auto-moves to `in_progress` → activity logged
6. Click "Submit for Review" → status `submitted` → appears in Dashboard "Pending Approval"
7. Open task as manager → set approval_status to approved + remark → status `approved`
8. Click "Mark Posted" → enter Instagram URL + date → status `posted` → activity logged
9. Dashboard reflects updated counts: posted +1, pending approval -1
10. Open Knowledge Base → create a reusable item → verify it appears in list

## Empty/error states
- **No tasks:** Dashboard shows "No tasks yet — create your first content task" with a CTA button
- **No SOPs:** SOPs page shows "No SOPs yet — add your first procedure" with CTA
- **Invalid URL on work link:** form shows inline error "Please enter a valid URL"
- **Task with no PIC:** save blocked, inline error "PIC name is required"
- **Delete confirmation:** modal asks "Delete this task? This cannot be undone" — confirm/cancel
- **Network error on save:** toast "Could not save — check connection and try again" with retry
- **Empty dashboard:** all count cards show 0, lists show empty-state messages

## Data-integrity checks
- Create task without idea_id → saves fine (standalone task)
- Delete a task with work_files → work_files remain orphaned (cascade not required v1, cleanup later)
- Change status out of order (e.g. posted → assigned) → allowed but activity logged with actor
