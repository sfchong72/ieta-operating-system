import { createClient } from "@/lib/supabase/server";
import type { Campaign } from "./types";

export async function listCampaigns(): Promise<Campaign[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("campaigns")
    .select("*")
    .order("name", { ascending: true });
  if (error) throw error;
  return data ?? [];
}
