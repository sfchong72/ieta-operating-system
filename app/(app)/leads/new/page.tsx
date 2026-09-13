import { redirect } from "next/navigation";
import { LeadForm } from "@/components/marketing-leads/lead-form";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listCampaigns } from "@/lib/data/campaigns";
import { listDepartments } from "@/lib/data/departments";
import { listLeadSources } from "@/lib/data/marketing-leads";
import { listWorkAssignees } from "@/lib/data/work-management";
export default async function NewLeadPage(){const user=await getCurrentUser();if(!user?.canAccessMarketingLeads||!["super_admin","management"].includes(user.role??""))redirect("/leads/my");const [sources,businessUnits,departments,campaigns,assignees]=await Promise.all([listLeadSources(),listBusinessUnits(),listDepartments(),listCampaigns(),listWorkAssignees()]);return <div className="mx-auto max-w-5xl"><PageHeader title="Add Lead" description="Create one restricted active-follow-up record. Historical bulk import is not part of Stage 5."/><LeadForm sources={sources} businessUnits={businessUnits} departments={departments} campaigns={campaigns} assignees={assignees}/></div>}

