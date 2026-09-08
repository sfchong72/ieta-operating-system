import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import { listDepartments } from "@/lib/data/departments";
import { listAttentionTasks, listWorkAssignees, listWorkTasks } from "@/lib/data/work-management";
import { PageHeader } from "@/components/ui";
import { WorkTaskList } from "@/components/work/work-task-list";
import { WorkTaskFilters, type WorkFilterValues } from "@/components/work/work-task-filters";
import { filterWorkTasks } from "@/lib/work-management";

export default async function TeamTasksPage({ searchParams }: { searchParams: Promise<WorkFilterValues> }) {
  const filters = await searchParams;
  const user = await getCurrentUser();
  if (!user || !["super_admin", "management"].includes(user.role ?? "")) redirect("/work");
  const [tasks, attention, departments, assignees] = await Promise.all([listWorkTasks(), listAttentionTasks(), listDepartments(), listWorkAssignees()]);
  return <div><PageHeader title="Team Tasks" description="Operational tasks within your authorised scope." action={<Link href="/work/new" className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white">Create Task</Link>} /><WorkTaskFilters values={filters} departments={departments} resetHref="/work/team" /><WorkTaskList tasks={filterWorkTasks(tasks, filters)} attentionById={new Map(attention.map((item) => [item.id, item]))} assigneeById={new Map(assignees.map((item) => [item.profile_id, item.full_name]))} departmentById={new Map(departments.map((item) => [item.id, item.name]))} emptyTitle="No team tasks match these filters." /></div>;
}
