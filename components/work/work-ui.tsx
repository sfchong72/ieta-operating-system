import Link from "next/link";
import type { WorkPriority, WorkStatus } from "@/lib/work-management";

const STATUS_STYLE: Record<WorkStatus, string> = {
  backlog: "bg-neutral-100 text-neutral-700",
  not_started: "bg-slate-100 text-slate-700",
  in_progress: "bg-blue-100 text-blue-800",
  waiting_feedback: "bg-amber-100 text-amber-800",
  blocked: "bg-red-100 text-red-800",
  on_hold: "bg-stone-100 text-stone-700",
  completed: "bg-emerald-100 text-emerald-800",
  cancelled: "bg-neutral-200 text-neutral-600",
};

const PRIORITY_STYLE: Record<WorkPriority, string> = {
  urgent: "text-red-700",
  high: "text-orange-700",
  medium: "text-blue-700",
  low: "text-neutral-600",
};

export function humanise(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

export function WorkStatusBadge({ status }: { status: WorkStatus }) {
  return <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${STATUS_STYLE[status]}`}>{humanise(status)}</span>;
}

export function PriorityLabel({ priority }: { priority: WorkPriority }) {
  return <span className={`text-xs font-semibold uppercase ${PRIORITY_STYLE[priority]}`}>{priority}</span>;
}

export function AttentionBadges({ flags }: { flags: string[] }) {
  if (!flags.length) return null;
  return <div className="flex flex-wrap gap-1">{flags.map((flag) => <span key={flag} className="rounded bg-red-50 px-2 py-1 text-xs font-medium text-red-800">{flag}</span>)}</div>;
}

export function TaskLink({ id, children }: { id: string; children: React.ReactNode }) {
  return <Link href={`/work/${id}`} className="font-medium text-neutral-950 hover:underline">{children}</Link>;
}
