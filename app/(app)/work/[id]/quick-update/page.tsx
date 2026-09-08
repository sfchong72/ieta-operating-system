import Link from "next/link";
import { notFound } from "next/navigation";
import { getWorkTask } from "@/lib/data/work-management";
import { PageHeader } from "@/components/ui";
import { QuickUpdateForm } from "@/components/work/task-interactions";

export default async function QuickUpdatePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const task = await getWorkTask(id);
  if (!task) notFound();
  return <div className="max-w-xl"><PageHeader title="Quick Update" description={`${task.task_number} · ${task.title}`} action={<Link href={`/work/${id}`} className="text-sm font-medium underline">Task Detail</Link>} /><div className="rounded-lg border border-neutral-200 p-5"><QuickUpdateForm task={task} /></div></div>;
}
