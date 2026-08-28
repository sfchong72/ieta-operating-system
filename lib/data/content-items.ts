import { createClient } from "@/lib/supabase/server";
import type { ContentItem, PlatformPublication } from "./types";

export type ContentItemWithPublications = ContentItem & {
  platform_publications: PlatformPublication[];
};

export async function listContentItems(): Promise<ContentItemWithPublications[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_items")
    .select("*, platform_publications(*)")
    .order("due_date", { ascending: true, nullsFirst: false })
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []) as ContentItemWithPublications[];
}

export async function getContentItem(id: string): Promise<ContentItemWithPublications | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_items")
    .select("*, platform_publications(*)")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data as ContentItemWithPublications | null;
}
