import { createClient } from "@/lib/supabase/server";
import type { ContentTask, TaskStatus, ApprovalStatus } from "./types";

export async function listTasks(): Promise<ContentTask[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_tasks")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function getTask(id: string): Promise<ContentTask | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_tasks")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export type TaskInput = {
  idea_id: string | null;
  title: string;
  department_id: string | null;
  pic_name: string;
  platform: string | null;
  deadline: string | null;
  remarks: string | null;
};

export async function createTask(
  input: TaskInput & {
    priority_score?: number | null;
    priority_source?: string | null;
    priority_confidence?: number | null;
  },
): Promise<ContentTask> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_tasks")
    .insert({ ...input, status: "assigned" satisfies TaskStatus })
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function updateTaskFields(
  id: string,
  input: Partial<TaskInput>,
): Promise<ContentTask> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_tasks")
    .update(input)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function updateTaskStatus(
  id: string,
  fields: {
    status?: TaskStatus;
    work_link?: string | null;
    approval_status?: ApprovalStatus;
    approval_remarks?: string | null;
    posted_url?: string | null;
    posted_date?: string | null;
    priority_score?: number | null;
    priority_source?: string | null;
    priority_confidence?: number | null;
  },
): Promise<ContentTask> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("content_tasks")
    .update(fields)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function deleteTask(id: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase.from("content_tasks").delete().eq("id", id);
  if (error) throw error;
}
