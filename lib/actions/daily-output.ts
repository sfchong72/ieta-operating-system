"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type DailyOutputActionState = {
  error?: string;
  success?: string;
  formVersion?: string;
  values?: Record<string, string | boolean>;
};

function value(formData: FormData, name: string) { return String(formData.get(name) ?? "").trim(); }
function optional(formData: FormData, name: string) { return value(formData, name) || null; }
function checked(formData: FormData, name: string) { return formData.get(name) === "on" || formData.get(name) === "true"; }
function safeMessage(error: unknown) {
  const message = error instanceof Error ? error.message : "The request could not be completed.";
  return message.replace(/https?:\/\/\S+/g, "[link hidden]").slice(0, 300);
}
function submissionValues(formData: FormData) {
  return {
    task_id: value(formData, "task_id"),
    what_done_today: value(formData, "what_done_today"),
    quantity: value(formData, "quantity"),
    result_or_output: value(formData, "result_or_output"),
    deliverable_completed: checked(formData, "deliverable_completed"),
    evidence_url: value(formData, "evidence_url"),
    blocker_or_help: value(formData, "blocker_or_help"),
    data_handling_confirmed: checked(formData, "data_handling_confirmed"),
  };
}
function reviewValues(formData: FormData) {
  return {
    review_status: value(formData, "review_status"),
    supervisor_comment: value(formData, "supervisor_comment"),
    data_handling_confirmed: checked(formData, "data_handling_confirmed"),
  };
}
function invalid(error: string, values: Record<string, string | boolean>): DailyOutputActionState {
  return { error, values, formVersion: crypto.randomUUID() };
}
function refresh(taskId?: string, updateId?: string) {
  revalidatePath("/daily-updates");
  if (taskId) revalidatePath(`/work/${taskId}`);
  if (updateId) revalidatePath(`/daily-updates/${updateId}`);
}

export async function submitDailyWorkUpdateAction(
  _previous: DailyOutputActionState,
  formData: FormData,
): Promise<DailyOutputActionState> {
  const taskId = value(formData, "task_id");
  const deliverableCompleted = checked(formData, "deliverable_completed");
  const values = submissionValues(formData);
  if (!taskId) return invalid("Choose a linked task.", values);
  if (!value(formData, "what_done_today") || !value(formData, "result_or_output")) {
    return invalid("What was done and result/output are required.", values);
  }
  if (deliverableCompleted && !value(formData, "evidence_url")) {
    return invalid("Add an evidence link for a completed deliverable.", values);
  }
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("submit_daily_work_update", {
      p_task_id: taskId,
      p_what_done_today: value(formData, "what_done_today"),
      p_quantity: optional(formData, "quantity"),
      p_result_or_output: value(formData, "result_or_output"),
      p_deliverable_completed: deliverableCompleted,
      p_evidence_url: optional(formData, "evidence_url"),
      p_blocker_or_help: optional(formData, "blocker_or_help"),
      p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
    });
    if (error) throw error;
    const updateId = String(data);
    refresh(taskId, updateId);
    redirect(`/daily-updates/${updateId}`);
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) throw error;
    return invalid(safeMessage(error), values);
  }
}

export async function reviewDailyWorkUpdateAction(
  _previous: DailyOutputActionState,
  formData: FormData,
): Promise<DailyOutputActionState> {
  const updateId = value(formData, "daily_update_id");
  const status = value(formData, "review_status");
  const values = reviewValues(formData);
  if (!["checked", "correction_required", "approved"].includes(status)) return invalid("Choose a valid review status.", values);
  if (status === "correction_required" && !value(formData, "supervisor_comment")) return invalid("Add a comment explaining the required correction.", values);
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("review_daily_work_update", {
      p_daily_update_id: updateId,
      p_review_status: status,
      p_supervisor_comment: optional(formData, "supervisor_comment"),
      p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
    });
    if (error) throw error;
    refresh(undefined, updateId);
    return { success: "Supervisor review added." };
  } catch (error) {
    return invalid(safeMessage(error), values);
  }
}
