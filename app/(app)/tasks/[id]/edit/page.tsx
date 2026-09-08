import Link from "next/link";
import { notFound } from "next/navigation";
import { getTask } from "@/lib/data/content-tasks";
import { listDepartments } from "@/lib/data/departments";
import { listIdeas } from "@/lib/data/content-ideas";
import { TaskForm } from "@/components/task-form";
import { PageHeader } from "@/components/ui";

export default async function EditTaskPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [task, departments, ideas] = await Promise.all([
    getTask(id),
    listDepartments(),
    listIdeas(),
  ]);
  if (!task) notFound();

  return (
    <div>
      <Link href={`/tasks/${task.id}`} className="text-sm text-neutral-500 hover:underline">
        ← Back to task
      </Link>
      <PageHeader title="Edit Task" description="Update details for this task." />
      <TaskForm departments={departments} ideas={ideas} task={task} />
    </div>
  );
}
