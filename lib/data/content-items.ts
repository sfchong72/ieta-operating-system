import { createClient } from "@/lib/supabase/server";
import type { ContentItem, Platform, PlatformPublication } from "./types";

export type ContentItemWithPublications = ContentItem & {
  platform_publications: PlatformPublication[];
};

export type ContentItemInput = {
  title: string;
  business_unit_id: string | null;
  department_id: string | null;
  campaign_id: string | null;
  approval_category_id: string | null;
  content_type: string | null;
  language: string | null;
  target_audience: string | null;
  priority: ContentItem["priority"];
  pic_name: string | null;
  due_date: string | null;
  on_screen_wording: string | null;
  main_caption: string | null;
  cta: string | null;
  hashtags: string | null;
  media_drive_link: string | null;
  canva_link: string | null;
  remarks: string | null;
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

/** Raw row without the joined publications — used to diff before/after on edit. */
export async function getContentItemRow(id: string): Promise<ContentItem | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_items")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function createContentItem(
  input: ContentItemInput & { user_id: string },
): Promise<ContentItem> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_items")
    .insert({ ...input, status: "draft" })
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function updateContentItem(
  id: string,
  input: ContentItemInput,
): Promise<ContentItem> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_items")
    .update(input)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

/** Seeds one platform_publications row per selected platform at creation time. */
export async function createPlatformPublications(
  contentItemId: string,
  platforms: Platform[],
): Promise<void> {
  if (platforms.length === 0) return;
  const supabase = await createClient();
  const { error } = await supabase.from("platform_publications").insert(
    platforms.map((platform) => ({
      content_item_id: contentItemId,
      platform,
      status: "scheduled" as const,
    })),
  );
  if (error) throw error;
}
