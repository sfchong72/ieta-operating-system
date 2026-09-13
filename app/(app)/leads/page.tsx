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
  return <div className="mx-auto max-w-[1500px]"><PageHeader title="Lead Register" description="Restricted active follow-up register. Contact details are visible only to authorised personnel." action={<div className="flex gap-2">{canManage&&<Link href="/leads/summary" className="rounded-md border px-3 py-2 text-sm font-medium">Manager summary</Link>}{canManage&&<Link href="/leads/new" className="rounded-md bg-neutral-900 px-3 py-2 text-sm font-medium text-white">Add lead</Link>}</div>} />
    <div className="mb-4 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-900">Restricted marketing data. Do not copy names, phone numbers, emails or private source links into generic tasks.</div>
    <LeadFiltersForm values={filters} sources={sources} assignees={assignees} businessUnits={businessUnits} campaigns={campaigns} branches={branches} programmes={programmes} basePath="/leads" />
    <p className="mb-3 text-sm text-neutral-500">{leads.length} permitted lead{leads.length===1?"":"s"}.</p><LeadList leads={leads} emptyText="No permitted leads match these filters." /></div>;
}

