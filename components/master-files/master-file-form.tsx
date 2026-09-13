"use client";

import { useActionState } from "react";
import { createMasterFileAction, updateMasterFileAction, type MasterFileActionState } from "@/lib/actions/master-files";
import type { BusinessUnit, Department } from "@/lib/data/types";
import type { MasterFile, MasterFileCategory } from "@/lib/master-files";
import { MASTER_FILE_ACCESS_LEVELS, MASTER_FILE_SOURCE_SYSTEMS, humaniseMasterFile } from "@/lib/master-files";
import type { WorkAssignee, WorkTask } from "@/lib/work-management";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const EMPTY: MasterFileActionState = {};
const inputClass = "mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm";

export function MasterFileForm({
  businessUnits,
  departments,
  categories,
  owners,
  tasks,
  file,
  canSetPc,
}: {
  businessUnits: BusinessUnit[];
  departments: Department[];
  categories: MasterFileCategory[];
  owners: WorkAssignee[];
  tasks: WorkTask[];
  file?: MasterFile;
  canSetPc: boolean;
}) {
  const [state, action] = useActionState(file ? updateMasterFileAction : createMasterFileAction, EMPTY);
  const uniqueOwners = Array.from(new Map(owners.map((owner) => [owner.profile_id, owner])).values());
  return <form action={action} className="max-w-4xl space-y-5">
    <FormError message={state.error} />
    {file && <input type="hidden" name="master_file_id" value={file.id} />}
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label="File name" required hint="Use a stable name. Status replaces FINAL, FINAL2, LATEST or NEW FINAL naming."><input name="file_name" required maxLength={200} defaultValue={file?.file_name ?? ""} className={inputClass} /></Field>
      <Field label="Category" required><select name="category_slug" required defaultValue={file?.category_slug ?? ""} className={inputClass}><option value="">Select category</option>{categories.map((category) => <option key={category.slug} value={category.slug}>{category.label}</option>)}</select></Field>
      <Field label="Business unit" required><select name="business_unit_id" required defaultValue={file?.business_unit_id ?? ""} className={inputClass}><option value="">Select business unit</option>{businessUnits.filter((unit) => unit.is_active || unit.id === file?.business_unit_id).map((unit) => <option key={unit.id} value={unit.id}>{unit.name}</option>)}</select></Field>
      <Field label="Department" required><select name="department_id" required defaultValue={file?.department_id ?? ""} className={inputClass}><option value="">Select department</option>{departments.map((department) => <option key={department.id} value={department.id}>{department.name}</option>)}</select></Field>
      <Field label="Owner" required><select name="owner_profile_id" required defaultValue={file?.owner_profile_id ?? ""} className={inputClass}><option value="">Select owner</option>{uniqueOwners.map((owner) => <option key={owner.profile_id} value={owner.profile_id}>{owner.full_name} · {humaniseMasterFile(owner.role)}</option>)}</select></Field>
      <Field label="Project / campaign"><input name="project_reference" maxLength={160} defaultValue={file?.project_reference ?? ""} className={inputClass} placeholder="Optional reference until Project Register stage" /></Field>
    </div>
    <Field label="Description" hint="Describe the asset, not confidential people or financial details."><textarea name="description" maxLength={2000} rows={3} defaultValue={file?.description ?? ""} className={inputClass} /></Field>
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label="Master link" required={false} hint="Required before a record can be Current."><input type="url" name="master_url" maxLength={2048} defaultValue={file?.master_url ?? ""} className={inputClass} placeholder="https://…" /></Field>
      <Field label="Folder link"><input type="url" name="folder_url" maxLength={2048} defaultValue={file?.folder_url ?? ""} className={inputClass} placeholder="https://…" /></Field>
      <Field label="Source system"><select name="source_system" defaultValue={file?.source_system ?? ""} className={inputClass}><option value="">Auto-detect from link</option>{MASTER_FILE_SOURCE_SYSTEMS.map((source) => <option key={source} value={source}>{humaniseMasterFile(source)}</option>)}</select></Field>
      <Field label="Access level" required><select name="access_level" required defaultValue={file?.access_level ?? "operational"} className={inputClass}>{MASTER_FILE_ACCESS_LEVELS.filter((level) => level !== "pc_restricted" || canSetPc || file?.access_level === level).map((level) => <option key={level} value={level}>{level === "pc_restricted" ? "P&C Restricted" : humaniseMasterFile(level)}</option>)}</select></Field>
      {!file && <Field label="Starting status" required><select name="status" required defaultValue="under_review" className={inputClass}><option value="under_review">Under Review</option><option value="current">Current</option></select></Field>}
      {!file && <Field label="Related task"><select name="related_task_id" defaultValue="" className={inputClass}><option value="">No task link</option>{tasks.map((task) => <option key={task.id} value={task.id}>{task.task_number} · {task.title}</option>)}</select></Field>}
    </div>
    {canSetPc && <label className="flex items-start gap-2 text-sm"><input type="checkbox" name="password_reference" defaultChecked={file?.password_reference ?? false} className="mt-1" /><span>This record is only a reference to an approved password-storage location. It contains no password, passcode or OTP.</span></label>}
    <Field label="Remarks"><textarea name="remarks" maxLength={2000} rows={3} defaultValue={file?.remarks ?? ""} className={inputClass} /></Field>
    <label className="flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-950"><input type="checkbox" name="data_handling_confirmed" required className="mt-1" /><span>I confirm this register entry contains no actual passwords and no unauthorised personal, student, candidate or financial data.</span></label>
    <SubmitButton pendingText="Saving…">{file ? "Save metadata" : "Add file record"}</SubmitButton>
  </form>;
}

function Field({ label, required, hint, children }: { label: string; required?: boolean; hint?: string; children: React.ReactNode }) {
  return <label className="block text-sm font-medium">{label}{required && <span className="text-red-600"> *</span>}{children}{hint && <span className="mt-1 block text-xs font-normal text-neutral-500">{hint}</span>}</label>;
}

