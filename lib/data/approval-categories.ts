import { createClient } from "@/lib/supabase/server";
import type { ApprovalCategory } from "./types";

export async function listApprovalCategories(): Promise<ApprovalCategory[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("approval_categories")
    .select("*")
    .order("name");
  if (error) throw error;
  return data ?? [];
}
