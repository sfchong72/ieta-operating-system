"use client";

import { useActionState } from "react";
import { createTaskAction, updateTaskAction, type ActionState } from "@/lib/actions/tasks";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
import type { Department, ContentIdea, ContentTask } from "@/lib/data/types";

const PLATFORMS = ["Instagram", "TikTok", "YouTube", "Facebook"];

const initialState: ActionState = {};

export function TaskForm({
  departments,
  ideas,
  defaultIdeaId,
  task,
}: {
  departments: Department[];
  ideas: ContentIdea[];
  defaultIdeaId?: string;
  /** When provided, the form edits this task instead of creating a new one. */
  task?: ContentTask;
}) {
  const isEdit = Boolean(task);
  const [state, formAction] = useActionState(
    isEdit ? updateTaskAction : createTaskAction,
    initialState,
  );

  return (
    <form action={formAction} className="max-w-xl space-y-4">
      <FormError message={state.error} />
      {task && <input type="hidden" name="task_id" value={task.id} />}

      <div>
        <label htmlFor="title" className="block text-sm font-medium">
          Task title <span className="text-red-600">*</span>
        </label>
        <input
          id="title"
          name="title"
          required
          defaultValue={task?.title}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="e.g. IETA Welcome Reel — Instagram"
        />
      </div>

      {!isEdit && (
        <div>
          <label htmlFor="idea_id" className="block text-sm font-medium">
            Linked idea (optional)
          </label>
          <select
            id="idea_id"
            name="idea_id"
            defaultValue={defaultIdeaId ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            <option value="">— Standalone task —</option>
            {ideas.map((idea) => (
              <option key={idea.id} value={idea.id}>
                {idea.title}
              </option>
            ))}
          </select>
        </div>
      )}

      <div>
        <label htmlFor="pic_name" className="block text-sm font-medium">
          PIC name <span className="text-red-600">*</span>
        </label>
        <input
          id="pic_name"
          name="pic_name"
          required
          defaultValue={task?.pic_name}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="Who is doing this?"
        />
        {isEdit && (
          <p className="mt-1 text-xs text-neutral-500">
            Reassigning? Just change the name above — the change is recorded in the activity trail.
          </p>
        )}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="department_id" className="block text-sm font-medium">
            Department
          </label>
          <select
            id="department_id"
            name="department_id"
            defaultValue={task?.department_id ?? ""}
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
          <label htmlFor="platform" className="block text-sm font-medium">
            Platform
          </label>
          <select
            id="platform"
            name="platform"
            defaultValue={task?.platform ?? ""}
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
      </div>

      <div>
        <label htmlFor="deadline" className="block text-sm font-medium">
          Deadline
        </label>
        <input
          type="date"
          id="deadline"
          name="deadline"
          defaultValue={task?.deadline ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      <div>
        <label htmlFor="remarks" className="block text-sm font-medium">
          Remarks
        </label>
        <textarea
          id="remarks"
          name="remarks"
          rows={3}
          defaultValue={task?.remarks ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      {isEdit && (
        <div>
          <label htmlFor="actor_name" className="block text-sm font-medium">
            Your name <span className="text-red-600">*</span>
          </label>
          <input
            id="actor_name"
            name="actor_name"
            required
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
            placeholder="Who is making this change?"
          />
        </div>
      )}

      <SubmitButton pendingText={isEdit ? "Saving…" : "Creating…"}>
        {isEdit ? "Save changes" : "Create task"}
      </SubmitButton>
    </form>
  );
}
