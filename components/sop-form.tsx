"use client";

import { useActionState } from "react";
import { createSopAction, updateSopAction, type ActionState } from "@/lib/actions/sops";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
import type { Department, Sop } from "@/lib/data/types";

const initialState: ActionState = {};

export function SopForm({
  departments,
  sop,
}: {
  departments: Department[];
  sop?: Sop;
}) {
  const action = sop ? updateSopAction : createSopAction;
  const [state, formAction] = useActionState(action, initialState);

  return (
    <form action={formAction} className="max-w-xl space-y-4">
      <FormError message={state.error} />
      {sop && <input type="hidden" name="id" value={sop.id} />}

      <div>
        <label htmlFor="title" className="block text-sm font-medium">
          Title <span className="text-red-600">*</span>
        </label>
        <input
          id="title"
          name="title"
          required
          defaultValue={sop?.title}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="e.g. Instagram Reel Production SOP"
        />
      </div>

      <div>
        <label htmlFor="department_id" className="block text-sm font-medium">
          Department
        </label>
        <select
          id="department_id"
          name="department_id"
          defaultValue={sop?.department_id ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        >
          <option value="">—</option>
          {departments.map((d) => (
            <option key={d.id} value={d.id}>
              {d.name}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label htmlFor="master_drive_link" className="block text-sm font-medium">
          Master Drive link
        </label>
        <input
          id="master_drive_link"
          name="master_drive_link"
          defaultValue={sop?.master_drive_link ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="https://drive.google.com/…"
        />
      </div>

      <div>
        <label htmlFor="version" className="block text-sm font-medium">
          Version
        </label>
        <input
          id="version"
          name="version"
          defaultValue={sop?.version ?? "v1"}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      <div>
        <label htmlFor="content" className="block text-sm font-medium">
          Steps / content
        </label>
        <textarea
          id="content"
          name="content"
          rows={6}
          defaultValue={sop?.content ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      <SubmitButton pendingText="Saving…">{sop ? "Save changes" : "Create SOP"}</SubmitButton>
    </form>
  );
}
