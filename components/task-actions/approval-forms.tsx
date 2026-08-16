"use client";

import { useActionState } from "react";
import { approveTaskAction, amendTaskAction, type ActionState } from "@/lib/actions/tasks";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function ApprovalForms({ taskId }: { taskId: string }) {
  const [approveState, approveAction] = useActionState(approveTaskAction, initialState);
  const [amendState, amendActionFn] = useActionState(amendTaskAction, initialState);

  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <form
        action={approveAction}
        className="space-y-3 rounded-lg border border-emerald-200 bg-emerald-50/40 p-4"
      >
        <h3 className="text-sm font-semibold">Approve (as manager)</h3>
        <input type="hidden" name="task_id" value={taskId} />
        <FormError message={approveState.error} />
        <div>
          <label htmlFor="ap_actor" className="block text-xs font-medium text-neutral-600">
            Manager name <span className="text-red-600">*</span>
          </label>
          <input
            id="ap_actor"
            name="actor_name"
            required
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label htmlFor="ap_remark" className="block text-xs font-medium text-neutral-600">
            Remark (optional)
          </label>
          <textarea
            id="ap_remark"
            name="remark"
            rows={2}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
        <SubmitButton
          pendingText="Approving…"
          className="rounded-md bg-emerald-700 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-800 disabled:opacity-50"
        >
          Approve
        </SubmitButton>
      </form>

      <form
        action={amendActionFn}
        className="space-y-3 rounded-lg border border-orange-200 bg-orange-50/40 p-4"
      >
        <h3 className="text-sm font-semibold">Send back for amendment</h3>
        <input type="hidden" name="task_id" value={taskId} />
        <FormError message={amendState.error} />
        <div>
          <label htmlFor="am_actor" className="block text-xs font-medium text-neutral-600">
            Manager name <span className="text-red-600">*</span>
          </label>
          <input
            id="am_actor"
            name="actor_name"
            required
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label htmlFor="am_remark" className="block text-xs font-medium text-neutral-600">
            Remark <span className="text-red-600">*</span>
          </label>
          <textarea
            id="am_remark"
            name="remark"
            required
            rows={2}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
            placeholder="What needs to change?"
          />
        </div>
        <SubmitButton
          pendingText="Sending back…"
          className="rounded-md bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700 disabled:opacity-50"
        >
          Send back
        </SubmitButton>
      </form>
    </div>
  );
}
