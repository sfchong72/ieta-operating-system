"use client";

import { useActionState } from "react";
import {
  createKnowledgeItemAction,
  updateKnowledgeItemAction,
  type ActionState,
} from "@/lib/actions/knowledge";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
import type { KnowledgeItem } from "@/lib/data/types";

const initialState: ActionState = {};

export function KnowledgeForm({ item }: { item?: KnowledgeItem }) {
  const action = item ? updateKnowledgeItemAction : createKnowledgeItemAction;
  const [state, formAction] = useActionState(action, initialState);

  return (
    <form action={formAction} className="max-w-xl space-y-4">
      <FormError message={state.error} />
      {item && <input type="hidden" name="id" value={item.id} />}

      <div>
        <label htmlFor="title" className="block text-sm font-medium">
          Title <span className="text-red-600">*</span>
        </label>
        <input
          id="title"
          name="title"
          required
          defaultValue={item?.title}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="e.g. IETA Brand Colors"
        />
      </div>

      <div>
        <label htmlFor="category" className="block text-sm font-medium">
          Category
        </label>
        <input
          id="category"
          name="category"
          defaultValue={item?.category ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="e.g. Branding"
        />
      </div>

      <div>
        <label htmlFor="body" className="block text-sm font-medium">
          Content
        </label>
        <textarea
          id="body"
          name="body"
          rows={6}
          defaultValue={item?.body ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      <div>
        <label htmlFor="tags" className="block text-sm font-medium">
          Tags
        </label>
        <input
          id="tags"
          name="tags"
          defaultValue={item?.tags?.join(", ") ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="comma, separated, tags"
        />
      </div>

      <SubmitButton pendingText="Saving…">{item ? "Save changes" : "Create item"}</SubmitButton>
    </form>
  );
}
