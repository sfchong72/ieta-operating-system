import { createClient } from "@/lib/supabase/server";
import type { Activity, ActivityAction } from "./types";

export async function listActivitiesForTask(taskId: string): Promise<Activity[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("activities")
    .select("*")
    .eq("task_id", taskId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function listRecentActivities(limit = 20): Promise<Activity[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("activities")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data ?? [];
}

export async function logActivity(input: {
  task_id: string;
  action: ActivityAction;
  actor_name: string | null;
  detail: string | null;
}): Promise<Activity> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("activities")
    .insert(input)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}
