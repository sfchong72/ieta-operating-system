"use client";

import { useActionState } from "react";
import {
  approveContentItemAction,
  requestRevisionAction,
  addCommentAction,
  type ActionState,
} from "@/lib/actions/approvals";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function ApprovalQueueForms({ contentItemId }: { contentItemId: string }) {
  const [approveState, approveAction] = useActionState(approveContentItemAction, initialState);
  const [revisionState, revisionAction] = useActionState(requestRevisionAction, initialState);
  const [commentState, commentAction] = useActionState(addCommentAction, initialState);

  return (
    <div className="mt-3 grid gap-3 sm:grid-cols-3">
      <form
        action={approveAction}
        className="space-y-2 rounded-lg border border-emerald-200 bg-emerald-50/40 p-3"
      >
        <input type="hidden" name="content_item_id" value={contentItemId} />
        <FormError message={approveState.error} />
        <label htmlFor={`approve-comment-${contentItemId}`} className="block text-xs font-medium text-neutral-600">
          Approve (remark optional)
        </label>
        <textarea
          id={`approve-comment-${contentItemId}`}
          name="comment"
          rows={2}
          className="w-full rounded-md border border-neutral-300 px-2 py-1 text-sm"
        />
        <SubmitButton
          pendingText="Approving…"
          className="w-full rounded-md bg-emerald-700 px-3 py-1.5 text-sm font-medium text-white hover:bg-emerald-800 disabled:opacity-50"
        >
          Approve
        </SubmitButton>
      </form>

      <form
        action={revisionAction}
        className="space-y-2 rounded-lg border border-orange-200 bg-orange-50/40 p-3"
      >
        <input type="hidden" name="content_item_id" value={contentItemId} />
        <FormError message={revisionState.error} />
        <label htmlFor={`revision-comment-${contentItemId}`} className="block text-xs font-medium text-neutral-600">
          Request revision (comment required)
        </label>
        <textarea
          id={`revision-comment-${contentItemId}`}
          name="comment"
          required
          rows={2}
          className="w-full rounded-md border border-neutral-300 px-2 py-1 text-sm"
        />
        <SubmitButton
          pendingText="Sending back…"
          className="w-full rounded-md bg-orange-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-orange-700 disabled:opacity-50"
        >
          Request Revision
        </SubmitButton>
      </form>

      <form
        action={commentAction}
        className="space-y-2 rounded-lg border border-neutral-200 p-3"
      >
        <input type="hidden" name="content_item_id" value={contentItemId} />
        <FormError message={commentState.error} />
        <label htmlFor={`comment-${contentItemId}`} className="block text-xs font-medium text-neutral-600">
          Comment only (no status change)
        </label>
        <textarea
          id={`comment-${contentItemId}`}
          name="comment"
          required
          rows={2}
          className="w-full rounded-md border border-neutral-300 px-2 py-1 text-sm"
        />
        <SubmitButton
          pendingText="Posting…"
          className="w-full rounded-md border border-neutral-300 px-3 py-1.5 text-sm font-medium hover:bg-neutral-50 disabled:opacity-50"
        >
          Comment
        </SubmitButton>
      </form>
    </div>
  );
}
