"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { fromBusinessLocalInput } from "@/lib/business-time";

export type LeadActionState = { error?: string; success?: string };
function value(formData: FormData, name: string) { return String(formData.get(name) ?? "").trim(); }
function optional(formData: FormData, name: string) { return value(formData, name) || null; }
function checked(formData: FormData, name: string) { return formData.get(name) === "on"; }
function numeric(formData: FormData, name: string) { const raw = value(formData, name); return raw ? Number(raw) : null; }
function safeMessage(error: unknown) { return (error instanceof Error ? error.message : "The request could not be completed.").replace(/https?:\/\/\S+/g, "[link hidden]").slice(0, 300); }
function refresh(id?: string) { revalidatePath("/leads"); revalidatePath("/leads/my"); revalidatePath("/leads/follow-up"); revalidatePath("/leads/summary"); if (id) revalidatePath(`/leads/${id}`); }

function shared(formData: FormData) {
  return {
    p_business_unit_id: value(formData, "business_unit_id"), p_department_id: value(formData, "department_id"),
    p_branch: value(formData, "branch"), p_source_slug: value(formData, "source_slug"),
    p_campaign_id: optional(formData, "campaign_id"), p_project_reference: optional(formData, "project_reference"),
    p_name: value(formData, "name"), p_contact_number: value(formData, "contact_number"), p_email: optional(formData, "email"),
    p_country: optional(formData, "country"), p_nationality: optional(formData, "nationality"),
    p_programme_interest: value(formData, "programme_interest"), p_assigned_to_profile_id: value(formData, "assigned_to_profile_id"),
    p_status: value(formData, "status"), p_next_follow_up_at: fromBusinessLocalInput(optional(formData, "next_follow_up_at")),
    p_consultation_date: fromBusinessLocalInput(optional(formData, "consultation_date")), p_estimated_or_actual_value: numeric(formData, "estimated_or_actual_value"),
    p_source_reference_url: optional(formData, "source_reference_url"), p_remarks: optional(formData, "remarks"),
    p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
  };
}

export async function createMarketingLeadAction(_previous: LeadActionState, formData: FormData): Promise<LeadActionState> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("create_marketing_lead", { ...shared(formData), p_date_received: fromBusinessLocalInput(optional(formData, "date_received")) });
    if (error) throw error; refresh(String(data)); redirect(`/leads/${data}`);
  } catch (error) { if (error && typeof error === "object" && "digest" in error) throw error; return { error: safeMessage(error) }; }
}

export async function updateMarketingLeadAction(_previous: LeadActionState, formData: FormData): Promise<LeadActionState> {
  const id = value(formData, "lead_id");
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("update_marketing_lead", { ...shared(formData), p_lead_id: id, p_final_outcome: optional(formData, "final_outcome") });
    if (error) throw error; refresh(id); redirect(`/leads/${id}`);
  } catch (error) { if (error && typeof error === "object" && "digest" in error) throw error; return { error: safeMessage(error) }; }
}

export async function addLeadInteractionAction(_previous: LeadActionState, formData: FormData): Promise<LeadActionState> {
  const id = value(formData, "lead_id");
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("add_lead_interaction", {
      p_lead_id: id, p_interaction_at: fromBusinessLocalInput(optional(formData, "interaction_at")),
      p_interaction_type: value(formData, "interaction_type"), p_result: value(formData, "result"),
      p_next_action: value(formData, "next_action"), p_next_follow_up_at: fromBusinessLocalInput(optional(formData, "next_follow_up_at")),
      p_evidence_reference_url: optional(formData, "evidence_reference_url"), p_status: value(formData, "status"),
    });
    if (error) throw error; refresh(id); return { success: "Interaction added without changing prior history." };
  } catch (error) { return { error: safeMessage(error) }; }
}

export async function markLeadDuplicateAction(_previous: LeadActionState, formData: FormData): Promise<LeadActionState> {
  const id = value(formData, "duplicate_lead_id");
  try { const supabase = await createClient(); const { error } = await supabase.rpc("mark_marketing_lead_duplicate", { p_duplicate_lead_id: id, p_canonical_lead_id: value(formData, "canonical_lead_id") }); if (error) throw error; refresh(id); return { success: "Duplicate relationship recorded; source history was preserved." }; } catch (error) { return { error: safeMessage(error) }; }
}

export async function createLeadTaskAction(_previous: LeadActionState, formData: FormData): Promise<LeadActionState> {
  const id = value(formData, "lead_id");
  try { const supabase = await createClient(); const { error } = await supabase.rpc("create_lead_followup_task", { p_lead_id: id, p_due_date: optional(formData, "due_date"), p_priority: value(formData, "priority") }); if (error) throw error; refresh(id); return { success: "Restricted-reference follow-up task created." }; } catch (error) { return { error: safeMessage(error) }; }
}

export async function createMarketingCampaignAction(_previous: LeadActionState, formData: FormData): Promise<LeadActionState> {
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("create_marketing_campaign", {
      p_business_unit_id: value(formData, "business_unit_id"),
      p_department_id: value(formData, "department_id"),
      p_name: value(formData, "name"),
    });
    if (error) throw error;
    revalidatePath("/leads/campaigns");
    revalidatePath("/leads");
    return { success: "Campaign added. It is now available in the Lead form." };
  } catch (error) {
    return { error: safeMessage(error) };
  }
}
