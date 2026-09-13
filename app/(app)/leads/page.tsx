import Link from "next/link";
import { redirect } from "next/navigation";
import { LeadFiltersForm } from "@/components/marketing-leads/lead-filters";
import { LeadList } from "@/components/marketing-leads/lead-list";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listCampaigns } from "@/lib/data/campaigns";
import { listLeadBranches, listLeadProgrammes, listLeadSources, searchMarketingLeads } from "@/lib/data/marketing-leads";
import { listWorkAssignees } from "@/lib/data/work-management";
import type { LeadFilters } from "@/lib/marketing-leads";
function first(value: string | string[] | undefined) { return Array.isArray(value) ? value[0] : value; }
export default async function LeadRegisterPage({ searchParams }: { searchParams: Promise<Record<string,string|string[]|undefined>> }) {
  const [user, params] = await Promise.all([getCurrentUser(), searchParams]); if (!user?.canAccessMarketingLeads) redirect("/work");
  const canManage = ["super_admin","management"].includes(user.role ?? "");
  const filters: LeadFilters = { q:first(params.q),assignedTo:first(params.assignedTo),businessUnit:first(params.businessUnit),branch:first(params.branch),source:first(params.source),campaign:first(params.campaign),status:first(params.status),programme:first(params.programme),followUpFrom:first(params.followUpFrom),followUpTo:first(params.followUpTo),receivedFrom:first(params.receivedFrom),receivedTo:first(params.receivedTo) };
  const [leads,sources,businessUnits,campaigns,assignees,branches,programmes] = await Promise.all([searchMarketingLeads(filters),listLeadSources(),listBusinessUnits(),listCampaigns(),canManage?listWorkAssignees():Promise.resolve([]),listLeadBranches(),listLeadProgrammes()]);
  return <div className="mx-auto max-w-[1500px]"><PageHeader title="Lead Register" description="Search, assign and follow up permitted marketing leads from one restricted workspace." action={<>{canManage&&<Link href="/leads/summary" className="inline-flex min-h-11 flex-1 items-center justify-center rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition-colors hover:border-slate-400 hover:bg-slate-50 sm:flex-none">Manager summary</Link>}{canManage&&<Link href="/leads/new" className="inline-flex min-h-11 flex-1 items-center justify-center rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-teal-700 sm:flex-none">Add lead</Link>}</>} />
    <div className="mb-5 flex gap-3 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm leading-6 text-amber-950"><span aria-hidden="true" className="font-bold">!</span><p><strong>Restricted marketing data.</strong> Keep names, contact details and private source links out of generic tasks.</p></div>
    <LeadFiltersForm values={filters} sources={sources} assignees={assignees} businessUnits={businessUnits} campaigns={campaigns} branches={branches} programmes={programmes} basePath="/leads" />
    <p className="mb-3 text-sm font-medium text-slate-500">Showing {leads.length} permitted lead{leads.length===1?"":"s"}</p><LeadList leads={leads} emptyText="No permitted leads match these filters. Try adjusting your search or filters." /></div>;
}
