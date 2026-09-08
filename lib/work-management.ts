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
};

export type WorkTaskAttention = Pick<WorkTask, "id" | "task_number" | "title" | "assigned_to" | "business_unit_id" | "department_id" | "priority" | "status" | "progress_percent" | "current_blocker" | "due_date" | "output_required" | "task_sensitivity"> & { meaningful_working_days: number; attention_flags: string[] };
export type WorkTaskArtifact = { id: string; task_id: string; added_by: string; artifact_type: ArtifactType; artifact_sensitivity: ArtifactSensitivity; label: string | null; url: string; created_at: string };
export type WorkTaskComment = { id: string; task_id: string; author_id: string; comment_kind: "comment" | "supervisor_feedback"; audience: "participants" | "management_only"; body: string; created_at: string };
export type WorkTaskUpdate = { id: string; task_id: string; created_by: string; status: WorkStatus; progress_percent: number; blocker_or_help: string | null; is_meaningful: boolean; created_at: string };
export type WorkAssignee = { profile_id: string; full_name: string; role: string; department_id: string };

export function filterWorkTasks<T extends Pick<WorkTask, "title" | "task_number" | "project_reference" | "status" | "department_id">>(tasks: T[], filters: { q?: string; status?: string; department?: string }): T[] {
  const query = filters.q?.trim().toLocaleLowerCase() ?? "";
  return tasks.filter((task) =>
    (!query || [task.title, task.task_number, task.project_reference ?? ""].some((value) => value.toLocaleLowerCase().includes(query)))
    && (!filters.status || task.status === filters.status)
    && (!filters.department || task.department_id === filters.department));
}
