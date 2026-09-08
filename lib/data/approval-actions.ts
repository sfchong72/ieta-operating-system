import { createClient } from "@/lib/supabase/server";
import type { ApprovalAction } from "./types";
import type { ContentItemWithPublications } from "./content-items";

export type ApprovalActionWithActor = ApprovalAction & {
  actor: { full_name: string | null; email: string } | null;
};

/** Full immutable history for one content item, oldest to newest. */
export async function listApprovalActionsForItem(
  contentItemId: string,
): Promise<ApprovalActionWithActor[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("approval_action")
    .select("*, actor:profiles(full_name, email)")
    .eq("content_item_id", contentItemId)
    .order("created_at", { ascending: true });
  if (error) throw error;
  return (data ?? []) as unknown as ApprovalActionWithActor[];
}

/**
 * My Approvals queue: content items currently awaiting_approval, routed by
 * whether an escalation category is set. NULL category -> routine ->
 * Management's queue. Any category set (one of the 8) -> Super Admin's
 * queue. RLS already scopes visible rows to department/business-unit
 * access; this just adds the routing filter on top.
 */
export async function listApprovalQueue(
  role: "super_admin" | "management",
): Promise<ContentItemWithPublications[]> {
  const supabase = await createClient();
  let query = supabase
    .from("content_items")
    .select("*, platform_publications(*)")
    .eq("status", "awaiting_approval");

  query = role === "super_admin" ? query.not("approval_category_id", "is", null) : query.is("approval_category_id", null);

  const { data, error } = await query.order("due_date", { ascending: true, nullsFirst: false });
  if (error) throw error;
  return (data ?? []) as unknown as ContentItemWithPublications[];
}
