import Link from "next/link";
import { redirect } from "next/navigation";
import { AttentionList } from "@/components/manager-dashboard/attention-list";
import { DailyOutputReview } from "@/components/manager-dashboard/daily-output-review";
import { DashboardFilterForm } from "@/components/manager-dashboard/dashboard-filters";
import { WorkloadTable } from "@/components/manager-dashboard/workload-table";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { listWorkAssignees } from "@/lib/data/work-management";
import {
  listDashboardAttention,
  listDashboardDailyUpdates,
  listDashboardMissingUpdates,
  listDashboardProjects,
  listDashboardWorkload,
} from "@/lib/data/work-dashboard";
import type { DashboardFilters, DashboardWorkload } from "@/lib/work-management";

function first(value: string | string[] | undefined) { return Array.isArray(value) ? value[0] : value; }
function filtersFrom(params: Record<string, string | string[] | undefined>): DashboardFilters {
  return {
    businessUnit: first(params.businessUnit), department: first(params.department),
    assignee: first(params.assignee), project: first(params.project), status: first(params.status),
    attention: first(params.attention), dateFrom: first(params.dateFrom), dateTo: first(params.dateTo),
  };
}

function StatCard({ label, value, tone = "neutral" }: { label: string; value: number; tone?: "neutral" | "red" | "amber" }) {
  const colour = tone === "red" ? "text-red-700" : tone === "amber" ? "text-amber-700" : "text-neutral-950";
  return <div className="rounded-lg border border-neutral-200 bg-white p-4"><p className="text-xs font-medium uppercase text-neutral-500">{label}</p><p className={`mt-1 text-2xl font-bold ${colour}`}>{value}</p></div>;
}

export default async function DashboardPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const [user, rawParams] = await Promise.all([getCurrentUser(), searchParams]);
  if (!user?.canViewWorkDashboard) redirect("/work");
  const filters = filtersFrom(rawParams);
  const [attention, workloadRows, updates, missing, businessUnits, departments, assignees, projects] = await Promise.all([
    listDashboardAttention(filters), listDashboardWorkload(filters), listDashboardDailyUpdates(filters),
    listDashboardMissingUpdates(filters), listBusinessUnits(), listDepartments(), listWorkAssignees(), listDashboardProjects(),
  ]);
  const scopedAssignees = assignees.filter((person) => {
    const department = departments.find((item) => item.id === person.department_id);
    return (!filters.department || person.department_id === filters.department)
      && (!filters.businessUnit || department?.business_unit_id === filters.businessUnit);
  });
  const uniqueAssignees = Array.from(new Map(scopedAssignees.map((person) => [person.profile_id, person])).values());
  const assigneeNames = new Map(uniqueAssignees.map((person) => [person.profile_id, person.full_name]));
  assigneeNames.set(user.profile.id, user.profile.full_name ?? user.profile.email);
  const departmentNames = new Map(departments.map((department) => [department.id, department.name]));
  const workloadByPerson = new Map(workloadRows.map((row) => [row.assigned_to, row]));
  const eligiblePeople = uniqueAssignees.filter((person) => !filters.assignee || person.profile_id === filters.assignee);
  const workload: DashboardWorkload[] = eligiblePeople.map((person) => workloadByPerson.get(person.profile_id) ?? {
    assigned_to: person.profile_id, active_tasks: 0, overdue_tasks: 0, stuck_tasks: 0,
    waiting_feedback: 0, completed_this_week: 0, updates_this_week: 0, workload_signal: "light_active_load",
  });
  const countFlag = (flag: string) => attention.filter((task) => task.attention_flags.includes(flag)).length;

  return <div className="mx-auto max-w-[1500px]">
    <PageHeader title="Manager Dashboard" description="A 5–10 minute exception-based review of workload, outputs and tasks needing action." action={<Link href="/work/attention" className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white">Open Needs Attention</Link>} />
    <DashboardFilterForm values={filters} businessUnits={businessUnits} departments={departments} assignees={uniqueAssignees} projects={projects} resetHref="/dashboard" />
    <section aria-labelledby="dashboard-summary"><h2 id="dashboard-summary" className="sr-only">Dashboard summary</h2><div className="grid grid-cols-2 gap-3 md:grid-cols-4 xl:grid-cols-8"><StatCard label="Needs attention" value={attention.length} tone="red" /><StatCard label="Overdue" value={countFlag("OVERDUE")} tone="red" /><StatCard label="Stuck" value={countFlag("STUCK")} tone="amber" /><StatCard label="Updates shown" value={updates.length} /><StatCard label="Deliverables done" value={updates.filter((item) => item.deliverable_completed).length} /><StatCard label="Blockers raised" value={updates.filter((item) => Boolean(item.blocker_or_help)).length} tone="red" /><StatCard label="Missing today" value={missing.length} tone="amber" /><StatCard label="Awaiting review" value={updates.filter((item) => item.awaiting_supervisor_review).length} tone="amber" /></div></section>
    <section className="mt-8"><div className="mb-3 flex items-end justify-between gap-4"><div><h2 className="text-lg font-semibold">Needs Attention</h2><p className="text-sm text-neutral-500">Highest-priority exceptions first, using the canonical task rules.</p></div><Link href="/work/attention" className="text-sm font-medium underline">View all</Link></div><AttentionList tasks={attention} assigneeNames={assigneeNames} departmentNames={departmentNames} limit={10} /></section>
    <section className="mt-8"><h2 className="text-lg font-semibold">Team Workload</h2><p className="mb-3 text-sm text-neutral-500">Workload visibility only. Signals describe active task volume and are not productivity scores.</p><WorkloadTable rows={workload} assigneeNames={assigneeNames} /></section>
    <section className="mt-8"><h2 className="text-lg font-semibold">Daily Output Review</h2><p className="mb-3 text-sm text-neutral-500">Today by default, or the selected date range. Open an update to review it without changing the original submission.</p><DailyOutputReview updates={updates} missing={missing} assigneeNames={assigneeNames} /></section>
  </div>;
}
