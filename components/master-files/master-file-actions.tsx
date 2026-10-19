"use client";

import { useActionState } from "react";
import {
  grantMasterFileAccessAction,
  linkMasterFileArtifactAction,
  linkMasterFileTaskAction,
  markMasterFileDuplicateAction,
  revokeMasterFileAccessAction,
  setMasterFileStatusAction,
  supersedeMasterFileAction,
  verifyMasterFileAction,
  type MasterFileActionState,
} from "@/lib/actions/master-files";
import type { MasterFile, MasterFileAccessGrant, MasterFileSearchRow } from "@/lib/master-files";
import type { WorkAssignee, WorkTask } from "@/lib/work-management";
import { FormError } from "@/components/ui";
import { SubmitButton } from "@/components/submit-button";

const EMPTY: MasterFileActionState = {};
const inputClass = "w-full rounded-md border border-neutral-300 px-3 py-2 text-sm";

export function MasterFileGovernanceActions({
  file,
  candidates,
  people,
  tasks,
  grants,
}: {
  file: MasterFile;
  candidates: MasterFileSearchRow[];
  people: WorkAssignee[];
  tasks: WorkTask[];
  grants: MasterFileAccessGrant[];
}) {
  const replacements = candidates.filter((candidate) => candidate.id !== file.id && candidate.business_unit_id === file.business_unit_id && candidate.department_id === file.department_id && candidate.category_slug === file.category_slug && ["current", "under_review"].includes(candidate.status));
  const canonicals = candidates.filter((candidate) => candidate.id !== file.id && candidate.business_unit_id === file.business_unit_id && ["current", "under_review"].includes(candidate.status));
  return <div className="space-y-5">
    <div className="grid gap-4 md:grid-cols-2">
      <ActionCard title="Verify record"><SimpleAction action={verifyMasterFileAction} hidden={{ master_file_id: file.id }} submit="Mark verified" help="Confirms that the metadata and external link are still correct." /></ActionCard>
      <ActionCard title="Change status"><StatusAction fileId={file.id} currentStatus={file.status} /></ActionCard>
      <ActionCard title="Replace an earlier master"><SelectAction action={supersedeMasterFileAction} hidden={{ old_file_id: file.id }} fieldName="replacement_file_id" label="Replacement record" options={replacements.map((item) => [item.id, `${item.file_number} · ${item.file_name}`])} submit="Supersede with replacement" help="The selected replacement becomes Current; this record is preserved as Superseded." /></ActionCard>
      <ActionCard title="Mark this record as a duplicate"><SelectAction action={markMasterFileDuplicateAction} hidden={{ duplicate_file_id: file.id }} fieldName="canonical_file_id" label="Canonical record" options={canonicals.map((item) => [item.id, `${item.file_number} · ${item.file_name}`])} submit="Archive as duplicate" help="This record is retained and linked to the chosen canonical record." /></ActionCard>
      <ActionCard title="Link another task"><SelectAction action={linkMasterFileTaskAction} hidden={{ master_file_id: file.id }} fieldName="task_id" label="Task" options={tasks.map((task) => [task.id, `${task.task_number} · ${task.title}`])} submit="Link task" /></ActionCard>
      <ActionCard title="Link a task artifact"><TextAction action={linkMasterFileArtifactAction} hidden={{ master_file_id: file.id }} fieldName="task_artifact_id" label="Task artifact ID" submit="Link artifact" help="Use when a permitted task output is promoted into the reusable file register." /></ActionCard>
    </div>
    {file.access_level === "appointed_personnel" || file.access_level === "pc_restricted" ? <AccessActions file={file} people={people} grants={grants} /> : null}
  </div>;
}

function StatusAction({ fileId, currentStatus }: { fileId: string; currentStatus: string }) {
  const [state, action] = useActionState(setMasterFileStatusAction, EMPTY);
  return <form action={action} className="space-y-3"><input type="hidden" name="master_file_id" value={fileId} /><FormMessage state={state} /><select name="status" defaultValue={currentStatus === "superseded" ? "under_review" : currentStatus} className={inputClass}><option value="current">Current</option><option value="under_review">Under Review</option><option value="archived">Archived</option></select><p className="text-xs text-neutral-500">Use the replacement action for Superseded.</p><SubmitButton pendingText="Saving…">Update status</SubmitButton></form>;
}

