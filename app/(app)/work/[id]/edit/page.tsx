import { notFound, redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { getWorkTask, listWorkAssignees } from "@/lib/data/work-management";
import { PageHeader } from "@/components/ui";
import { WorkTaskForm } from "@/components/work/work-task-form";

export default async function EditWorkTaskPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser();
  if (!user || !["super_admin", "management"].includes(user.role ?? "")) redirect(`/work/${id}`);
  const [task, businessUnits, departments, assignees] = await Promise.all([getWorkTask(id), listBusinessUnits(), listDepartments(), listWorkAssignees()]);
  if (!task) notFound();
  if (user.role === "management" && !user.businessUnitIds.includes(task.business_unit_id)) redirect(`/work/${id}`);
  return <div><PageHeader title={`Edit ${task.task_number}`} description="Update assignment and scope. Progress remains in Quick Update." /><WorkTaskForm task={task} businessUnits={businessUnits} departments={departments} assignees={assignees} canSetPc={user.role === "super_admin"} /></div>;
}
