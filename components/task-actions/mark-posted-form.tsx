"use client";

import { useActionState } from "react";
import { markPostedAction, type ActionState } from "@/lib/actions/tasks";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function MarkPostedForm({ taskId }: { taskId: string }) {
  const [state, formAction] = useActionState(markPostedAction, initialState);

  return (
    <form
      action={formAction}
      className="space-y-3 rounded-lg border border-purple-200 bg-purple-50/40 p-4"
    >
      <h3 className="text-sm font-semibold">Mark posted</h3>
      <input type="hidden" name="task_id" value={taskId} />
      <FormError message={state.error} />
      <div>
        <label htmlFor="mp_actor" className="block text-xs font-medium text-neutral-600">
          Your name
        </label>
        <input
          id="mp_actor"
          name="actor_name"
          required
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        <div>
          <label htmlFor="mp_url" className="block text-xs font-medium text-neutral-600">
            Live post URL <span className="text-red-600">*</span>
          </label>
          <input
            id="mp_url"
            name="posted_url"
            required
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
            placeholder="https://instagram.com/p/…"
          />
        </div>
        <div>
          <label htmlFor="mp_date" className="block text-xs font-medium text-neutral-600">
            Posted date <span className="text-red-600">*</span>
          </label>
          <input
            type="date"
            id="mp_date"
            name="posted_date"
            required
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
      </div>
      <SubmitButton
        pendingText="Saving…"
        className="rounded-md bg-purple-700 px-4 py-2 text-sm font-medium text-white hover:bg-purple-800 disabled:opacity-50"
      >
        Mark Posted
      </SubmitButton>
    </form>
  );
}
