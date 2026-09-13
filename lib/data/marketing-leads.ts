import { createClient } from "@/lib/supabase/server";
import type { LeadAuditEvent, LeadDuplicateWarning, LeadFilters, LeadInteraction, LeadSource, LeadSummary, LeadTaskLink, MarketingLead, MarketingLeadRow } from "@/lib/marketing-leads";

export async function listLeadSources(): Promise<LeadSource[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("marketing_lead_sources").select("slug,label,sort_order,is_active").order("sort_order");
  if (error) throw error;
  return (data ?? []) as LeadSource[];
}

export async function searchMarketingLeads(filters: LeadFilters = {}): Promise<MarketingLeadRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("search_marketing_leads", {
    p_search: filters.q || null, p_assigned_to: filters.assignedTo || null,
    p_business_unit_id: filters.businessUnit || null, p_branch: filters.branch || null,
    p_source_slug: filters.source || null, p_campaign_id: filters.campaign || null,
    p_status: filters.status || null, p_programme_interest: filters.programme || null,
    p_follow_up_from: filters.followUpFrom || null, p_follow_up_to: filters.followUpTo || null,
    p_received_from: filters.receivedFrom || null, p_received_to: filters.receivedTo || null,
    p_my_leads: filters.myLeads ?? false, p_due_only: filters.dueOnly ?? false,
    p_lead_id: null, p_limit: 100,
  });
  if (error) throw error;
  return (data ?? []) as MarketingLeadRow[];
}

export async function getMarketingLeadDetail(id: string) {
  const supabase = await createClient();
  const [leadRes, rowRes, interactionsRes, tasksRes, duplicateRes, auditRes, canManageRes] = await Promise.all([
    supabase.from("marketing_leads").select("*").eq("id", id).maybeSingle(),
    supabase.rpc("search_marketing_leads", { p_lead_id: id, p_limit: 1 }),
    supabase.from("lead_interactions").select("*,profiles!lead_interactions_performed_by_fkey(full_name,email)").eq("lead_id", id).order("interaction_at", { ascending: false }),
    supabase.from("marketing_lead_task_links").select("task_id,work_tasks!inner(task_number,title)").eq("lead_id", id),
    supabase.rpc("get_marketing_lead_duplicate_warnings", { p_lead_id: id }),
    supabase.rpc("get_marketing_lead_audit", { p_lead_id: id }),
    supabase.rpc("fn_ml_can_manage_lead", { subject_uid: (await supabase.auth.getUser()).data.user?.id ?? "00000000-0000-0000-0000-000000000000", target_lead: id }),
  ]);
  for (const result of [leadRes, rowRes, interactionsRes, tasksRes, duplicateRes, auditRes, canManageRes]) if (result.error) throw result.error;
  if (!leadRes.data) return null;
  const interactions = (interactionsRes.data ?? []).map((item) => {
    const profile = item.profiles as unknown as { full_name: string | null; email: string } | null;
    return { ...item, performer_name: profile?.full_name ?? profile?.email ?? "Authorised user" };
  }) as LeadInteraction[];
  const tasks = (tasksRes.data ?? []).map((item) => {
    const task = item.work_tasks as unknown as { task_number: string; title: string };
    return { task_id: item.task_id, task_number: task.task_number, task_title: task.title };
  }) as LeadTaskLink[];
  return {
    lead: leadRes.data as MarketingLead,
    row: ((rowRes.data ?? [])[0] ?? null) as MarketingLeadRow | null,
    interactions, tasks,
    duplicates: (duplicateRes.data ?? []) as LeadDuplicateWarning[],
    audit: (auditRes.data ?? []) as LeadAuditEvent[],
    canManage: canManageRes.data === true,
  };
}

export async function getMarketingLeadSummary(): Promise<LeadSummary> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("get_marketing_lead_summary", { p_business_unit_id: null });
  if (error) throw error;
  return (data ?? { authorised: false }) as LeadSummary;
}

export async function listLeadBranches() {
  const rows = await searchMarketingLeads();
  return Array.from(new Set(rows.map((row) => row.branch))).sort();
}

export async function listLeadProgrammes() {
  const rows = await searchMarketingLeads();
  return Array.from(new Set(rows.map((row) => row.programme_interest))).sort();
}
