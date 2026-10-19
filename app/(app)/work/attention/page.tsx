import { redirect } from "next/navigation";
import { AttentionList } from "@/components/manager-dashboard/attention-list";
import { DashboardFilterForm } from "@/components/manager-dashboard/dashboard-filters";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { listWorkAssignees } from "@/lib/data/work-management";
import { listDashboardAttention, listDashboardProjects } from "@/lib/data/work-dashboard";
import type { DashboardFilters } from "@/lib/work-management";

function first(value: string | string[] | undefined) { return Array.isArray(value) ? value[0] : value; }

export default async function NeedsAttentionPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const [user, params] = await Promise.all([getCurrentUser(), searchParams]);
  if (!user?.canViewWorkDashboard) redirect("/work");
  const filters: DashboardFilters = { businessUnit: first(params.businessUnit), department: first(params.department), assignee: first(params.assignee), project: first(params.project), status: first(params.status), attention: first(params.attention), dateFrom: first(params.dateFrom), dateTo: first(params.dateTo) };
  const [attention, businessUnits, departments, assignees, projects] = await Promise.all([listDashboardAttention(filters), listBusinessUnits(), listDepartments(), listWorkAssignees(), listDashboardProjects()]);
  const uniqueAssignees = Array.from(new Map(assignees.map((person) => [person.profile_id, person])).values());
  const names = new Map(uniqueAssignees.map((person) => [person.profile_id, person.full_name]));
  names.set(user.profile.id, user.profile.full_name ?? user.profile.email);
  return <div className="mx-auto max-w-[1500px]"><PageHeader title="Needs Attention" description="Overdue, stuck, evidence, blocker, feedback, missing-update and supervisor-review exceptions." /><DashboardFilterForm values={filters} businessUnits={businessUnits} departments={departments} assignees={uniqueAssignees} projects={projects} resetHref="/work/attention" /><AttentionList tasks={attention} assigneeNames={names} departmentNames={new Map(departments.map((item) => [item.id, item.name]))} /></div>;
}
