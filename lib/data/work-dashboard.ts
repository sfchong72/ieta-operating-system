import { createClient } from "@/lib/supabase/server";
import type {
  DashboardDailyUpdate,
  DashboardFilters,
  DashboardMissingUpdate,
  DashboardWorkload,
  WorkTaskAttention,
} from "@/lib/work-management";

function rpcFilters(filters: DashboardFilters) {
  return {
    p_business_unit_id: filters.businessUnit || null,
    p_department_id: filters.department || null,
    p_assigned_to: filters.assignee || null,
    p_project_reference: filters.project || null,
    p_status: filters.status || null,
    p_attention_flag: filters.attention || null,
    p_date_from: filters.dateFrom || null,
    p_date_to: filters.dateTo || null,
  };
}

export async function listDashboardAttention(filters: DashboardFilters): Promise<WorkTaskAttention[]> {
  const supabase = await createClient();
  let query = supabase
    .from("work_dashboard_attention")
    .select("*")
    .not("attention_rank", "is", null)
    .order("attention_rank", { ascending: true })
    .order("due_date", { ascending: true, nullsFirst: false });
  if (filters.businessUnit) query = query.eq("business_unit_id", filters.businessUnit);
  if (filters.department) query = query.eq("department_id", filters.department);
  if (filters.assignee) query = query.eq("assigned_to", filters.assignee);
  if (filters.project) query = query.eq("project_reference", filters.project);
  if (filters.status) query = query.eq("status", filters.status);
  if (filters.attention) query = query.contains("attention_flags", [filters.attention]);
  if (filters.dateFrom) query = query.gte("due_date", filters.dateFrom);
  if (filters.dateTo) query = query.lte("due_date", filters.dateTo);
  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []) as WorkTaskAttention[];
}

export async function listDashboardWorkload(filters: DashboardFilters): Promise<DashboardWorkload[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("get_work_dashboard_team_workload", rpcFilters(filters));
  if (error) throw error;
  return ((data ?? []) as DashboardWorkload[]).map((row) => ({
    ...row,
    active_tasks: Number(row.active_tasks),
    overdue_tasks: Number(row.overdue_tasks),
    stuck_tasks: Number(row.stuck_tasks),
    waiting_feedback: Number(row.waiting_feedback),
    completed_this_week: Number(row.completed_this_week),
    updates_this_week: Number(row.updates_this_week),
  })) as DashboardWorkload[];
}

export async function listDashboardDailyUpdates(filters: DashboardFilters): Promise<DashboardDailyUpdate[]> {
  const supabase = await createClient();
  let query = supabase
    .from("work_dashboard_daily_updates")
    .select("*")
    .order("created_at", { ascending: false });
  if (filters.businessUnit) query = query.eq("business_unit_id", filters.businessUnit);
  if (filters.department) query = query.eq("department_id", filters.department);
  if (filters.assignee) query = query.eq("staff_id", filters.assignee);
  if (filters.project) query = query.eq("project_reference", filters.project);
  if (filters.status) query = query.eq("task_status", filters.status);
  if (filters.dateFrom) query = query.gte("work_date", filters.dateFrom);
  if (filters.dateTo) query = query.lte("work_date", filters.dateTo);
  if (!filters.dateFrom && !filters.dateTo) query = query.eq("work_date", new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Kuala_Lumpur" }));
  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []) as DashboardDailyUpdate[];
}

export async function listDashboardMissingUpdates(filters: DashboardFilters): Promise<DashboardMissingUpdate[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("get_work_dashboard_missing_updates_today", {
    p_business_unit_id: filters.businessUnit || null,
    p_department_id: filters.department || null,
    p_assigned_to: filters.assignee || null,
    p_project_reference: filters.project || null,
  });
  if (error) throw error;
  return ((data ?? []) as DashboardMissingUpdate[]).map((row) => ({ ...row, active_task_count: Number(row.active_task_count) }));
}

export async function listDashboardProjects(): Promise<string[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("list_work_dashboard_projects");
  if (error) throw error;
  return ((data ?? []) as Array<{ project_reference: string | null }>).map((row) => row.project_reference).filter((value): value is string => Boolean(value));
}
