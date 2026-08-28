import type { ContentItemStatus, ContentItemApprovalStatus } from "@/lib/data/types";

const WORKFLOW_STYLES: Record<ContentItemStatus, string> = {
  draft: "bg-neutral-100 text-neutral-600",
  in_progress: "bg-blue-100 text-blue-700",
  awaiting_approval: "bg-amber-100 text-amber-800",
  revision_required: "bg-orange-100 text-orange-800",
  approved: "bg-emerald-100 text-emerald-700",
  scheduled_publishing: "bg-purple-100 text-purple-700",
  published: "bg-purple-200 text-purple-800",
  archived: "bg-neutral-200 text-neutral-500",
};

const WORKFLOW_LABELS: Record<ContentItemStatus, string> = {
  draft: "Draft",
  in_progress: "In Progress",
  awaiting_approval: "Awaiting Approval",
  revision_required: "Revision Required",
  approved: "Approved",
  scheduled_publishing: "Scheduled/Publishing",
  published: "Published",
  archived: "Archived",
};

export function WorkflowBadge({ status }: { status: ContentItemStatus }) {
  return (
    <span
      className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${WORKFLOW_STYLES[status]}`}
    >
      {WORKFLOW_LABELS[status]}
    </span>
  );
}

const APPROVAL_STYLES: Record<string, string> = {
  pending: "bg-amber-100 text-amber-800",
  approved: "bg-emerald-100 text-emerald-700",
  amend: "bg-orange-100 text-orange-800",
};

export function ApprovalBadge({ status }: { status: ContentItemApprovalStatus }) {
  if (!status) return <span className="text-xs text-neutral-400">—</span>;
  return (
    <span
      className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${APPROVAL_STYLES[status] ?? "bg-neutral-100 text-neutral-600"}`}
    >
      {status}
    </span>
  );
}
