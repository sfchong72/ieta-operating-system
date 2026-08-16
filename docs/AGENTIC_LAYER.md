# Agentic Layer

## Draftable actions (low risk — auto)
- Auto-detect file type from pasted URL (drive vs canva)
- Auto-fill `platform` from task title keywords
- Calculate priority_score from rules
- Generate suggested_tags for content ideas

## Executable after approval (medium risk)
- Auto-draft approval remarks from task history + remarks
- Auto-suggest PIC based on current workload count
- Auto-archive content idea when all linked tasks are posted

## Human-only (high/critical risk)
- Delete any SOP, task, idea, or knowledge item
- Change approval_status to "approved" or "amend"
- Mark task as posted (entering live URL)
- Reassign a task to a different PIC

## Named tools
- `detect_file_type(url)` → returns drive | canva | other
- `compute_priority_score(task)` → returns 0–1 + reason
- `suggest_tags(idea_text)` → returns string array + confidence
- `draft_approval_remark(task)` → returns text draft (later)
- `suggest_pic(department_id)` → returns name + workload count (later)

## Audit-log fields
Every agentic action logs: `action`, `actor_name` ("system" for auto), `detail` (JSON of inputs/outputs), `task_id`, `created_at`, `user_id`.

## v1 vs later
**v1:** detect_file_type, compute_priority_score, suggest_tags (rule-based, no external AI call).
**Later:** draft_approval_remark, suggest_pic, full agentic task creation from idea text.
