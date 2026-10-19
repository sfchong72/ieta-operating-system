import Link from "next/link";
import type { WorkTaskAttention } from "@/lib/work-management";
import { AttentionBadges, WorkStatusBadge } from "@/components/work/work-ui";

function formatActivity(value: string | null) {
  if (!value) return "No activity";
  return new Intl.DateTimeFormat("en-MY", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Kuala_Lumpur" }).format(new Date(value));
}

function ArtifactIndicator({ value }: { value: WorkTaskAttention["artifact_indicator"] }) {
  const label = value === "final_or_evidence" ? "Final / evidence" : value === "working" ? "Working link" : "No artifact";
  const style = value === "final_or_evidence" ? "bg-emerald-50 text-emerald-800" : value === "working" ? "bg-blue-50 text-blue-800" : "bg-neutral-100 text-neutral-600";
  return <span className={`rounded px-2 py-1 text-xs font-medium ${style}`}>{label}</span>;
}

export function AttentionList({
  tasks,
  assigneeNames,
  departmentNames,
  limit,
}: {
  tasks: WorkTaskAttention[];
  assigneeNames: Map<string, string>;
  departmentNames: Map<string, string>;
  limit?: number;
}) {
  const rows = typeof limit === "number" ? tasks.slice(0, limit) : tasks;
  if (!rows.length) return <div className="rounded-lg border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">No tasks currently need attention within these filters.</div>;
  return <>
    <div className="space-y-3 md:hidden">{rows.map((task) => <article key={task.id} className="rounded-lg border border-neutral-200 p-4">
      <div className="flex items-start justify-between gap-3"><div><p className="text-xs font-medium text-neutral-500">{task.task_number}</p><Link href={`/work/${task.id}`} className="font-semibold hover:underline">{task.title}</Link></div><WorkStatusBadge status={task.status} /></div>
      <dl className="mt-3 grid grid-cols-2 gap-3 text-xs"><div><dt className="text-neutral-500">Assigned to</dt><dd className="mt-1 font-medium">{assigneeNames.get(task.assigned_to) ?? "Assigned user"}</dd></div><div><dt className="text-neutral-500">Department</dt><dd className="mt-1 font-medium">{departmentNames.get(task.department_id) ?? "—"}</dd></div><div><dt className="text-neutral-500">Deadline</dt><dd className="mt-1">{task.due_date ?? "—"}</dd></div><div><dt className="text-neutral-500">Activity days</dt><dd className="mt-1">{task.meaningful_working_days}</dd></div><div className="col-span-2"><dt className="text-neutral-500">Last activity</dt><dd className="mt-1">{formatActivity(task.last_activity_at)}</dd></div></dl>
      <div className="mt-3 flex flex-wrap gap-2"><AttentionBadges flags={task.attention_flags} /><ArtifactIndicator value={task.artifact_indicator} /></div>
      <Link href={`/work/${task.id}`} className="mt-4 inline-block text-sm font-medium underline">Open Task Detail</Link>
    </article>)}</div>
    <div className="hidden overflow-x-auto rounded-lg border border-neutral-200 md:block"><table className="w-full min-w-[1120px] text-left text-sm"><thead className="bg-neutral-50 text-xs uppercase text-neutral-500"><tr><th className="px-4 py-3">Task</th><th className="px-4 py-3">Assigned / Department</th><th className="px-4 py-3">Deadline</th><th className="px-4 py-3">Status</th><th className="px-4 py-3">Activity</th><th className="px-4 py-3">Attention reason</th><th className="px-4 py-3">Artifact</th></tr></thead><tbody className="divide-y divide-neutral-200">{rows.map((task) => <tr key={task.id} className="align-top hover:bg-neutral-50"><td className="px-4 py-3"><Link href={`/work/${task.id}`} className="font-medium hover:underline">{task.title}</Link><p className="mt-1 text-xs text-neutral-500">{task.task_number}</p></td><td className="px-4 py-3">{assigneeNames.get(task.assigned_to) ?? "Assigned user"}<p className="mt-1 text-xs text-neutral-500">{departmentNames.get(task.department_id) ?? "—"}</p></td><td className="px-4 py-3">{task.due_date ?? "—"}</td><td className="px-4 py-3"><WorkStatusBadge status={task.status} /></td><td className="px-4 py-3"><p>{task.meaningful_working_days} working days</p><p className="mt-1 text-xs text-neutral-500">{formatActivity(task.last_activity_at)}</p></td><td className="px-4 py-3"><AttentionBadges flags={task.attention_flags} /></td><td className="px-4 py-3"><ArtifactIndicator value={task.artifact_indicator} /></td></tr>)}</tbody></table></div>
  </>;
}
