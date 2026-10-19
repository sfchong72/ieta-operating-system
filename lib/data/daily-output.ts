import { createClient } from "@/lib/supabase/server";
import type { DailyUpdateReview, DailyWorkUpdate, WorkTask, WorkTaskArtifact } from "@/lib/work-management";

export async function listDailyWorkUpdates(): Promise<DailyWorkUpdate[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("daily_work_updates").select("*").order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []) as DailyWorkUpdate[];
}

export async function getDailyWorkUpdateDetail(id: string) {
  const supabase = await createClient();
  const { data: update, error } = await supabase.from("daily_work_updates").select("*").eq("id", id).maybeSingle();
  if (error) throw error;
  if (!update) return { update: null, task: null, artifact: null, reviews: [] as DailyUpdateReview[] };
  const typed = update as DailyWorkUpdate;
  const [taskResult, artifactResult, reviewsResult] = await Promise.all([
    supabase.from("work_tasks").select("*").eq("id", typed.task_id).maybeSingle(),
    typed.artifact_id
      ? supabase.from("work_task_artifacts").select("*").eq("id", typed.artifact_id).maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    supabase.from("daily_update_reviews").select("*").eq("daily_update_id", id).order("created_at", { ascending: false }),
  ]);
  for (const result of [taskResult, artifactResult, reviewsResult]) if (result.error) throw result.error;
  return {
    update: typed,
    task: taskResult.data as WorkTask | null,
    artifact: artifactResult.data as WorkTaskArtifact | null,
    reviews: (reviewsResult.data ?? []) as DailyUpdateReview[],
  };
}
