import Link from "next/link";
import type { BusinessUnit, Department } from "@/lib/data/types";
import type { DashboardFilters, WorkAssignee } from "@/lib/work-management";
import { DASHBOARD_ATTENTION_FLAGS, WORK_STATUSES } from "@/lib/work-management";
import { humanise } from "@/components/work/work-ui";

const fieldClass = "mt-1 w-full rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm text-neutral-900";

export function DashboardFilterForm({
  values,
  businessUnits,
  departments,
  assignees,
  projects,
  resetHref,
}: {
  values: DashboardFilters;
  businessUnits: BusinessUnit[];
  departments: Department[];
  assignees: WorkAssignee[];
  projects: string[];
  resetHref: string;
}) {
  return <form method="get" className="mb-6 rounded-lg border border-neutral-200 bg-neutral-50 p-4">
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      <label className="text-xs font-medium text-neutral-600">Business unit<select name="businessUnit" defaultValue={values.businessUnit ?? ""} className={fieldClass}><option value="">All permitted</option>{businessUnits.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
      <label className="text-xs font-medium text-neutral-600">Department<select name="department" defaultValue={values.department ?? ""} className={fieldClass}><option value="">All permitted</option>{departments.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
      <label className="text-xs font-medium text-neutral-600">Staff / intern<select name="assignee" defaultValue={values.assignee ?? ""} className={fieldClass}><option value="">Everyone permitted</option>{assignees.map((item) => <option key={`${item.profile_id}-${item.department_id}`} value={item.profile_id}>{item.full_name}</option>)}</select></label>
      <label className="text-xs font-medium text-neutral-600">Project<select name="project" defaultValue={values.project ?? ""} className={fieldClass}><option value="">All projects</option>{projects.map((project) => <option key={project} value={project}>{project}</option>)}</select></label>
      <label className="text-xs font-medium text-neutral-600">Task status<select name="status" defaultValue={values.status ?? ""} className={fieldClass}><option value="">All statuses</option>{WORK_STATUSES.map((status) => <option key={status} value={status}>{humanise(status)}</option>)}</select></label>
      <label className="text-xs font-medium text-neutral-600">Attention flag<select name="attention" defaultValue={values.attention ?? ""} className={fieldClass}><option value="">All flags</option>{DASHBOARD_ATTENTION_FLAGS.map((flag) => <option key={flag} value={flag}>{humanise(flag.toLowerCase())}</option>)}</select></label>
      <label className="text-xs font-medium text-neutral-600">Date from<input type="date" name="dateFrom" defaultValue={values.dateFrom ?? ""} className={fieldClass} /></label>
      <label className="text-xs font-medium text-neutral-600">Date to<input type="date" name="dateTo" defaultValue={values.dateTo ?? ""} className={fieldClass} /></label>
    </div>
    <div className="mt-4 flex flex-wrap gap-2"><button type="submit" className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white">Apply filters</button><Link href={resetHref} className="rounded-md border border-neutral-300 bg-white px-4 py-2 text-sm">Reset</Link></div>
  </form>;
}
