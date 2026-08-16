"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createIdea, updateIdea, deleteIdea as deleteIdeaRow } from "@/lib/data/content-ideas";
import { suggestTags } from "@/lib/ai/rules";
import type { IdeaStatus } from "@/lib/data/types";

export type ActionState = { error?: string; success?: boolean };

export async function createIdeaAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const title = String(formData.get("title") ?? "").trim();
  const platform = String(formData.get("platform") ?? "").trim() || null;
  const topic = String(formData.get("topic") ?? "").trim() || null;

  if (!title) return { error: "Idea title is required." };

  // Agentic auto-action (low risk): rule-based tag suggestion, no external AI call.
  const { tags, confidence } = suggestTags(`${title} ${topic ?? ""}`);

  const idea = await createIdea({
    title,
    platform,
    topic,
    suggested_tags: tags.length ? tags.join(",") : null,
    tags_source: tags.length ? "rule" : null,
    tags_confidence: tags.length ? confidence : null,
  });

  revalidatePath("/ideas");
  revalidatePath("/dashboard");
  redirect(`/ideas/${idea.id}`);
}

export async function updateIdeaAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const platform = String(formData.get("platform") ?? "").trim() || null;
  const topic = String(formData.get("topic") ?? "").trim() || null;
  const status = String(formData.get("status") ?? "idea") as IdeaStatus;

  if (!id) return { error: "Missing idea." };
  if (!title) return { error: "Idea title is required." };

  await updateIdea(id, { title, platform, topic, status });
  revalidatePath("/ideas");
  revalidatePath(`/ideas/${id}`);
  redirect(`/ideas/${id}`);
}

export async function deleteIdeaAction(formData: FormData): Promise<void> {
  const id = String(formData.get("id") ?? "");
  if (!id) return;
  await deleteIdeaRow(id);
  revalidatePath("/ideas");
  revalidatePath("/dashboard");
  redirect("/ideas");
}
