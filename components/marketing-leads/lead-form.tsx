"use client";
import { useActionState } from "react";
import { createMarketingLeadAction, updateMarketingLeadAction, type LeadActionState } from "@/lib/actions/marketing-leads";
import type { BusinessUnit, Campaign, Department } from "@/lib/data/types";
import type { LeadSource, MarketingLead } from "@/lib/marketing-leads";
import { LEAD_STATUSES, humaniseLead } from "@/lib/marketing-leads";
import type { WorkAssignee } from "@/lib/work-management";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
const EMPTY: LeadActionState = {};
const input = "mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm";
const local = (value?: string | null) => value ? new Date(value).toISOString().slice(0, 16) : "";

export function LeadForm({ lead, sources, businessUnits, departments, campaigns, assignees }: { lead?: MarketingLead; sources: LeadSource[]; businessUnits: BusinessUnit[]; departments: Department[]; campaigns: Campaign[]; assignees: WorkAssignee[] }) {
  const [state, action] = useActionState(lead ? updateMarketingLeadAction : createMarketingLeadAction, EMPTY);
  return <form action={action} className="max-w-5xl space-y-5">
    <FormError message={state.error} />{lead && <input type="hidden" name="lead_id" value={lead.id} />}
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {!lead && <Field label="Date received" required><input type="datetime-local" name="date_received" defaultValue={local()} className={input} /></Field>}
      <Field label="Business unit" required><select name="business_unit_id" required defaultValue={lead?.business_unit_id ?? ""} className={input}><option value="">Select</option>{businessUnits.map((x)=><option key={x.id} value={x.id}>{x.name}</option>)}</select></Field>
      <Field label="Department" required><select name="department_id" required defaultValue={lead?.department_id ?? ""} className={input}><option value="">Select</option>{departments.map((x)=><option key={x.id} value={x.id}>{x.name}</option>)}</select></Field>
      <Field label="Branch" required><input name="branch" required maxLength={120} defaultValue={lead?.branch ?? ""} className={input} /></Field>
      <Field label="Source" required><select name="source_slug" required defaultValue={lead?.source_slug ?? ""} className={input}><option value="">Select</option>{sources.map((x)=><option key={x.slug} value={x.slug}>{x.label}</option>)}</select></Field>
      <Field label="Campaign"><select name="campaign_id" defaultValue={lead?.campaign_id ?? ""} className={input}><option value="">No campaign</option>{campaigns.map((x)=><option key={x.id} value={x.id}>{x.name}</option>)}</select></Field>
      <Field label="Project reference"><input name="project_reference" maxLength={160} defaultValue={lead?.project_reference ?? ""} className={input} /></Field>
      <Field label="Assigned to" required><select name="assigned_to_profile_id" required defaultValue={lead?.assigned_to_profile_id ?? ""} className={input}><option value="">Select</option>{assignees.map((x)=><option key={x.profile_id} value={x.profile_id}>{x.full_name}</option>)}</select></Field>
      <Field label="Status" required><select name="status" required defaultValue={lead?.status ?? "new"} className={input}>{(lead ? LEAD_STATUSES : ["new"] as const).map((x)=><option key={x} value={x}>{humaniseLead(x)}</option>)}</select></Field>
    </div>
    <div className="rounded-lg border border-red-200 bg-red-50 p-4"><p className="mb-3 text-sm font-semibold text-red-900">Restricted contact details</p><div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <Field label="Name" required><input name="name" required maxLength={160} defaultValue={lead?.name ?? ""} className={input} /></Field>
      <Field label="Contact number" required><input name="contact_number" required maxLength={50} defaultValue={lead?.contact_number ?? ""} className={input} /></Field>
      <Field label="Email"><input type="email" name="email" maxLength={254} defaultValue={lead?.email ?? ""} className={input} /></Field>
      <Field label="Country"><input name="country" maxLength={100} defaultValue={lead?.country ?? ""} className={input} /></Field>
      <Field label="Nationality"><input name="nationality" maxLength={100} defaultValue={lead?.nationality ?? ""} className={input} /></Field>
      <Field label="Programme interest" required><input name="programme_interest" required maxLength={200} defaultValue={lead?.programme_interest ?? ""} className={input} /></Field>
    </div></div>
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <Field label="Next follow-up"><input type="datetime-local" name="next_follow_up_at" defaultValue={local(lead?.next_follow_up_at)} className={input} /></Field>
      <Field label="Consultation date"><input type="datetime-local" name="consultation_date" defaultValue={local(lead?.consultation_date)} className={input} /></Field>
      <Field label="Estimated / actual value"><input type="number" min="0" step="0.01" name="estimated_or_actual_value" defaultValue={lead?.estimated_or_actual_value ?? ""} className={input} /></Field>
      <Field label="Source reference URL"><input type="url" name="source_reference_url" maxLength={2048} defaultValue={lead?.source_reference_url ?? ""} className={input} /></Field>
      {lead && <Field label="Final outcome"><input name="final_outcome" maxLength={1000} defaultValue={lead.final_outcome ?? ""} className={input} /></Field>}
    </div>
    <Field label="Remarks" hint="Use interactions for follow-up history."><textarea name="remarks" rows={3} maxLength={2000} defaultValue={lead?.remarks ?? ""} className={input} /></Field>
    <label className="flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm"><input type="checkbox" name="data_handling_confirmed" required className="mt-1" /><span>I confirm this PII belongs in the restricted Lead Register and is not copied into generic tasks or comments.</span></label>
    <SubmitButton pendingText="Saving…">{lead ? "Save lead" : "Add lead"}</SubmitButton>
  </form>;
}
function Field({ label, required, hint, children }: { label: string; required?: boolean; hint?: string; children: React.ReactNode }) { return <label className="block text-sm font-medium">{label}{required && <span className="text-red-600"> *</span>}{children}{hint && <span className="mt-1 block text-xs font-normal text-neutral-500">{hint}</span>}</label>; }

