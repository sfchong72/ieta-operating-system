import Link from "next/link";
import { listTasks } from "@/lib/data/content-tasks";
import { listDepartments } from "@/lib/data/departments";
import { PageHeader, EmptyState, StatusBadge } from "@/components/ui";

export default async function TasksPage() {
  const [tasks, departments] = await Promise.all([listTasks(), listDepartments()]);
  const deptById = new Map(departments.map((d) => [d.id, d.name]));

  return (
    <div>
      <PageHeader
        title="Tasks"
        description="Every content task, assign → work → submit → approve → post."
        action={
          <Link
            href="/tasks/new"
            className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800"
          >
            New Task
          </Link>
        }
      />

      {tasks.length === 0 ? (
        <EmptyState
          title="No tasks yet — create your first content task"
          cta="New Task"
          href="/tasks/new"
        />
      ) : (
        <div className="overflow-x-auto rounded-lg border border-neutral-200">
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead className="bg-neutral-50 text-xs uppercase text-neutral-500">
              <tr>
                <th className="px-4 py-3 font-medium">Title</th>
                <th className="px-4 py-3 font-medium">PIC</th>
                <th className="px-4 py-3 font-medium">Department</th>
                <th className="px-4 py-3 font-medium">Platform</th>
                <th className="px-4 py-3 font-medium">Deadline</th>
                <th className="px-4 py-3 font-medium">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {tasks.map((task) => (
                <tr key={task.id} className="hover:bg-neutral-50">
                  <td className="px-4 py-3">
                    <Link href={`/tasks/${task.id}`} className="font-medium hover:underline">
                      {task.title}
                    </Link>
                  </td>
                  <td className="px-4 py-3">{task.pic_name}</td>
                  <td className="px-4 py-3">
                    {task.department_id ? (deptById.get(task.department_id) ?? "—") : "—"}
                  </td>
                  <td className="px-4 py-3">{task.platform ?? "—"}</td>
                  <td className="px-4 py-3">{task.deadline ?? "—"}</td>
                  <td className="px-4 py-3">
                    <StatusBadge status={task.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
