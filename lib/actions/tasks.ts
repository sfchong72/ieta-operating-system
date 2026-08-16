"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  createTask,
  deleteTask as deleteTaskRow,
  getTask,
  updateTaskStatus,
  updateTaskFields,
} from "@/lib/data/content-tasks";
import { createWorkFile } from "@/lib/data/work-files";
import { logActivity } from "@/lib/data/activities";
import { allTasksPosted, updateIdea } from "@/lib/data/content-ideas";
import { listDepartments } from "@/lib/data/departments";
import { detectFileType, computePriorityScore } from "@/lib/ai/rules";

export type ActionState = { error?: string; success?: boolean };

function isValidUrl(value: string): boolean {
  try {
    const u = new URL(value);
    return u.protocol === "http:" || u.protocol === "https:";
  } catch {
    return false;
  }
}

/**
 * Agentic auto-action (low risk): recompute compute_priority_score after any
 * transition that could change urgency (deadline proximity, status, work link
 * presence). Rule-based only, per docs/AGENTIC_LAYER.md.
 */
async function recomputePriority(taskId: string): Promise<void> {
  const [task, departments] = await Promise.all([getTask(taskId), listDepartments()]);
  if (!task) return;
  const marketingId = departments.find((d) => d.slug === "marketing")?.id ?? null;
  const { score, reason } = computePriorityScore(task, marketingId);
  await updateTaskStatus(taskId, {
    priority_score: score,
    priority_source: "rule",
    priority_confidence: reason ? 0.9 : 0.5,
  });
}

export async function createTaskAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const title = String(formData.get("title") ?? "").trim();
  const pic_name = String(formData.get("pic_name") ?? "").trim();
  const department_id = String(formData.get("department_id") ?? "") || null;
  const idea_id = String(formData.get("idea_id") ?? "") || null;
  const platform = String(formData.get("platform") ?? "").trim() || null;
  const deadline = String(formData.get("deadline") ?? "").trim() || null;
  const remarks = String(formData.get("remarks") ?? "").trim() || null;

  if (!title) return { error: "Task title is required." };
  if (!pic_name) return { error: "PIC name is required." };

  const task = await createTask({
    title,
    pic_name,
    department_id,
    idea_id,
    platform,
    deadline,
    remarks,
  });

  await logActivity({
    task_id: task.id,
    action: "created",
    actor_name: pic_name,
    detail: idea_id ? `Task created from idea` : `Task created`,
  });

  if (idea_id) {
    await updateIdea(idea_id, { status: "tasked" });
  }

  await recomputePriority(task.id);

  revalidatePath("/tasks");
  revalidatePath("/dashboard");
  redirect(`/tasks/${task.id}`);
}

export async function attachWorkLinkAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const task_id = String(formData.get("task_id") ?? "");
  const url = String(formData.get("url") ?? "").trim();
  const label = String(formData.get("label") ?? "").trim() || null;
  const actor_name = String(formData.get("actor_name") ?? "").trim() || "Unknown";

  if (!task_id) return { error: "Missing task." };
  if (!url || !isValidUrl(url)) {
    return { error: "Please enter a valid URL." };
  }

  const file_type = detectFileType(url);
  await createWorkFile({ task_id, label, url, file_type });

  await updateTaskStatus(task_id, { status: "in_progress", work_link: url });

  await logActivity({
    task_id,
    action: "link_attached",
    actor_name,
    detail: `${file_type} link attached: ${url}`,
  });

  await recomputePriority(task_id);

  revalidatePath(`/tasks/${task_id}`);
  revalidatePath("/tasks");
  revalidatePath("/dashboard");
  return { success: true };
}

