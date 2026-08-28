import { createClient } from "@/lib/supabase/server";
import type { BusinessUnit } from "./types";

export async function listBusinessUnits(): Promise<BusinessUnit[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("business_units")
    .select("*")
    .order("name", { ascending: true });
  if (error) throw error;
  return data ?? [];
}
