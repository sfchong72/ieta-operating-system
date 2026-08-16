# Intelligence Layer

## Messy inputs
- Intern pastes a raw Canva link with no label
- Task title is vague ("do the reel")
- Content idea submitted with no platform
- Remarks field has free-text updates

## Auto-structure schema
```json
{
  "task_title_clean": "IETA Welcome Reel — Instagram",
  "platform_detected": "instagram",
  "file_type_detected": "canva",
  "suggested_tags": ["onboarding", "reel", "welcome"],
  "priority_score": 0.82,
  "priority_reason": "deadline in 2 days + high-priority department"
}
```

## Events to track
- task.created → log activity, score priority
- task.status_changed → log activity, update dashboard counts
- task.link_attached → detect file type from URL
- task.submitted → notify approver (later)
- task.posted → archive idea if all tasks done

## Scoring rules (rule-based v1)
- Deadline ≤ 2 days and status not submitted → +0.4
- Status = submitted and approval pending > 1 day → +0.3
- No work link attached and status = in_progress → +0.2
- Department = Marketing → +0.1
- Score range 0–1; ≥ 0.7 flagged "urgent" on dashboard

## What gets ranked
Content tasks ranked by priority_score desc on dashboard "Attention Needed" panel.

## v1 vs later
**v1:** Rule-based priority scoring, URL file-type detection, simple title cleanup.
**Later:** AI tag suggestions, auto-draft approval remarks, smart PIC suggestions based on workload, content idea clustering.
