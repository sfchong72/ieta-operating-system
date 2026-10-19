import { createClient } from "@/lib/supabase/server";
import type {
  MasterFile,
  MasterFileAccessGrant,
  MasterFileArtifactLink,
  MasterFileAuditEvent,
  MasterFileCategory,
  MasterFileFilters,
  MasterFileSearchRow,
  MasterFileTaskLink,
} from "@/lib/master-files";

export async function listMasterFileCategories(): Promise<MasterFileCategory[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("master_file_categories")
    .select("slug,label,sort_order,is_active")
    .order("sort_order")
    .order("label");
  if (error) throw error;
  return (data ?? []) as MasterFileCategory[];
}

export async function searchMasterFiles(filters: MasterFileFilters = {}): Promise<MasterFileSearchRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("search_master_files", {
    p_search: filters.q || null,
    p_business_unit_id: filters.businessUnit || null,
    p_department_id: filters.department || null,
    p_category_slug: filters.category || null,
    p_owner_profile_id: filters.owner || null,
    p_project_reference: filters.project || null,
    p_status: filters.status || null,
    p_access_level: filters.access || null,
    p_include_history: filters.includeHistory ?? false,
    p_review_only: filters.reviewOnly ?? false,
    p_file_id: null,
    p_limit: 100,
  });
  if (error) throw error;
  return (data ?? []) as MasterFileSearchRow[];
}

export async function getMasterFile(id: string): Promise<MasterFile | null> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("master_files").select("*").eq("id", id).maybeSingle();
  if (error) throw error;
  return data as MasterFile | null;
}

export async function canManageMasterFile(id: string): Promise<boolean> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("fn_mf_can_manage_file", {
    subject_uid: (await supabase.auth.getUser()).data.user?.id ?? "00000000-0000-0000-0000-000000000000",
    target_file: id,
  });
  if (error) throw error;
  return data === true;
}

export async function getMasterFileDetail(id: string) {
  const supabase = await createClient();
  const file = await getMasterFile(id);
  if (!file) return null;

  const [summary, audit, taskLinks, artifactLinks, accessGrants, visibleFiles, replacements, duplicates] = await Promise.all([
    supabase.rpc("search_master_files", { p_file_id: id, p_include_history: true, p_limit: 1 }),
    supabase.rpc("get_master_file_audit", { p_master_file_id: id }),
    supabase
      .from("master_file_tasks")
      .select("task_id,work_tasks!inner(task_number,title)")
      .eq("master_file_id", id),
    supabase
      .from("master_file_artifacts")
      .select("task_artifact_id,work_task_artifacts!inner(label,artifact_type,artifact_sensitivity,url)")
      .eq("master_file_id", id),
    supabase
      .from("master_file_access_grants")
      .select("profile_id,grant_type,grant_reason,created_at")
      .eq("master_file_id", id)
      .order("created_at"),
    supabase.rpc("search_master_files", { p_include_history: true, p_limit: 100 }),
    supabase.from("master_files").select("id,file_number,file_name,status").eq("supersedes_file_id", id),
    supabase.from("master_files").select("id,file_number,file_name,status").eq("duplicate_of_file_id", id),
  ]);
  for (const result of [summary, audit, taskLinks, artifactLinks, accessGrants, visibleFiles, replacements, duplicates]) {
    if (result.error) throw result.error;
  }

  const tasks = (taskLinks.data ?? []).map((row) => {
    const task = row.work_tasks as unknown as { task_number: string; title: string };
    return { task_id: row.task_id, task_number: task.task_number, task_title: task.title };
  }) as MasterFileTaskLink[];
  const artifacts = (artifactLinks.data ?? []).map((row) => {
    const artifact = row.work_task_artifacts as unknown as {
      label: string | null;
      artifact_type: string;
      artifact_sensitivity: string;
      url: string;
    };
    return { task_artifact_id: row.task_artifact_id, ...artifact };
  }) as MasterFileArtifactLink[];

  return {
    file,
    summary: ((summary.data ?? [])[0] ?? null) as MasterFileSearchRow | null,
    audit: (audit.data ?? []) as MasterFileAuditEvent[],
    taskLinks: tasks,
    artifactLinks: artifacts,
    accessGrants: (accessGrants.data ?? []) as MasterFileAccessGrant[],
    visibleFiles: (visibleFiles.data ?? []) as MasterFileSearchRow[],
    replacements: (replacements.data ?? []) as Pick<MasterFile, "id" | "file_number" | "file_name" | "status">[],
    duplicates: (duplicates.data ?? []) as Pick<MasterFile, "id" | "file_number" | "file_name" | "status">[],
  };
}

export async function listMasterFileProjects(): Promise<string[]> {
  const rows = await searchMasterFiles({ includeHistory: true });
  return Array.from(new Set(rows.map((row) => row.project_reference).filter((value): value is string => Boolean(value)))).sort();
}
