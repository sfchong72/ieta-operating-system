"use client";

import { useActionState } from "react";
import { submitForReviewAction, type ActionState } from "@/lib/actions/tasks";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function SubmitReviewForm({ taskId }: { taskId: string }) {
  const [state, formAction] = useActionState(submitForReviewAction, initialState);

  return (
    <form action={formAction} className="space-y-3 rounded-lg border border-neutral-200 p-4">
      <h3 className="text-sm font-semibold">Submit for review</h3>
      <input type="hidden" name="task_id" value={taskId} />
      <FormError message={state.error} />
      <div>
        <label htmlFor="sr_actor" className="block text-xs font-medium text-neutral-600">
          Your name
        </label>
        <input
          id="sr_actor"
          name="actor_name"
          required
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>
      <SubmitButton pendingText="Submitting…">Submit for Review</SubmitButton>
    </form>
  );
}
