import type { BusinessUnit, Department } from "@/lib/data/types";
import type { WorkAssignee } from "@/lib/work-management";
import type { MasterFileCategory, MasterFileFilters } from "@/lib/master-files";
import { MASTER_FILE_ACCESS_LEVELS, MASTER_FILE_STATUSES, humaniseMasterFile } from "@/lib/master-files";

const inputClass = "rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm";

export function MasterFileFiltersForm({
  values,
  businessUnits,
  departments,
  categories,
  owners,
  projects,
  reviewMode = false,
}: {
  values: MasterFileFilters;
  businessUnits: BusinessUnit[];
  departments: Department[];
  categories: MasterFileCategory[];
  owners: WorkAssignee[];
  projects: string[];
  reviewMode?: boolean;
}) {
  return <form method="get" className="mb-5 rounded-lg border border-neutral-200 bg-neutral-50 p-4">
    {reviewMode && <input type="hidden" name="review" value="1" />}
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <input name="q" defaultValue={values.q} placeholder="File name, ID or keyword" aria-label="Search files" className={`${inputClass} lg:col-span-2`} />
      <Select name="businessUnit" label="All business units" value={values.businessUnit} options={businessUnits.map((item) => [item.id, item.name])} />
      <Select name="department" label="All departments" value={values.department} options={departments.map((item) => [item.id, item.name])} />
      <Select name="category" label="All categories" value={values.category} options={categories.map((item) => [item.slug, item.label])} />
      <Select name="owner" label="All owners" value={values.owner} options={owners.map((item) => [item.profile_id, item.full_name])} />
      <Select name="project" label="All projects" value={values.project} options={projects.map((item) => [item, item])} />
      <Select name="status" label="All statuses" value={values.status} options={MASTER_FILE_STATUSES.map((item) => [item, humaniseMasterFile(item)])} />
      <Select name="access" label="All access levels" value={values.access} options={MASTER_FILE_ACCESS_LEVELS.map((item) => [item, item === "pc_restricted" ? "P&C Restricted" : humaniseMasterFile(item)])} />
    </div>
    <div className="mt-3 flex flex-wrap items-center gap-3">
      {!reviewMode && <label className="flex items-center gap-2 text-sm text-neutral-700"><input type="checkbox" name="history" value="1" defaultChecked={values.includeHistory} /> Include superseded and archived</label>}
      <button type="submit" className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white">Apply filters</button>
      <a href={reviewMode ? "/files/review" : "/files"} className="text-sm text-neutral-600 underline">Reset</a>
    </div>
  </form>;
}

function Select({ name, label, value, options }: { name: string; label: string; value?: string; options: readonly (readonly [string, string])[] }) {
  return <select name={name} defaultValue={value ?? ""} aria-label={label} className={inputClass}><option value="">{label}</option>{options.map(([optionValue, optionLabel]) => <option key={optionValue} value={optionValue}>{optionLabel}</option>)}</select>;
}

