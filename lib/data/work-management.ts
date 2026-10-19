import { createClient } from "@/lib/supabase/server";
import type {
  WorkAssignee,
  WorkTask,
  WorkTaskArtifact,
  WorkTaskAttention,
  WorkTaskComment,
  WorkTaskUpdate,
} from "@/lib/work-management";

export async function listWorkTasks(assignedTo?: string): Promise<WorkTask[]> {
  const supabase = await createClient();
  let query = supabase.from("work_tasks").select("*").order("updated_at", { ascending: false });
  if (assignedTo) query = query.eq("assigned_to", assignedTo);
  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []) as WorkTask[];
}

export async function getWorkTask(id: string): Promise<WorkTask | null> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("work_tasks").select("*").eq("id", id).maybeSingle();
  if (error) throw error;
  return data as WorkTask | null;
}

export async function getWorkTaskAttention(id: string): Promise<WorkTaskAttention | null> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("work_task_attention").select("*").eq("id", id).maybeSingle();
  if (error) throw error;
  return data as WorkTaskAttention | null;
}

export async function listAttentionTasks(): Promise<WorkTaskAttention[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("work_task_attention").select("*").order("due_date", { ascending: true, nullsFirst: false });
  if (error) throw error;
  return ((data ?? []) as WorkTaskAttention[]).filter((task) => task.attention_flags.length > 0);
}

export async function getWorkTaskDetail(id: string) {
  const supabase = await createClient();
  const [task, attention, artifacts, comments, updates] = await Promise.all([
    getWorkTask(id),
    getWorkTaskAttention(id),
    supabase.from("work_task_artifacts").select("*").eq("task_id", id).order("created_at", { ascending: false }),
    supabase.from("work_task_comments").select("*").eq("task_id", id).order("created_at", { ascending: false }),
    supabase.from("work_task_updates").select("*").eq("task_id", id).order("created_at", { ascending: false }),
  ]);
  for (const result of [artifacts, comments, updates]) if (result.error) throw result.error;
  return {
    task,
    attention,
    artifacts: (artifacts.data ?? []) as WorkTaskArtifact[],
    comments: (comments.data ?? []) as WorkTaskComment[],
    updates: (updates.data ?? []) as WorkTaskUpdate[],
  };
}

export async function listWorkAssignees(): Promise<WorkAssignee[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("list_work_task_assignees");
  if (error) throw error;
  return (data ?? []) as WorkAssignee[];
}
