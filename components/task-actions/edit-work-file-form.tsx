"use client";

import { useActionState, useState } from "react";
import { updateWorkFileAction, type ActionState } from "@/lib/actions/tasks";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
import type { WorkFile } from "@/lib/data/types";

const initialState: ActionState = {};

/** Inline "correct this link" form — lets a work file be edited in place, not just replaced by a new one. */
export function EditWorkFileForm({ file, taskId }: { file: WorkFile; taskId: string }) {
  const [open, setOpen] = useState(false);
  const [state, formAction] = useActionState(updateWorkFileAction, initialState);

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="text-xs text-neutral-500 hover:underline"
      >
        Edit
      </button>
    );
  }

  return (
    <form action={formAction} className="mt-2 space-y-2 rounded-md border border-neutral-200 p-3">
      <input type="hidden" name="work_file_id" value={file.id} />
      <input type="hidden" name="task_id" value={taskId} />
      <FormError message={state.error} />
      <div>
        <label htmlFor={`ewf_actor_${file.id}`} className="block text-xs font-medium text-neutral-600">
          Your name
        </label>
        <input
          id={`ewf_actor_${file.id}`}
          name="actor_name"
          required
          className="mt-1 w-full rounded-md border border-neutral-300 px-2 py-1.5 text-sm"
        />
      </div>
      <div>
        <label htmlFor={`ewf_label_${file.id}`} className="block text-xs font-medium text-neutral-600">
          Label
        </label>
        <input
          id={`ewf_label_${file.id}`}
          name="label"
          defaultValue={file.label ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-2 py-1.5 text-sm"
        />
      </div>
      <div>
        <label htmlFor={`ewf_url_${file.id}`} className="block text-xs font-medium text-neutral-600">
          URL <span className="text-red-600">*</span>
        </label>
        <input
          id={`ewf_url_${file.id}`}
          name="url"
          required
          defaultValue={file.url}
          className="mt-1 w-full rounded-md border border-neutral-300 px-2 py-1.5 text-sm"
        />
      </div>
      <div className="flex items-center gap-3">
        <SubmitButton pendingText="Saving…">Save</SubmitButton>
        <button
          type="button"
          onClick={() => setOpen(false)}
          className="text-xs text-neutral-500 hover:underline"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
