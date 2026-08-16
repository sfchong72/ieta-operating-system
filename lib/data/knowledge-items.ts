import { createClient } from "@/lib/supabase/server";
import type { KnowledgeItem } from "./types";

export async function listKnowledgeItems(): Promise<KnowledgeItem[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("knowledge_items")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function getKnowledgeItem(id: string): Promise<KnowledgeItem | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("knowledge_items")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export type KnowledgeItemInput = {
  title: string;
  category: string | null;
  body: string | null;
  tags: string[] | null;
};

export async function createKnowledgeItem(input: KnowledgeItemInput): Promise<KnowledgeItem> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("knowledge_items")
    .insert(input)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function updateKnowledgeItem(
  id: string,
  input: Partial<KnowledgeItemInput>,
): Promise<KnowledgeItem> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("knowledge_items")
    .update(input)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function deleteKnowledgeItem(id: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase.from("knowledge_items").delete().eq("id", id);
  if (error) throw error;
}
