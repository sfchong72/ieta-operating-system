"use client";

import { useState, useTransition } from "react";

/**
 * Renders a "Delete" trigger that opens a confirm/cancel modal, then submits
 * the given server action with the given hidden fields. Used for SOPs,
 * content tasks, and knowledge items per docs/TEST_PLAN.md delete-confirmation flow.
 */
export function DeleteButton({
  action,
  fields,
  itemLabel = "item",
  className,
}: {
  action: (formData: FormData) => void | Promise<void>;
  fields: Record<string, string>;
  itemLabel?: string;
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className={
          className ??
          "rounded-md border border-red-300 px-3 py-1.5 text-sm font-medium text-red-700 hover:bg-red-50"
        }
      >
        Delete
      </button>

      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="delete-dialog-title"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
        >
          <div className="w-full max-w-sm rounded-lg bg-white p-5 shadow-xl">
            <h2 id="delete-dialog-title" className="text-base font-semibold">
              Delete this {itemLabel}?
            </h2>
            <p className="mt-1 text-sm text-neutral-600">This cannot be undone.</p>
            <div className="mt-4 flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-md border border-neutral-300 px-3 py-1.5 text-sm font-medium hover:bg-neutral-50"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={isPending}
                onClick={() => {
                  const fd = new FormData();
                  Object.entries(fields).forEach(([k, v]) => fd.set(k, v));
                  startTransition(async () => {
                    await action(fd);
                    setOpen(false);
                  });
                }}
                className="rounded-md bg-red-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
              >
                {isPending ? "Deleting…" : "Confirm delete"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
