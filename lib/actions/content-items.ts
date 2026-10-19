"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import {
  createContentItem,
  createPlatformPublications,
  getContentItemRow,
  updateContentItem,
  type ContentItemInput,
} from "@/lib/data/content-items";
import type { Platform } from "@/lib/data/types";

export type ActionState = { error?: string; success?: boolean };

const VALID_PLATFORMS: Platform[] = ["instagram", "facebook", "tiktok", "youtube_shorts", "other"];

function readInput(formData: FormData): { title: string; input: ContentItemInput } {
  const title = String(formData.get("title") ?? "").trim();
  const input: ContentItemInput = {
    title,
    business_unit_id: String(formData.get("business_unit_id") ?? "") || null,
    department_id: String(formData.get("department_id") ?? "") || null,
    campaign_id: String(formData.get("campaign_id") ?? "") || null,
    approval_category_id: String(formData.get("approval_category_id") ?? "") || null,
    content_type: String(formData.get("content_type") ?? "").trim() || null,
    language: String(formData.get("language") ?? "").trim() || null,
    target_audience: String(formData.get("target_audience") ?? "").trim() || null,
    priority: (String(formData.get("priority") ?? "") || null) as ContentItemInput["priority"],
    pic_name: String(formData.get("pic_name") ?? "").trim() || null,
    due_date: String(formData.get("due_date") ?? "").trim() || null,
    on_screen_wording: String(formData.get("on_screen_wording") ?? "").trim() || null,
    main_caption: String(formData.get("main_caption") ?? "").trim() || null,
    cta: String(formData.get("cta") ?? "").trim() || null,
    hashtags: String(formData.get("hashtags") ?? "").trim() || null,
    media_drive_link: String(formData.get("media_drive_link") ?? "").trim() || null,
    canva_link: String(formData.get("canva_link") ?? "").trim() || null,
    remarks: String(formData.get("remarks") ?? "").trim() || null,
  };
  return { title, input };
}

export async function createContentItemAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const currentUser = await getCurrentUser();
  if (!currentUser) return { error: "Not signed in." };

  const { title, input } = readInput(formData);
  if (!title) return { error: "Title is required." };

  const platforms = formData
    .getAll("platforms")
    .map(String)
    .filter((p): p is Platform => VALID_PLATFORMS.includes(p as Platform));

  const item = await createContentItem({ ...input, user_id: currentUser.profile.id });
  if (platforms.length > 0) {
    await createPlatformPublications(item.id, platforms);
  }

  revalidatePath("/planner");
  redirect(`/planner/${item.id}`);
}

/**
 * Full content-item edit. The staging database trigger writes the immutable
 * edit event in the same transaction. Platform selection is managed by the
 * separate publishing workflow.
 */
export async function updateContentItemAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const content_item_id = String(formData.get("content_item_id") ?? "");
  if (!content_item_id) return { error: "Missing content item." };

  const currentUser = await getCurrentUser();
  if (!currentUser) return { error: "Not signed in." };

  const { title, input } = readInput(formData);
  if (!title) return { error: "Title is required." };

  const before = await getContentItemRow(content_item_id);
  if (!before) return { error: "Content item not found." };

  await updateContentItem(content_item_id, input);

  revalidatePath(`/planner/${content_item_id}`);
  revalidatePath("/planner");
  return { success: true };
}
