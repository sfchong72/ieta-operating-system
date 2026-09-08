"use client";

import { useActionState } from "react";
import {
  addWorkArtifactAction,
  addWorkCommentAction,
  quickUpdateWorkTaskAction,
  superviseWorkTaskAction,
  type WorkActionState,
} from "@/lib/actions/work-management";
import { ARTIFACT_SENSITIVITIES, ARTIFACT_TYPES, WORK_STATUSES, type WorkTask } from "@/lib/work-management";
import { FormError } from "@/components/ui";
import { SubmitButton } from "@/components/submit-button";
import { humanise } from "./work-ui";

const EMPTY: WorkActionState = {};
const inputClass = "mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm";

function Result({ state }: { state: WorkActionState }) {
  return <><FormError message={state.error} />{state.success && <p role="status" className="text-sm font-medium text-emerald-700">{state.success}</p>}</>;
}

export function QuickUpdateForm({ task }: { task: WorkTask }) {
  const [state, action] = useActionState(quickUpdateWorkTaskAction, EMPTY);
  return <form action={action} className="space-y-3">
    <input type="hidden" name="task_id" value={task.id} />
    <Result state={state} />
    <div className="grid gap-3 sm:grid-cols-2">
      <label className="text-sm font-medium">Status<select name="status" defaultValue={task.status} className={inputClass}>{WORK_STATUSES.map((status) => <option key={status} value={status}>{humanise(status)}</option>)}</select></label>
      <label className="text-sm font-medium">Progress %<input name="progress_percent" type="number" min="0" max="100" defaultValue={task.progress_percent} className={inputClass} /></label>
    </div>
    <label className="block text-sm font-medium">Blocker / need help<textarea name="blocker_or_help" rows={2} defaultValue={task.current_blocker ?? ""} className={inputClass} /></label>
    <SafetyConfirmation />
    <SubmitButton pendingText="Updating…">Update task</SubmitButton>
  </form>;
}

export function ArtifactForm({ taskId, canManage }: { taskId: string; canManage: boolean }) {
  const [state, action] = useActionState(addWorkArtifactAction, EMPTY);
  return <form action={action} className="space-y-3">
    <input type="hidden" name="task_id" value={taskId} /><input type="hidden" name="managed" value={canManage ? "true" : "false"} />
    <Result state={state} />
    <label className="block text-sm font-medium">Canva / artwork / Drive link<input type="url" name="url" required placeholder="https://…" className={inputClass} /></label>
    <div className="grid gap-3 sm:grid-cols-2"><label className="text-sm font-medium">Link type<select name="artifact_type" defaultValue="working" className={inputClass}>{ARTIFACT_TYPES.map((item) => <option key={item} value={item}>{humanise(item)}</option>)}</select></label>{canManage && <label className="text-sm font-medium">Sensitivity<select name="artifact_sensitivity" defaultValue="operational" className={inputClass}>{ARTIFACT_SENSITIVITIES.map((item) => <option key={item} value={item}>{humanise(item)}</option>)}</select></label>}</div>
    <label className="block text-sm font-medium">Label<input name="label" maxLength={160} placeholder="Optional" className={inputClass} /></label>
    <SubmitButton pendingText="Adding…">Add link</SubmitButton>
  </form>;
}

export function CommentForm({ taskId }: { taskId: string }) {
  const [state, action] = useActionState(addWorkCommentAction, EMPTY);
  return <form action={action} className="space-y-3"><input type="hidden" name="task_id" value={taskId} /><Result state={state} /><label className="block text-sm font-medium">Comment<textarea name="body" required maxLength={2000} rows={3} className={inputClass} /></label><SafetyConfirmation /><SubmitButton pendingText="Adding…">Add comment</SubmitButton></form>;
}

export function SupervisorForm({ task }: { task: WorkTask }) {
  const [state, action] = useActionState(superviseWorkTaskAction, EMPTY);
  return <form action={action} className="space-y-3"><input type="hidden" name="task_id" value={task.id} /><Result state={state} /><label className="block text-sm font-medium">Comments / feedback<textarea name="feedback" maxLength={2000} rows={3} className={inputClass} /></label><label className="block text-sm font-medium">Next action<textarea name="next_action" maxLength={1000} rows={2} defaultValue={task.next_action ?? ""} className={inputClass} /></label><div className="space-y-2 text-sm"><label className="flex gap-2"><input type="checkbox" name="approve_final" /> Final output reviewed and approved</label>{!task.output_required && <><label className="flex gap-2"><input type="checkbox" name="waive_output" /> Approve no-output waiver</label><input name="waiver_reason" placeholder="Required waiver reason" className={inputClass} /></>}<label className="flex gap-2"><input type="checkbox" name="complete_task" /> Complete task now</label><label className="flex gap-2"><input type="checkbox" name="feedback_management_only" /> Management-only feedback</label></div><SafetyConfirmation /><SubmitButton pendingText="Saving…">Save supervisor review</SubmitButton></form>;
}

function SafetyConfirmation() {
  return <label className="flex items-start gap-2 text-xs text-neutral-600"><input type="checkbox" name="data_handling_confirmed" required className="mt-0.5" /><span>No sensitive personal data is copied here; restricted matters use an approved restricted reference.</span></label>;
}