export async function submitForReviewAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const task_id = String(formData.get("task_id") ?? "");
  const actor_name = String(formData.get("actor_name") ?? "").trim() || "Unknown";
  if (!task_id) return { error: "Missing task." };

  await updateTaskStatus(task_id, { status: "submitted", approval_status: "pending" });
  await logActivity({
    task_id,
    action: "status_changed",
    actor_name,
    detail: "Submitted for review",
  });

  await recomputePriority(task_id);

  revalidatePath(`/tasks/${task_id}`);
  revalidatePath("/tasks");
  revalidatePath("/dashboard");
  return { success: true };
}

export async function approveTaskAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const task_id = String(formData.get("task_id") ?? "");
  const actor_name = String(formData.get("actor_name") ?? "").trim();
  const remark = String(formData.get("remark") ?? "").trim() || null;
  if (!task_id) return { error: "Missing task." };
  if (!actor_name) return { error: "Manager name is required to approve." };

  await updateTaskStatus(task_id, {
    status: "approved",
    approval_status: "approved",
    approval_remarks: remark,
  });
  await logActivity({
    task_id,
    action: "approved",
    actor_name,
    detail: remark ?? "Approved",
  });

  await recomputePriority(task_id);

  revalidatePath(`/tasks/${task_id}`);
  revalidatePath("/tasks");
  revalidatePath("/dashboard");
  return { success: true };
}

export async function amendTaskAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const task_id = String(formData.get("task_id") ?? "");
  const actor_name = String(formData.get("actor_name") ?? "").trim();
  const remark = String(formData.get("remark") ?? "").trim();
  if (!task_id) return { error: "Missing task." };
  if (!actor_name) return { error: "Manager name is required." };
  if (!remark) return { error: "A remark is required when requesting amendments." };

  await updateTaskStatus(task_id, {
    status: "amendment",
    approval_status: "amend",
    approval_remarks: remark,
  });
  await logActivity({
    task_id,
    action: "status_changed",
    actor_name,
    detail: `Sent back for amendment: ${remark}`,
  });

  await recomputePriority(task_id);

  revalidatePath(`/tasks/${task_id}`);
  revalidatePath("/tasks");
  revalidatePath("/dashboard");
  return { success: true };
}

export async function markPostedAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const task_id = String(formData.get("task_id") ?? "");
  const actor_name = String(formData.get("actor_name") ?? "").trim() || "Unknown";
  const posted_url = String(formData.get("posted_url") ?? "").trim();
  const posted_date = String(formData.get("posted_date") ?? "").trim();

  if (!task_id) return { error: "Missing task." };
  if (!posted_url || !isValidUrl(posted_url)) {
    return { error: "Please enter a valid URL." };
  }
  if (!posted_date) return { error: "Posted date is required." };

  const task = await updateTaskStatus(task_id, {
    status: "posted",
    posted_url,
    posted_date,
  });
  await logActivity({
    task_id,
    action: "posted",
    actor_name,
    detail: `Posted: ${posted_url}`,
  });

  // Agentic auto-action (medium risk, post-approval): archive idea once every linked task is posted.
  if (task.idea_id) {
    const done = await allTasksPosted(task.idea_id);
    if (done) {
      await updateIdea(task.idea_id, { status: "archived" });
    }
  }

  await recomputePriority(task_id);

  revalidatePath(`/tasks/${task_id}`);
  revalidatePath("/tasks");
  revalidatePath("/dashboard");
  revalidatePath("/ideas");
  return { success: true };
}

export async function updateTaskRemarksAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const task_id = String(formData.get("task_id") ?? "");
  const remarks = String(formData.get("remarks") ?? "").trim() || null;
  if (!task_id) return { error: "Missing task." };

  await updateTaskFields(task_id, { remarks });
  revalidatePath(`/tasks/${task_id}`);
  return { success: true };
}

export async function deleteTaskAction(formData: FormData): Promise<void> {
  const task_id = String(formData.get("task_id") ?? "");
  if (!task_id) return;
  await deleteTaskRow(task_id);
  revalidatePath("/tasks");
  revalidatePath("/dashboard");
  redirect("/tasks");
}
