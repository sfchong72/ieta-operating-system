import { notFound, redirect } from "next/navigation";
import { LeadForm } from "@/components/marketing-leads/lead-form";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listCampaigns } from "@/lib/data/campaigns";
import { listDepartments } from "@/lib/data/departments";
import { getMarketingLeadDetail, listLeadSources } from "@/lib/data/marketing-leads";
import { listWorkAssignees } from "@/lib/data/work-management";
export default async function EditLeadPage({params}:{params:Promise<{id:string}>}){const [{id},user]=await Promise.all([params,getCurrentUser()]);if(!user?.canAccessMarketingLeads)redirect("/work");const detail=await getMarketingLeadDetail(id);if(!detail)notFound();if(!detail.canManage)redirect(`/leads/${id}`);const [sources,businessUnits,departments,campaigns,assignees]=await Promise.all([listLeadSources(),listBusinessUnits(),listDepartments(),listCampaigns(),listWorkAssignees()]);return <div className="mx-auto max-w-5xl"><PageHeader title={`Edit ${detail.lead.lead_number}`} description="Important assignment, status and sensitive-data changes are audited."/><LeadForm lead={detail.lead} sources={sources} businessUnits={businessUnits} departments={departments} campaigns={campaigns} assignees={assignees}/></div>}

