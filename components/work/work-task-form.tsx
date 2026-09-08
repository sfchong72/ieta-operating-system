"use client";

import { useActionState } from "react";
import { createWorkTaskAction, updateWorkTaskAction, type WorkActionState } from "@/lib/actions/work-management";
import { ARTIFACT_SENSITIVITIES, WORK_PRIORITIES, type WorkAssignee, type WorkTask } from "@/lib/work-management";
import type { BusinessUnit, Department } from "@/lib/data/types";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
import { humanise } from "./work-ui";

const EMPTY: WorkActionState = {};
const inputClass = "mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm";

export function WorkTaskForm({
  businessUnits,
  departments,
  assignees,
  task,
}: {
  businessUnits: BusinessUnit[];
  departments: Department[];
  assignees: WorkAssignee[];
  task?: WorkTask;
}) {
  const [state, action] = useActionState(task ? updateWorkTaskAction : createWorkTaskAction, EMPTY);
  const uniqueAssignees = Array.from(new Map(assignees.map((person) => [person.profile_id, person])).values());

  return (
    <form action={action} className="max-w-3xl space-y-5">
      <FormError message={state.error} />
      {task && <input type="hidden" name="task_id" value={task.id} />}

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Assigned to" required>
          <select name="assigned_to" required defaultValue={task?.assigned_to ?? ""} className={inputClass}>
            <option value="">Select person</option>
            {uniqueAssignees.map((person) => <option key={person.profile_id} value={person.profile_id}>{person.full_name} · {humanise(person.role)}</option>)}
          </select>
        </Field>
        <Field label="Department" required>
          <select name="department_id" required defaultValue={task?.department_id ?? ""} className={inputClass}>
            <option value="">Select department</option>
            {departments.map((department) => <option key={department.id} value={department.id}>{department.name}</option>)}
          </select>
        </Field>
        <Field label="Business unit" required>
          <select name="business_unit_id" required defaultValue={task?.business_unit_id ?? ""} className={inputClass}>
            <option value="">Select business unit</option>
            {businessUnits.map((unit) => <option key={unit.id} value={unit.id}>{unit.name}</option>)}
          </select>
        </Field>
        <Field label="Project / campaign">
          <input name="project_reference" defaultValue={task?.project_reference ?? ""} className={inputClass} placeholder="Optional short reference" />
        </Field>
      </div>

      <Field label="Task" required>
        <input name="title" required maxLength={160} defaultValue={task?.title ?? ""} className={inputClass} placeholder="Short, clear task title" />
      </Field>
      <Field label="Clear instructions" required hint="Do not include student, candidate, financial or other sensitive personal data.">
        <textarea name="instructions" required maxLength={4000} rows={5} defaultValue={task?.instructions ?? ""} className={inputClass} />
      </Field>
      <Field label="Expected final output">
        <textarea name="expected_final_output" maxLength={1000} rows={2} defaultValue={task?.expected_final_output ?? ""} className={inputClass} placeholder="Example: approved Canva artwork link" />
      </Field>

      <div className="grid gap-4 sm:grid-cols-3">
        <Field label="Deadline"><input type="date" name="due_date" defaultValue={task?.due_date ?? ""} className={inputClass} /></Field>
        <Field label="Priority" required>
          <select name="priority" defaultValue={task?.priority ?? "medium"} className={inputClass}>{WORK_PRIORITIES.map((item) => <option key={item} value={item}>{humanise(item)}</option>)}</select>
        </Field>
        <Field label="Sensitivity" required>
          <select name="task_sensitivity" defaultValue={task?.task_sensitivity ?? "operational"} className={inputClass}>{ARTIFACT_SENSITIVITIES.map((item) => <option key={item} value={item}>{humanise(item)}</option>)}</select>
        </Field>
      </div>

      {!task && <Field label="Starting status"><select name="status" defaultValue="not_started" className={inputClass}><option value="not_started">Not Started</option><option value="backlog">Backlog</option></select></Field>}
      <label className="flex items-start gap-2 text-sm"><input type="checkbox" name="output_required" defaultChecked={task?.output_required ?? true} className="mt-1" /><span>This task requires final output or evidence.</span></label>
      <label className="flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-950"><input type="checkbox" name="data_handling_confirmed" required className="mt-1" /><span>I confirm the task text contains no sensitive personal data. Restricted matters use a restricted record ID or restricted link.</span></label>
      <SubmitButton pendingText="Saving…">{task ? "Save task" : "Create task"}</SubmitButton>
    </form>
  );
}

function Field({ label, hint, required, children }: { label: string; hint?: string; required?: boolean; children: React.ReactNode }) {
  return <label className="block text-sm font-medium">{label}{required && <span className="text-red-600"> *</span>}{children}{hint && <span className="mt-1 block text-xs font-normal text-neutral-500">{hint}</span>}</label>;
}
