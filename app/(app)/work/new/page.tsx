import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { listWorkAssignees } from "@/lib/data/work-management";
import { PageHeader } from "@/components/ui";
import { WorkTaskForm } from "@/components/work/work-task-form";

export default async function CreateWorkTaskPage() {
  const user = await getCurrentUser();
  if (!user || !["super_admin", "management"].includes(user.role ?? "")) redirect("/work");
  const [businessUnits, departments, assignees] = await Promise.all([listBusinessUnits(), listDepartments(), listWorkAssignees()]);
  return <div><PageHeader title="Create Task" description="Assign clear work with an expected output and deadline." /><WorkTaskForm businessUnits={businessUnits} departments={departments} assignees={assignees} /></div>;
}
