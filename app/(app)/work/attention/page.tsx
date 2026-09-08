import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import { listDepartments } from "@/lib/data/departments";
import { listAttentionTasks, listWorkAssignees, listWorkTasks } from "@/lib/data/work-management";
import { PageHeader } from "@/components/ui";
import { WorkTaskList } from "@/components/work/work-task-list";

export default async function NeedsAttentionPage() {
  const user = await getCurrentUser();
  if (!user || !["super_admin", "management"].includes(user.role ?? "")) redirect("/work");
  const [attention, allTasks, departments, assignees] = await Promise.all([listAttentionTasks(), listWorkTasks(), listDepartments(), listWorkAssignees()]);
  const ids = new Set(attention.map((item) => item.id));
  return <div><PageHeader title="Needs Attention" description="Overdue, stuck, blocked, waiting-feedback and evidence exceptions." /><WorkTaskList tasks={allTasks.filter((task) => ids.has(task.id))} attentionById={new Map(attention.map((item) => [item.id, item]))} assigneeById={new Map(assignees.map((item) => [item.profile_id, item.full_name]))} departmentById={new Map(departments.map((item) => [item.id, item.name]))} emptyTitle="No tasks currently need attention." /></div>;
}
