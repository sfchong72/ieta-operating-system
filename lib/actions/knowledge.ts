"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  createKnowledgeItem,
  updateKnowledgeItem,
  deleteKnowledgeItem as deleteKnowledgeItemRow,
} from "@/lib/data/knowledge-items";

export type ActionState = { error?: string; success?: boolean };

function parseTags(raw: string): string[] | null {
  const tags = raw
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean);
  return tags.length ? tags : null;
}

export async function createKnowledgeItemAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const title = String(formData.get("title") ?? "").trim();
  const category = String(formData.get("category") ?? "").trim() || null;
  const body = String(formData.get("body") ?? "").trim() || null;
  const tags = parseTags(String(formData.get("tags") ?? ""));

  if (!title) return { error: "Title is required." };

  const item = await createKnowledgeItem({ title, category, body, tags });
  revalidatePath("/knowledge");
  redirect(`/knowledge/${item.id}`);
}

export async function updateKnowledgeItemAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const category = String(formData.get("category") ?? "").trim() || null;
  const body = String(formData.get("body") ?? "").trim() || null;
  const tags = parseTags(String(formData.get("tags") ?? ""));

  if (!id) return { error: "Missing item." };
  if (!title) return { error: "Title is required." };

  await updateKnowledgeItem(id, { title, category, body, tags });
  revalidatePath("/knowledge");
  revalidatePath(`/knowledge/${id}`);
  redirect(`/knowledge/${id}`);
}

export async function deleteKnowledgeItemAction(formData: FormData): Promise<void> {
  const id = String(formData.get("id") ?? "");
  if (!id) return;
  await deleteKnowledgeItemRow(id);
  revalidatePath("/knowledge");
  redirect("/knowledge");
}
