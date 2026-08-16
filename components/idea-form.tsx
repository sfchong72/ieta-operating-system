"use client";

import { useActionState } from "react";
import { createIdeaAction, updateIdeaAction, type ActionState } from "@/lib/actions/ideas";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
import type { ContentIdea } from "@/lib/data/types";

const PLATFORMS = ["Instagram", "TikTok", "YouTube", "Facebook"];
const STATUSES = ["idea", "selected", "tasked", "archived"];

const initialState: ActionState = {};

export function IdeaForm({ idea }: { idea?: ContentIdea }) {
  const action = idea ? updateIdeaAction : createIdeaAction;
  const [state, formAction] = useActionState(action, initialState);

  return (
    <form action={formAction} className="max-w-xl space-y-4">
      <FormError message={state.error} />
      {idea && <input type="hidden" name="id" value={idea.id} />}

      <div>
        <label htmlFor="title" className="block text-sm font-medium">
          Title <span className="text-red-600">*</span>
        </label>
        <input
          id="title"
          name="title"
          required
          defaultValue={idea?.title}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="e.g. Student Testimonial TikTok"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="platform" className="block text-sm font-medium">
            Platform
          </label>
          <select
            id="platform"
            name="platform"
            defaultValue={idea?.platform ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            <option value="">—</option>
            {PLATFORMS.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="topic" className="block text-sm font-medium">
            Topic
          </label>
          <input
            id="topic"
            name="topic"
            defaultValue={idea?.topic ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
      </div>

      {idea && (
        <div>
          <label htmlFor="status" className="block text-sm font-medium">
            Status
          </label>
          <select
            id="status"
            name="status"
            defaultValue={idea.status}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </div>
      )}

      <SubmitButton pendingText="Saving…">{idea ? "Save changes" : "Create idea"}</SubmitButton>
    </form>
  );
}