function AccessActions({ file, people, grants }: { file: MasterFile; people: WorkAssignee[]; grants: MasterFileAccessGrant[] }) {
  const [grantState, grantAction] = useActionState(grantMasterFileAccessAction, EMPTY);
  const [revokeState, revokeAction] = useActionState(revokeMasterFileAccessAction, EMPTY);
  const granted = new Set(grants.map((grant) => grant.profile_id));
  const choices = Array.from(new Map(people.map((person) => [person.profile_id, person])).values()).filter((person) => !granted.has(person.profile_id));
  return <ActionCard title={file.access_level === "pc_restricted" ? "P&C appointed access" : "Appointed personnel access"}>
    <p className="mb-3 text-xs text-neutral-500">Access is explicit and enforced by row-level security. Changing an external provider’s permissions is outside Stage 4.</p>
    <ul className="mb-4 divide-y divide-neutral-200">{grants.map((grant) => <li key={`${grant.profile_id}-${grant.grant_type}`} className="flex flex-wrap items-center justify-between gap-2 py-2 text-sm"><span>{people.find((person) => person.profile_id === grant.profile_id)?.full_name ?? "Appointed user"} <span className="text-xs text-neutral-500">· {grant.grant_reason}</span></span>{grant.grant_reason === "explicit" && <form action={revokeAction}><input type="hidden" name="master_file_id" value={file.id} /><input type="hidden" name="profile_id" value={grant.profile_id} /><input type="hidden" name="grant_type" value={grant.grant_type} /><SubmitButton pendingText="Revoking…" className="rounded border border-neutral-300 px-2 py-1 text-xs">Revoke</SubmitButton></form>}</li>)}</ul>
    <FormMessage state={revokeState} />
    <form action={grantAction} className="flex flex-col gap-2 sm:flex-row"><input type="hidden" name="master_file_id" value={file.id} /><input type="hidden" name="grant_type" value={file.access_level} /><select name="profile_id" required defaultValue="" className={inputClass}><option value="">Select person</option>{choices.map((person) => <option key={person.profile_id} value={person.profile_id}>{person.full_name}</option>)}</select><SubmitButton pendingText="Granting…">Grant access</SubmitButton></form><FormMessage state={grantState} />
  </ActionCard>;
}

function SimpleAction({ action, hidden, submit, help }: { action: Parameters<typeof useActionState<MasterFileActionState, FormData>>[0]; hidden: Record<string, string>; submit: string; help?: string }) {
  const [state, formAction] = useActionState(action, EMPTY);
  return <form action={formAction} className="space-y-3">{Object.entries(hidden).map(([name, value]) => <input key={name} type="hidden" name={name} value={value} />)}{help && <p className="text-xs text-neutral-500">{help}</p>}<FormMessage state={state} /><SubmitButton pendingText="Saving…">{submit}</SubmitButton></form>;
}

function SelectAction({ action, hidden, fieldName, label, options, submit, help }: { action: Parameters<typeof useActionState<MasterFileActionState, FormData>>[0]; hidden: Record<string, string>; fieldName: string; label: string; options: [string, string][]; submit: string; help?: string }) {
  const [state, formAction] = useActionState(action, EMPTY);
  return <form action={formAction} className="space-y-3">{Object.entries(hidden).map(([name, value]) => <input key={name} type="hidden" name={name} value={value} />)}{help && <p className="text-xs text-neutral-500">{help}</p>}<label className="block text-sm font-medium">{label}<select name={fieldName} required defaultValue="" className={`mt-1 ${inputClass}`}><option value="">Select record</option>{options.map(([value, optionLabel]) => <option key={value} value={value}>{optionLabel}</option>)}</select></label><FormMessage state={state} /><SubmitButton pendingText="Saving…">{submit}</SubmitButton></form>;
}

function TextAction({ action, hidden, fieldName, label, submit, help }: { action: Parameters<typeof useActionState<MasterFileActionState, FormData>>[0]; hidden: Record<string, string>; fieldName: string; label: string; submit: string; help?: string }) {
  const [state, formAction] = useActionState(action, EMPTY);
  return <form action={formAction} className="space-y-3">{Object.entries(hidden).map(([name, value]) => <input key={name} type="hidden" name={name} value={value} />)}{help && <p className="text-xs text-neutral-500">{help}</p>}<label className="block text-sm font-medium">{label}<input name={fieldName} required className={`mt-1 ${inputClass}`} /></label><FormMessage state={state} /><SubmitButton pendingText="Saving…">{submit}</SubmitButton></form>;
}

function FormMessage({ state }: { state: MasterFileActionState }) { return <>{state.error && <FormError message={state.error} />}{state.success && <p role="status" className="text-sm font-medium text-emerald-700">{state.success}</p>}</>; }
function ActionCard({ title, children }: { title: string; children: React.ReactNode }) { return <section className="rounded-lg border border-neutral-200 p-4"><h3 className="mb-3 font-semibold">{title}</h3>{children}</section>; }

