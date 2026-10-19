export const LEAD_STATUSES = [
  "new", "contacted", "follow_up", "consultation_booked", "interested",
  "application", "signed_up", "not_suitable", "no_response", "withdrawn", "closed_other",
] as const;

export const LEAD_INTERACTION_TYPES = [
  "call", "whatsapp", "email", "consultation", "walk_in", "video_call", "event", "other",
] as const;

export type LeadStatus = (typeof LEAD_STATUSES)[number];
export type LeadInteractionType = (typeof LEAD_INTERACTION_TYPES)[number];

export type LeadSource = { slug: string; label: string; sort_order: number; is_active: boolean };

export type MarketingLead = {
  id: string; lead_number: string; date_received: string; business_unit_id: string;
  department_id: string; branch: string; source_slug: string; campaign_id: string | null;
  project_reference: string | null; name: string; contact_number: string; email: string | null;
  country: string | null; nationality: string | null; programme_interest: string;
  assigned_to_profile_id: string; status: LeadStatus; last_contact_at: string | null;
  next_follow_up_at: string | null; contact_result: string | null;
  consultation_date: string | null; final_outcome: string | null;
  estimated_or_actual_value: number | null; source_reference_url: string | null;
  remarks: string | null; duplicate_of_lead_id: string | null; created_by: string;
  created_at: string; updated_at: string; row_version: number;
};

export type MarketingLeadRow = MarketingLead & {
  business_unit_name: string; department_name: string; source_label: string;
  campaign_name: string | null; assigned_to_name: string; attention_reason: string | null;
};

export type LeadInteraction = {
  id: string; lead_id: string; interaction_at: string; interaction_type: LeadInteractionType;
  performed_by: string; performer_name: string; result: string; next_action: string;
  next_follow_up_at: string | null; evidence_reference_url: string | null; created_at: string;
};

export type LeadAuditEvent = {
  event_id: number; event_type: string; actor_id: string; actor_name: string;
  metadata: Record<string, unknown>; created_at: string;
};

export type LeadDuplicateWarning = { possible_duplicate_id: string; lead_number: string; name: string; reasons: string[] };
export type LeadTaskLink = { task_id: string; task_number: string; task_title: string };

export type LeadFilters = {
  q?: string; assignedTo?: string; businessUnit?: string; branch?: string; source?: string;
  campaign?: string; status?: string; programme?: string; followUpFrom?: string;
  followUpTo?: string; receivedFrom?: string; receivedTo?: string;
  myLeads?: boolean; dueOnly?: boolean;
};

export type LeadSummary = {
  authorised: boolean; new_leads?: number; pending_follow_up?: number; overdue?: number;
  consultations_booked?: number; applications?: number; signed_up?: number;
  by_source?: Record<string, number>;
};

export function humaniseLead(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (character) => character.toUpperCase());
}

export function formatLeadDate(value: string | null) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("en-MY", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Kuala_Lumpur" }).format(new Date(value));
}

