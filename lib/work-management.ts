export const WORK_STATUSES = ["backlog", "not_started", "in_progress", "waiting_feedback", "blocked", "on_hold", "completed", "cancelled"] as const;
export const WORK_PRIORITIES = ["urgent", "high", "medium", "low"] as const;
export const ARTIFACT_TYPES = ["working", "final", "evidence", "reference"] as const;
export const ARTIFACT_SENSITIVITIES = ["operational", "appointed_personnel", "full_time_only", "management_only", "pc_restricted"] as const;

export type WorkStatus = (typeof WORK_STATUSES)[number];
export type WorkPriority = (typeof WORK_PRIORITIES)[number];
export type ArtifactType = (typeof ARTIFACT_TYPES)[number];
export type ArtifactSensitivity = (typeof ARTIFACT_SENSITIVITIES)[number];

export type WorkTask = {
  id: string; task_number: string; business_unit_id: string; department_id: string;
  assigned_to: string; assigned_by: string; created_by: string; project_reference: string | null;
  title: string; instructions: string; expected_final_output: string | null; output_required: boolean;
  priority: WorkPriority; status: WorkStatus; progress_percent: number; current_blocker: string | null;
  next_action: string | null; task_sensitivity: ArtifactSensitivity; due_date: string | null;
  completed_at: string | null; output_waived: boolean; output_waiver_reason: string | null;
  output_waived_by: string | null; output_waived_at: string | null; final_approved_by: string | null;
  final_approved_at: string | null; row_version: number; created_at: string; updated_at: string;
  last_activity_at: string | null;
};

export type WorkTaskAttention = Pick<WorkTask, "id" | "task_number" | "title" | "assigned_to" | "business_unit_id" | "department_id" | "project_reference" | "priority" | "status" | "progress_percent" | "current_blocker" | "due_date" | "output_required" | "task_sensitivity" | "last_activity_at"> & {
  status_changed_at: string;
  meaningful_working_days: number;
  has_work_artifact: boolean;
  has_completion_artifact: boolean;
  artifact_indicator: "none" | "working" | "final_or_evidence";
  supervisor_wait_working_days: number;
  attention_rank: number | null;
  attention_flags: string[];
};
export type WorkTaskArtifact = { id: string; task_id: string; added_by: string; artifact_type: ArtifactType; artifact_sensitivity: ArtifactSensitivity; label: string | null; url: string; created_at: string };
export type WorkTaskComment = { id: string; task_id: string; author_id: string; comment_kind: "comment" | "supervisor_feedback"; audience: "participants" | "management_only"; body: string; created_at: string };
export type WorkTaskUpdate = { id: string; task_id: string; created_by: string; status: WorkStatus; progress_percent: number; blocker_or_help: string | null; is_meaningful: boolean; created_at: string };
export type WorkAssignee = { profile_id: string; full_name: string; role: string; department_id: string };

export type DailyWorkUpdate = {
  id: string; task_id: string; staff_id: string; work_date: string;
  what_done_today: string; quantity: string | null; result_or_output: string;
  deliverable_completed: boolean; artifact_id: string | null;
  blocker_or_help: string | null; created_at: string;
};

export type DailyUpdateReview = {
  id: string; daily_update_id: string; reviewer_id: string;
  review_status: "checked" | "correction_required" | "approved";
  supervisor_comment: string | null; created_at: string;
};

export const DASHBOARD_ATTENTION_FLAGS = [
  "OVERDUE",
  "STUCK",
  "COMPLETED MISSING EVIDENCE",
  "BLOCKED",
  "WAITING FEEDBACK",
  "NO UPDATE PREVIOUS WORKDAY",
  "SUPERVISOR BOTTLENECK",
] as const;

export type DashboardAttentionFlag = (typeof DASHBOARD_ATTENTION_FLAGS)[number];

export type DashboardWorkload = {
  assigned_to: string;
  active_tasks: number;
  overdue_tasks: number;
  stuck_tasks: number;
  waiting_feedback: number;
  completed_this_week: number;
  updates_this_week: number;
  workload_signal: "high_active_load" | "balanced_active_load" | "light_active_load";
};

export type DashboardDailyUpdate = Omit<DailyWorkUpdate, "artifact_id"> & {
  task_number: string;
  task_title: string;
  business_unit_id: string;
  department_id: string;
  project_reference: string | null;
  task_status: WorkStatus;
  has_visible_artifact: boolean;
  awaiting_supervisor_review: boolean;
};

export type DashboardMissingUpdate = {
  assigned_to: string;
  active_task_count: number;
};

export type DashboardFilters = {
  businessUnit?: string;
  department?: string;
  assignee?: string;
  project?: string;
  status?: string;
  attention?: string;
  dateFrom?: string;
  dateTo?: string;
};

export function filterWorkTasks<T extends Pick<WorkTask, "title" | "task_number" | "project_reference" | "status" | "department_id">>(tasks: T[], filters: { q?: string; status?: string; department?: string }): T[] {
  const query = filters.q?.trim().toLocaleLowerCase() ?? "";
  return tasks.filter((task) =>
    (!query || [task.title, task.task_number, task.project_reference ?? ""].some((value) => value.toLocaleLowerCase().includes(query)))
    && (!filters.status || task.status === filters.status)
    && (!filters.department || task.department_id === filters.department));
}
