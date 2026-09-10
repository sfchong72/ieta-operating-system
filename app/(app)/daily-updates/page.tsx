import Link from "next/link";
import { DailyUpdateForm } from "@/components/daily-output/daily-update-forms";
import { getCurrentUser } from "@/lib/data/access";
import { listDailyWorkUpdates } from "@/lib/data/daily-output";
import { listWorkAssignees, listWorkTasks } from "@/lib/data/work-management";

export default async function DailyUpdatesPage({ searchParams }: { searchParams: Promise<{ task?: string }> }) {
  const user = await getCurrentUser();
  if (!user) return null;
  const canManage = user.role === "super_admin" || user.role === "management";
  const [{ task: selectedTaskId }, tasks, updates, assignees] = await Promise.all([searchParams, listWorkTasks(), listDailyWorkUpdates(), canManage ? listWorkAssignees() : Promise.resolve([])]);
  const eligibleTasks = tasks.filter((task) => !["completed", "cancelled"].includes(task.status) && (canManage || task.assigned_to === user.profile.id));
  const tasksById = new Map(tasks.map((task) => [task.id, task]));
  const names = new Map(assignees.map((person) => [person.profile_id, person.full_name]));
  names.set(user.profile.id, user.profile.full_name ?? user.profile.email);

  return <div className="mx-auto max-w-5xl space-y-8">
    <header><h1 className="text-2xl font-bold tracking-tight">Daily Update</h1><p className="mt-1 text-sm text-neutral-600">Record what was done, the result, evidence and any blocker. Keep it brief.</p></header>
    <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)]">
      <section className="rounded-lg border border-neutral-200 p-4 md:p-5"><h2 className="mb-4 text-base font-semibold">Submit today’s update</h2>{eligibleTasks.length ? <DailyUpdateForm tasks={eligibleTasks} selectedTaskId={selectedTaskId} /> : <p className="text-sm text-neutral-500">No active tasks are available for an update.</p>}</section>
      <section><h2 className="mb-4 text-base font-semibold">Update history</h2>{updates.length ? <ul className="space-y-3">{updates.map((update) => { const task = tasksById.get(update.task_id); return <li key={update.id}><Link href={`/daily-updates/${update.id}`} className="block rounded-lg border border-neutral-200 p-4 transition hover:border-neutral-400"><div className="flex flex-wrap items-center justify-between gap-2"><span className="text-xs font-medium text-neutral-500">{task?.task_number ?? "Task"} · {update.work_date}</span>{update.deliverable_completed && <span className="rounded bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700">Deliverable completed</span>}</div><p className="mt-2 font-medium">{task?.title ?? "Visible task"}</p><p className="mt-1 text-xs text-neutral-500">{names.get(update.staff_id) ?? "Assigned staff"}</p><p className="mt-1 line-clamp-2 text-sm text-neutral-600">{update.what_done_today}</p></Link></li>; })}</ul> : <p className="rounded-lg border border-dashed border-neutral-300 p-5 text-sm text-neutral-500">No daily updates yet.</p>}</section>
    </div>
  </div>;
}
