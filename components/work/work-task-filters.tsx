import Link from "next/link";
import { WORK_STATUSES } from "@/lib/work-management";
import type { Department } from "@/lib/data/types";
import { humanise } from "./work-ui";

export type WorkFilterValues = { q?: string; status?: string; department?: string };

export function WorkTaskFilters({ values, departments, resetHref }: { values: WorkFilterValues; departments?: Department[]; resetHref: string }) {
  return <form method="get" className="mb-4 grid gap-3 rounded-lg border border-neutral-200 bg-neutral-50 p-3 sm:grid-cols-[minmax(12rem,1fr)_auto_auto_auto]">
    <label className="text-xs font-medium text-neutral-600">Search<input type="search" name="q" defaultValue={values.q ?? ""} placeholder="Task, project or number" className="mt-1 w-full rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm text-neutral-900" /></label>
    <label className="text-xs font-medium text-neutral-600">Status<select name="status" defaultValue={values.status ?? ""} className="mt-1 w-full rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm text-neutral-900"><option value="">All</option>{WORK_STATUSES.map((status) => <option key={status} value={status}>{humanise(status)}</option>)}</select></label>
    {departments && <label className="text-xs font-medium text-neutral-600">Department<select name="department" defaultValue={values.department ?? ""} className="mt-1 w-full rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm text-neutral-900"><option value="">All</option>{departments.map((department) => <option key={department.id} value={department.id}>{department.name}</option>)}</select></label>}
    <div className="flex items-end gap-2"><button type="submit" className="rounded-md bg-neutral-900 px-3 py-2 text-sm font-medium text-white">Filter</button><Link href={resetHref} className="rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm">Reset</Link></div>
  </form>;
}
