"use client";
import { useActionState } from "react";
import { addLeadInteractionAction, createLeadTaskAction, markLeadDuplicateAction, type LeadActionState } from "@/lib/actions/marketing-leads";
import type { LeadDuplicateWarning } from "@/lib/marketing-leads";
import { LEAD_INTERACTION_TYPES, LEAD_STATUSES, humaniseLead } from "@/lib/marketing-leads";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
const EMPTY: LeadActionState = {};
const input = "mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm";

export function LeadInteractionForm({ leadId }: { leadId: string }) {
  const [state, action] = useActionState(addLeadInteractionAction, EMPTY);
  return <form action={action} className="space-y-3 rounded-lg border border-neutral-200 p-4"><h2 className="font-semibold">Add interaction</h2><FormError message={state.error} />{state.success && <p className="text-sm text-emerald-700">{state.success}</p>}<input type="hidden" name="lead_id" value={leadId} />
    <div className="grid gap-3 sm:grid-cols-2"><label className="text-sm">When<input type="datetime-local" name="interaction_at" className={input} /></label><label className="text-sm">Type<select name="interaction_type" defaultValue="call" className={input}>{LEAD_INTERACTION_TYPES.map(x=><option key={x} value={x}>{humaniseLead(x)}</option>)}</select></label></div>
    <label className="block text-sm">Result<textarea name="result" required maxLength={2000} rows={3} className={input} /></label>
    <label className="block text-sm">Next action<input name="next_action" required maxLength={1000} className={input} /></label>
    <div className="grid gap-3 sm:grid-cols-2"><label className="text-sm">Next follow-up<input type="datetime-local" name="next_follow_up_at" className={input} /></label><label className="text-sm">New status<select name="status" defaultValue="follow_up" className={input}>{LEAD_STATUSES.filter(x=>x!=="new").map(x=><option key={x} value={x}>{humaniseLead(x)}</option>)}</select></label></div>
    <label className="block text-sm">Permitted evidence / reference URL<input type="url" name="evidence_reference_url" maxLength={2048} className={input} /></label><SubmitButton pendingText="Adding…">Add interaction</SubmitButton>
  </form>;
}

export function LeadManagementActions({ leadId, duplicates }: { leadId: string; duplicates: LeadDuplicateWarning[] }) {
  const [dupState, dupAction] = useActionState(markLeadDuplicateAction, EMPTY);
  const [taskState, taskAction] = useActionState(createLeadTaskAction, EMPTY);
  return <div className="space-y-4">
    {duplicates.length > 0 && <form action={dupAction} className="rounded-lg border border-amber-300 bg-amber-50 p-4"><h2 className="font-semibold">Duplicate warning</h2><p className="mt-1 text-sm">Review only. Inter Excel Operating System will not merge or delete either record.</p><FormError message={dupState.error} />{dupState.success && <p className="text-sm text-emerald-700">{dupState.success}</p>}<input type="hidden" name="duplicate_lead_id" value={leadId} /><select name="canonical_lead_id" className={input}>{duplicates.map(x=><option key={x.possible_duplicate_id} value={x.possible_duplicate_id}>{x.lead_number} · {x.name} · {x.reasons.join(", ")}</option>)}</select><div className="mt-3"><SubmitButton pendingText="Recording…">Confirm duplicate</SubmitButton></div></form>}
    <form action={taskAction} className="rounded-lg border border-neutral-200 p-4"><h2 className="font-semibold">Create related task</h2><p className="mt-1 text-sm text-neutral-600">The task will contain only the restricted lead number—never contact details.</p><FormError message={taskState.error} />{taskState.success && <p className="text-sm text-emerald-700">{taskState.success}</p>}<input type="hidden" name="lead_id" value={leadId} /><div className="mt-3 grid gap-3 sm:grid-cols-2"><label className="text-sm">Due date<input type="date" name="due_date" className={input} /></label><label className="text-sm">Priority<select name="priority" defaultValue="medium" className={input}><option value="urgent">Urgent</option><option value="high">High</option><option value="medium">Medium</option><option value="low">Low</option></select></label></div><div className="mt-3"><SubmitButton pendingText="Creating…">Create follow-up task</SubmitButton></div></form>
  </div>;
}
