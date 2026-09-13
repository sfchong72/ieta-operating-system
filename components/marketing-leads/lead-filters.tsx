"use client";

import { useState } from "react";
import type { BusinessUnit, Campaign } from "@/lib/data/types";
import type { LeadFilters, LeadSource } from "@/lib/marketing-leads";
import { LEAD_STATUSES, humaniseLead } from "@/lib/marketing-leads";
import type { WorkAssignee } from "@/lib/work-management";

const inputClass = "min-h-11 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 shadow-sm outline-none transition-colors placeholder:text-slate-400 focus:border-teal-500 focus:ring-2 focus:ring-teal-100";
export function LeadFiltersForm({ values, sources, assignees, businessUnits, campaigns, branches, programmes, basePath }: {
  values: LeadFilters; sources: LeadSource[]; assignees: WorkAssignee[]; businessUnits: BusinessUnit[];
  campaigns: Campaign[]; branches: string[]; programmes: string[]; basePath: string;
}) {
  const hasFilters = Object.values(values).some(Boolean);
  const [mobileOpen, setMobileOpen] = useState(hasFilters);
  return <div className="mb-5">
    <button type="button" aria-expanded={mobileOpen} aria-controls="lead-filters" onClick={() => setMobileOpen((open) => !open)} className="mb-3 flex min-h-11 w-full items-center justify-between rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition-colors hover:border-slate-300 sm:hidden">
      <span>{hasFilters ? "Filters applied" : "Search and filters"}</span><span aria-hidden="true" className="text-lg leading-none text-slate-400">{mobileOpen ? "−" : "+"}</span>
    </button>
    <form id="lead-filters" method="get" className={`${mobileOpen ? "block" : "hidden"} rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:block sm:p-5`}>
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      <input name="q" defaultValue={values.q} placeholder="Lead ID, name, phone or email" aria-label="Search leads" className={inputClass} />
      {assignees.length > 0 && <Select name="assignedTo" label="All assigned people" value={values.assignedTo} options={assignees.map((item) => [item.profile_id, item.full_name])} />}
      <Select name="businessUnit" label="All business units" value={values.businessUnit} options={businessUnits.map((item) => [item.id, item.name])} />
      <Select name="branch" label="All branches" value={values.branch} options={branches.map((item) => [item, item])} />
      <Select name="source" label="All sources" value={values.source} options={sources.map((item) => [item.slug, item.label])} />
      <Select name="campaign" label="All campaigns" value={values.campaign} options={campaigns.map((item) => [item.id, item.name])} />
      <Select name="status" label="All statuses" value={values.status} options={LEAD_STATUSES.map((item) => [item, humaniseLead(item)])} />
      <Select name="programme" label="All programmes" value={values.programme} options={programmes.map((item) => [item, item])} />
      <label className="text-xs font-medium text-slate-600">Follow-up from<input name="followUpFrom" type="date" defaultValue={values.followUpFrom} className={`mt-1 ${inputClass}`} /></label>
      <label className="text-xs font-medium text-slate-600">Follow-up to<input name="followUpTo" type="date" defaultValue={values.followUpTo} className={`mt-1 ${inputClass}`} /></label>
      <label className="text-xs font-medium text-slate-600">Received from<input name="receivedFrom" type="date" defaultValue={values.receivedFrom} className={`mt-1 ${inputClass}`} /></label>
      <label className="text-xs font-medium text-slate-600">Received to<input name="receivedTo" type="date" defaultValue={values.receivedTo} className={`mt-1 ${inputClass}`} /></label>
    </div>
    <div className="mt-4 flex flex-col gap-2 sm:flex-row"><button type="submit" className="min-h-11 rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-teal-700">Apply filters</button><a href={basePath} className="inline-flex min-h-11 items-center justify-center rounded-lg px-4 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-100">Reset filters</a></div>
    </form>
  </div>;
}
function Select({ name, label, value, options }: { name: string; label: string; value?: string; options: readonly (readonly [string, string])[] }) {
  return <select name={name} defaultValue={value ?? ""} aria-label={label} className={inputClass}><option value="">{label}</option>{options.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select>;
}
