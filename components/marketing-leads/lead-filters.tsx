import type { BusinessUnit, Campaign } from "@/lib/data/types";
import type { LeadFilters, LeadSource } from "@/lib/marketing-leads";
import { LEAD_STATUSES, humaniseLead } from "@/lib/marketing-leads";
import type { WorkAssignee } from "@/lib/work-management";

const inputClass = "rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm";
export function LeadFiltersForm({ values, sources, assignees, businessUnits, campaigns, branches, programmes, basePath }: {
  values: LeadFilters; sources: LeadSource[]; assignees: WorkAssignee[]; businessUnits: BusinessUnit[];
  campaigns: Campaign[]; branches: string[]; programmes: string[]; basePath: string;
}) {
  return <form method="get" className="mb-5 rounded-lg border border-neutral-200 bg-neutral-50 p-4">
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <input name="q" defaultValue={values.q} placeholder="Lead ID, name, phone or email" aria-label="Search leads" className={`${inputClass} lg:col-span-2`} />
      {assignees.length > 0 && <Select name="assignedTo" label="All assigned people" value={values.assignedTo} options={assignees.map((item) => [item.profile_id, item.full_name])} />}
      <Select name="businessUnit" label="All business units" value={values.businessUnit} options={businessUnits.map((item) => [item.id, item.name])} />
      <Select name="branch" label="All branches" value={values.branch} options={branches.map((item) => [item, item])} />
      <Select name="source" label="All sources" value={values.source} options={sources.map((item) => [item.slug, item.label])} />
      <Select name="campaign" label="All campaigns" value={values.campaign} options={campaigns.map((item) => [item.id, item.name])} />
      <Select name="status" label="All statuses" value={values.status} options={LEAD_STATUSES.map((item) => [item, humaniseLead(item)])} />
      <Select name="programme" label="All programmes" value={values.programme} options={programmes.map((item) => [item, item])} />
      <label className="text-xs text-neutral-600">Follow-up from<input name="followUpFrom" type="date" defaultValue={values.followUpFrom} className={`mt-1 w-full ${inputClass}`} /></label>
      <label className="text-xs text-neutral-600">Follow-up to<input name="followUpTo" type="date" defaultValue={values.followUpTo} className={`mt-1 w-full ${inputClass}`} /></label>
      <label className="text-xs text-neutral-600">Received from<input name="receivedFrom" type="date" defaultValue={values.receivedFrom} className={`mt-1 w-full ${inputClass}`} /></label>
      <label className="text-xs text-neutral-600">Received to<input name="receivedTo" type="date" defaultValue={values.receivedTo} className={`mt-1 w-full ${inputClass}`} /></label>
    </div>
    <div className="mt-3 flex gap-3"><button type="submit" className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white">Apply filters</button><a href={basePath} className="py-2 text-sm underline">Reset</a></div>
  </form>;
}
function Select({ name, label, value, options }: { name: string; label: string; value?: string; options: readonly (readonly [string, string])[] }) {
  return <select name={name} defaultValue={value ?? ""} aria-label={label} className={inputClass}><option value="">{label}</option>{options.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select>;
}

