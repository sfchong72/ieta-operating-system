"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/data/access";

export type ActionState = { error?: string; success?: boolean };

/** Anyone with access to the item can submit/resubmit their own work. */
export async function submitForReviewAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const content_item_id = String(formData.get("content_item_id") ?? "");
  if (!content_item_id) return { error: "Missing content item." };

  const currentUser = await getCurrentUser();
  if (!currentUser) return { error: "Not signed in." };

  const supabase = await createClient();

  const { error } = await supabase.rpc("submit_content_item_for_review", {
    target_id: content_item_id,
  });
  if (error) return { error: error.message };

  revalidatePath(`/planner/${content_item_id}`);
  revalidatePath("/planner");
  revalidatePath("/approvals");
  return { success: true };
}

/** Super Admin / Management only — enforced again here, not just by RLS. */
export async function approveContentItemAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const content_item_id = String(formData.get("content_item_id") ?? "");
  const comment = String(formData.get("comment") ?? "").trim() || null;
  if (!content_item_id) return { error: "Missing content item." };

  const currentUser = await getCurrentUser();
  if (!currentUser || !["super_admin", "management"].includes(currentUser.role ?? "")) {
    return { error: "Only Super Admin or Management can approve." };
  }

  const supabase = await createClient();

  const { error } = await supabase.rpc("review_content_item", {
    target_id: content_item_id,
    decision: "approved",
    review_comment: comment,
  });
  if (error) return { error: error.message };

  revalidatePath(`/planner/${content_item_id}`);
  revalidatePath("/planner");
  revalidatePath("/approvals");
  return { success: true };
}

export async function requestRevisionAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const content_item_id = String(formData.get("content_item_id") ?? "");
  const comment = String(formData.get("comment") ?? "").trim();
  if (!content_item_id) return { error: "Missing content item." };
  if (!comment) return { error: "A comment is required when requesting revision." };

  const currentUser = await getCurrentUser();
  if (!currentUser || !["super_admin", "management"].includes(currentUser.role ?? "")) {
    return { error: "Only Super Admin or Management can request revision." };
  }

  const supabase = await createClient();

  const { error } = await supabase.rpc("review_content_item", {
    target_id: content_item_id,
    decision: "revision_requested",
    review_comment: comment,
  });
  if (error) return { error: error.message };

  revalidatePath(`/planner/${content_item_id}`);
  revalidatePath("/planner");
  revalidatePath("/approvals");
  return { success: true };
}

/** Comment only — no status change. Super Admin / Management only. */
export async function addCommentAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const content_item_id = String(formData.get("content_item_id") ?? "");
  const comment = String(formData.get("comment") ?? "").trim();
  if (!content_item_id) return { error: "Missing content item." };
  if (!comment) return { error: "Comment cannot be empty." };

  const currentUser = await getCurrentUser();
  if (!currentUser || !["super_admin", "management"].includes(currentUser.role ?? "")) {
    return { error: "Only Super Admin or Management can comment here." };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("comment_on_content_item", {
    target_id: content_item_id,
    body: comment,
  });
  if (error) return { error: error.message };

  revalidatePath(`/planner/${content_item_id}`);
  revalidatePath("/approvals");
  return { success: true };
}
