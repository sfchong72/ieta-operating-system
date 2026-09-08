import type { ApprovalActionWithActor } from "@/lib/data/approval-actions";

const ACTION_LABELS: Record<string, string> = {
  submitted: "submitted for review",
  approved: "approved",
  revision_requested: "requested revision",
  comment: "commented",
  edited: "edited",
};

const ACTION_STYLES: Record<string, string> = {
  submitted: "bg-amber-100 text-amber-800",
  approved: "bg-emerald-100 text-emerald-700",
  revision_requested: "bg-orange-100 text-orange-800",
  comment: "bg-neutral-100 text-neutral-600",
  edited: "bg-blue-100 text-blue-700",
};

/** Full immutable approval history, oldest to newest. */
export function ApprovalHistory({ actions }: { actions: ApprovalActionWithActor[] }) {
  if (actions.length === 0) {
    return <p className="mt-2 text-sm text-neutral-500">No approval activity yet.</p>;
  }
  return (
    <ul className="mt-2 space-y-2">
      {actions.map((a) => (
        <li key={a.id} className="rounded-md border border-neutral-200 p-3 text-sm">
          <span className="font-medium">{a.actor?.full_name ?? a.actor?.email ?? "Unknown"}</span>{" "}
          <span
            className={`ml-1 inline-block rounded-full px-2 py-0.5 text-xs font-medium ${
              ACTION_STYLES[a.action] ?? "bg-neutral-100 text-neutral-600"
            }`}
          >
            {ACTION_LABELS[a.action] ?? a.action}
          </span>
          {a.comment && <p className="mt-1 text-neutral-600">{a.comment}</p>}
          <div className="mt-1 text-xs text-neutral-400">
            {new Date(a.created_at).toLocaleString()}
          </div>
        </li>
      ))}
    </ul>
  );
}
