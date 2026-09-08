import { getCurrentUser } from "@/lib/data/access";
import { listDepartments } from "@/lib/data/departments";
import { listAttentionTasks, listWorkTasks } from "@/lib/data/work-management";
import { PageHeader } from "@/components/ui";
import { WorkTaskList } from "@/components/work/work-task-list";
import { WorkTaskFilters, type WorkFilterValues } from "@/components/work/work-task-filters";
import { filterWorkTasks } from "@/lib/work-management";

export default async function MyWorkPage({ searchParams }: { searchParams: Promise<WorkFilterValues> }) {
  const filters = await searchParams;
  const user = await getCurrentUser();
  if (!user) return null;
  const [tasks, attention, departments] = await Promise.all([listWorkTasks(user.profile.id), listAttentionTasks(), listDepartments()]);
  return <div><PageHeader title="My Work" description="Your assigned work, deadlines, progress and evidence." /><WorkTaskFilters values={filters} resetHref="/work" /><WorkTaskList tasks={filterWorkTasks(tasks, filters)} attentionById={new Map(attention.map((item) => [item.id, item]))} assigneeById={new Map([[user.profile.id, user.profile.full_name ?? user.profile.email]])} departmentById={new Map(departments.map((item) => [item.id, item.name]))} emptyTitle="No assigned work matches these filters." /></div>;
}
