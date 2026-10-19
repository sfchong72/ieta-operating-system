"use client";

import { useActionState } from "react";
import { submitForReviewAction, type ActionState } from "@/lib/actions/approvals";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function SubmitReviewForm({ contentItemId }: { contentItemId: string }) {
  const [state, formAction] = useActionState(submitForReviewAction, initialState);
  return (
    <form action={formAction} className="rounded-lg border border-neutral-200 p-4">
      <input type="hidden" name="content_item_id" value={contentItemId} />
      <FormError message={state.error} />
      <SubmitButton pendingText="Submitting…">Submit for Review</SubmitButton>
    </form>
  );
}
