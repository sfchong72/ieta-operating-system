import { listDepartments } from "@/lib/data/departments";
import { listIdeas } from "@/lib/data/content-ideas";
import { TaskForm } from "@/components/task-form";
import { PageHeader } from "@/components/ui";

export default async function NewTaskPage({
  searchParams,
}: {
  searchParams: Promise<{ idea_id?: string }>;
}) {
  const { idea_id } = await searchParams;
  const [departments, ideas] = await Promise.all([listDepartments(), listIdeas()]);

  return (
    <div>
      <PageHeader title="New Task" description="Assign a content task to a PIC." />
      <TaskForm departments={departments} ideas={ideas} defaultIdeaId={idea_id} />
    </div>
  );
}
