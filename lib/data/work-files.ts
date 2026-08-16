import { createClient } from "@/lib/supabase/server";
import type { WorkFile, FileType } from "./types";

export async function listWorkFiles(taskId: string): Promise<WorkFile[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("work_files")
    .select("*")
    .eq("task_id", taskId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function createWorkFile(input: {
  task_id: string;
  label: string | null;
  url: string;
  file_type: FileType;
}): Promise<WorkFile> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("work_files")
    .insert(input)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}
