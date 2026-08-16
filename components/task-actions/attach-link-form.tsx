"use client";

import { useActionState } from "react";
import { attachWorkLinkAction, type ActionState } from "@/lib/actions/tasks";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function AttachLinkForm({ taskId }: { taskId: string }) {
  const [state, formAction] = useActionState(attachWorkLinkAction, initialState);

  return (
    <form action={formAction} className="space-y-3 rounded-lg border border-neutral-200 p-4">
      <h3 className="text-sm font-semibold">Attach work link</h3>
      <input type="hidden" name="task_id" value={taskId} />
      <FormError message={state.error} />
      <div>
        <label htmlFor="al_actor" className="block text-xs font-medium text-neutral-600">
          Your name
        </label>
        <input
          id="al_actor"
          name="actor_name"
          required
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label htmlFor="al_label" className="block text-xs font-medium text-neutral-600">
          Label (optional)
        </label>
        <input
          id="al_label"
          name="label"
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="e.g. Draft v1"
        />
      </div>
      <div>
        <label htmlFor="al_url" className="block text-xs font-medium text-neutral-600">
          Canva or Drive link <span className="text-red-600">*</span>
        </label>
        <input
          id="al_url"
          name="url"
          required
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="https://canva.com/design/…"
        />
      </div>
      <SubmitButton pendingText="Attaching…">Attach link</SubmitButton>
    </form>
  );
}
