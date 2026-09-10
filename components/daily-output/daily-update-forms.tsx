"use client";

import { useActionState } from "react";
import { reviewDailyWorkUpdateAction, submitDailyWorkUpdateAction, type DailyOutputActionState } from "@/lib/actions/daily-output";
import type { WorkTask } from "@/lib/work-management";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const EMPTY: DailyOutputActionState = {};
const inputClass = "mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-base md:text-sm";

function Result({ state }: { state: DailyOutputActionState }) {
  return <><FormError message={state.error} />{state.success && <p role="status" className="text-sm font-medium text-emerald-700">{state.success}</p>}</>;
}

function SafetyConfirmation({ defaultChecked = false }: { defaultChecked?: boolean }) {
  return <label className="flex items-start gap-2 text-xs leading-5 text-neutral-600"><input type="checkbox" name="data_handling_confirmed" required defaultChecked={defaultChecked} className="mt-1" /><span>No sensitive personal data is copied here; restricted matters use an approved restricted reference.</span></label>;
}

export function DailyUpdateForm({ tasks, selectedTaskId }: { tasks: WorkTask[]; selectedTaskId?: string }) {
  const [state, action] = useActionState(submitDailyWorkUpdateAction, EMPTY);
  const values = state.values ?? {};
  return <form key={state.formVersion ?? "initial"} action={action} className="space-y-4">
    <Result state={state} />
    <label className="block text-sm font-medium">Linked Task<select name="task_id" required defaultValue={String(values.task_id ?? selectedTaskId ?? "")} className={inputClass}><option value="" disabled>Choose task</option>{tasks.map((task) => <option key={task.id} value={task.id}>{task.task_number} — {task.title}</option>)}</select></label>
    <label className="block text-sm font-medium">What was done today<textarea name="what_done_today" required maxLength={2000} rows={3} defaultValue={String(values.what_done_today ?? "")} placeholder="State the work completed today." className={inputClass} /></label>
    <label className="block text-sm font-medium">Quantity<input name="quantity" maxLength={120} defaultValue={String(values.quantity ?? "")} placeholder="Example: 13 CVs or 8 pages" className={inputClass} /></label>
    <label className="block text-sm font-medium">Result / output<textarea name="result_or_output" required maxLength={2000} rows={3} defaultValue={String(values.result_or_output ?? "")} placeholder="State the result, outcome or output." className={inputClass} /></label>
    <label className="flex items-start gap-2 rounded-md bg-neutral-50 p-3 text-sm font-medium"><input type="checkbox" name="deliverable_completed" defaultChecked={values.deliverable_completed === true} className="mt-1" /><span>Deliverable completed today?<span className="mt-1 block text-xs font-normal text-neutral-500">If selected, the work/evidence link below is required.</span></span></label>
    <label className="block text-sm font-medium">Work / evidence link<input type="url" name="evidence_url" maxLength={2048} defaultValue={String(values.evidence_url ?? "")} placeholder="https://…" className={inputClass} /></label>
    <label className="block text-sm font-medium">Blocker / need help<textarea name="blocker_or_help" maxLength={1000} rows={2} defaultValue={String(values.blocker_or_help ?? "")} placeholder="Optional" className={inputClass} /></label>
    <SafetyConfirmation defaultChecked={values.data_handling_confirmed === true} />
    <SubmitButton pendingText="Submitting…">Submit daily update</SubmitButton>
  </form>;
}

export function DailyUpdateReviewForm({ updateId }: { updateId: string }) {
  const [state, action] = useActionState(reviewDailyWorkUpdateAction, EMPTY);
  const values = state.values ?? {};
  return <form key={state.formVersion ?? "initial"} action={action} className="space-y-4">
    <input type="hidden" name="daily_update_id" value={updateId} />
    <Result state={state} />
    <label className="block text-sm font-medium">Review status<select name="review_status" defaultValue={String(values.review_status ?? "checked")} className={inputClass}><option value="checked">Checked</option><option value="correction_required">Correction Required</option><option value="approved">Approved</option></select></label>
    <label className="block text-sm font-medium">Supervisor comment<textarea name="supervisor_comment" maxLength={2000} rows={3} defaultValue={String(values.supervisor_comment ?? "")} placeholder="Required when correction is needed" className={inputClass} /></label>
    <SafetyConfirmation defaultChecked={values.data_handling_confirmed === true} />
    <SubmitButton pendingText="Adding review…">Add supervisor review</SubmitButton>
  </form>;
}
