"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  ARTIFACT_SENSITIVITIES,
  ARTIFACT_TYPES,
  WORK_PRIORITIES,
  WORK_STATUSES,
  type ArtifactSensitivity,
  type ArtifactType,
  type WorkPriority,
  type WorkStatus,
} from "@/lib/work-management";

export type WorkActionState = { error?: string; success?: string };

function value(formData: FormData, name: string) {
  return String(formData.get(name) ?? "").trim();
}

function optional(formData: FormData, name: string) {
  return value(formData, name) || null;
}

function checked(formData: FormData, name: string) {
  return formData.get(name) === "on" || formData.get(name) === "true";
}

function safeMessage(error: unknown) {
  const message = error instanceof Error ? error.message : "The request could not be completed.";
  return message.replace(/https?:\/\/\S+/g, "[link hidden]").slice(0, 300);
}

function refresh(taskId?: string) {
  revalidatePath("/work");
  revalidatePath("/work/team");
  revalidatePath("/work/attention");
  if (taskId) revalidatePath(`/work/${taskId}`);
}

export async function createWorkTaskAction(
  _previous: WorkActionState,
  formData: FormData,
): Promise<WorkActionState> {
  const priority = value(formData, "priority") as WorkPriority;
  const status = value(formData, "status") as WorkStatus;
  const sensitivity = value(formData, "task_sensitivity") as ArtifactSensitivity;
  if (!WORK_PRIORITIES.includes(priority) || !["backlog", "not_started"].includes(status)) {
    return { error: "Choose a valid priority and starting status." };
  }
  if (!ARTIFACT_SENSITIVITIES.includes(sensitivity)) return { error: "Choose a valid sensitivity." };
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("create_work_task", {
      p_business_unit_id: value(formData, "business_unit_id"),
      p_department_id: value(formData, "department_id"),
      p_assigned_to: value(formData, "assigned_to"),
      p_project_reference: optional(formData, "project_reference"),
      p_title: value(formData, "title"),
      p_instructions: value(formData, "instructions"),
      p_expected_final_output: optional(formData, "expected_final_output"),
      p_output_required: checked(formData, "output_required"),
      p_due_date: optional(formData, "due_date"),
      p_priority: priority,
      p_initial_status: status,
      p_task_sensitivity: sensitivity,
      p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
    });
    if (error) throw error;
    refresh(String(data));
    redirect(`/work/${data}`);
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) throw error;
    return { error: safeMessage(error) };
  }
}

export async function updateWorkTaskAction(
  _previous: WorkActionState,
  formData: FormData,
): Promise<WorkActionState> {
  const taskId = value(formData, "task_id");
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("update_work_task_management", {
      p_task_id: taskId,
      p_business_unit_id: value(formData, "business_unit_id"),
      p_department_id: value(formData, "department_id"),
      p_assigned_to: value(formData, "assigned_to"),
      p_project_reference: optional(formData, "project_reference"),
      p_title: value(formData, "title"),
      p_instructions: value(formData, "instructions"),
      p_expected_final_output: optional(formData, "expected_final_output"),
      p_output_required: checked(formData, "output_required"),
      p_due_date: optional(formData, "due_date"),
      p_priority: value(formData, "priority"),
      p_task_sensitivity: value(formData, "task_sensitivity"),
      p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
    });
    if (error) throw error;
    refresh(taskId);
    redirect(`/work/${taskId}`);
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) throw error;
    return { error: safeMessage(error) };
  }
}

export async function quickUpdateWorkTaskAction(
  _previous: WorkActionState,
  formData: FormData,
): Promise<WorkActionState> {
  const taskId = value(formData, "task_id");
  const status = value(formData, "status") as WorkStatus;
  if (!WORK_STATUSES.includes(status)) return { error: "Choose a valid status." };
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("quick_update_work_task", {
      p_task_id: taskId,
      p_status: status,
      p_progress_percent: Number(value(formData, "progress_percent")),
      p_blocker_or_help: optional(formData, "blocker_or_help"),
      p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
    });
    if (error) throw error;
    refresh(taskId);
    return { success: "Task updated." };
  } catch (error) {
    return { error: safeMessage(error) };
  }
}

export async function addWorkArtifactAction(
  _previous: WorkActionState,
  formData: FormData,
): Promise<WorkActionState> {
  const taskId = value(formData, "task_id");
  const artifactType = value(formData, "artifact_type") as ArtifactType;
  if (!ARTIFACT_TYPES.includes(artifactType)) return { error: "Choose a valid link type." };
  try {
    const supabase = await createClient();
    const managed = value(formData, "managed") === "true";
    const { error } = managed
      ? await supabase.rpc("add_managed_work_task_artifact", {
          p_task_id: taskId,
          p_artifact_type: artifactType,
          p_artifact_sensitivity: value(formData, "artifact_sensitivity"),
          p_label: optional(formData, "label"),
          p_url: value(formData, "url"),
        })
      : await supabase.rpc("add_work_task_artifact", {
          p_task_id: taskId,
          p_artifact_type: artifactType,
          p_label: optional(formData, "label"),
          p_url: value(formData, "url"),
        });
    if (error) throw error;
    refresh(taskId);
    return { success: "Link added." };
  } catch (error) {
    return { error: safeMessage(error) };
  }
}

export async function addWorkCommentAction(
  _previous: WorkActionState,
  formData: FormData,
): Promise<WorkActionState> {
  const taskId = value(formData, "task_id");
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("add_work_task_comment", {
      p_task_id: taskId,
      p_body: value(formData, "body"),
      p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
    });
    if (error) throw error;
    refresh(taskId);
    return { success: "Comment added." };
  } catch (error) {
    return { error: safeMessage(error) };
  }
}

export async function superviseWorkTaskAction(
  _previous: WorkActionState,
  formData: FormData,
): Promise<WorkActionState> {
  const taskId = value(formData, "task_id");
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("supervise_work_task", {
      p_task_id: taskId,
      p_feedback: optional(formData, "feedback"),
      p_next_action: optional(formData, "next_action"),
      p_approve_final: checked(formData, "approve_final"),
      p_waive_output: checked(formData, "waive_output"),
      p_waiver_reason: optional(formData, "waiver_reason"),
      p_complete_task: checked(formData, "complete_task"),
      p_feedback_management_only: checked(formData, "feedback_management_only"),
      p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
    });
    if (error) throw error;
    refresh(taskId);
    return { success: "Supervisor review saved." };
  } catch (error) {
    return { error: safeMessage(error) };
  }
}
