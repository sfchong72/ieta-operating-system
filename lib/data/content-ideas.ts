import { createClient } from "@/lib/supabase/server";
import { withJwtClockSkewRetry } from "@/lib/supabase/retry";
import type { ContentIdea, IdeaStatus } from "./types";

export async function listIdeas(): Promise<ContentIdea[]> {
  return withJwtClockSkewRetry(async () => {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("content_ideas")
      .select("*")
      .order("created_at", { ascending: false });
    if (error) throw error;
    return data ?? [];
  });
}

export async function getIdea(id: string): Promise<ContentIdea | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_ideas")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export type IdeaInput = {
  title: string;
  platform: string | null;
  topic: string | null;
};

export async function createIdea(
  input: IdeaInput & {
    suggested_tags?: string | null;
    tags_source?: string | null;
    tags_confidence?: number | null;
  },
): Promise<ContentIdea> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_ideas")
    .insert({ ...input, status: "idea" })
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function updateIdea(
  id: string,
  input: Partial<IdeaInput> & { status?: IdeaStatus },
): Promise<ContentIdea> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_ideas")
    .update(input)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function deleteIdea(id: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase.from("content_ideas").delete().eq("id", id);
  if (error) throw error;
}

/** True when every content_task linked to this idea has status = 'posted'. */
export async function allTasksPosted(ideaId: string): Promise<boolean> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_tasks")
    .select("status")
    .eq("idea_id", ideaId);
  if (error) throw error;
  if (!data || data.length === 0) return false;
  return data.every((t) => t.status === "posted");
}
