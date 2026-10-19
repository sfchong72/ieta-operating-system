import { EmptyState } from "@/components/ui";
import type { WorkTask, WorkTaskAttention } from "@/lib/work-management";
import { AttentionBadges, PriorityLabel, TaskLink, WorkStatusBadge } from "./work-ui";

export function WorkTaskList({
  tasks,
  attentionById,
  assigneeById,
  departmentById,
  emptyTitle,
}: {
  tasks: WorkTask[];
  attentionById: Map<string, WorkTaskAttention>;
  assigneeById: Map<string, string>;
  departmentById: Map<string, string>;
  emptyTitle: string;
}) {
  if (!tasks.length) return <EmptyState title={emptyTitle} />;
  return <div className="overflow-x-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
    <table className="w-full min-w-[850px] text-left text-sm">
      <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-4 py-3.5">Task</th><th className="px-4 py-3.5">Assigned to</th><th className="px-4 py-3.5">Department</th><th className="px-4 py-3.5">Due</th><th className="px-4 py-3.5">Priority</th><th className="px-4 py-3.5">Status</th><th className="px-4 py-3.5">Attention</th></tr></thead>
      <tbody className="divide-y divide-slate-100">{tasks.map((task) => {
        const attention = attentionById.get(task.id);
        return <tr key={task.id} className="align-top hover:bg-neutral-50"><td className="px-4 py-3"><TaskLink id={task.id}>{task.title}</TaskLink><p className="mt-1 text-xs text-neutral-500">{task.task_number}{task.project_reference ? ` · ${task.project_reference}` : ""}</p></td><td className="px-4 py-3">{assigneeById.get(task.assigned_to) ?? "Assigned user"}</td><td className="px-4 py-3">{departmentById.get(task.department_id) ?? "—"}</td><td className="px-4 py-3">{task.due_date ?? "—"}</td><td className="px-4 py-3"><PriorityLabel priority={task.priority} /></td><td className="px-4 py-3"><WorkStatusBadge status={task.status} /><p className="mt-2 text-xs text-neutral-500">{task.progress_percent}%</p></td><td className="px-4 py-3"><AttentionBadges flags={attention?.attention_flags ?? []} /></td></tr>;
      })}</tbody>
    </table>
  </div>;
}
