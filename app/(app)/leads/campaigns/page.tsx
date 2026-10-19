import { redirect } from "next/navigation";
import { CampaignManager } from "@/components/marketing-leads/campaign-manager";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listCampaigns } from "@/lib/data/campaigns";
import { listDepartments } from "@/lib/data/departments";

export default async function LeadCampaignsPage() {
  const user = await getCurrentUser();
  if (!user?.canAccessMarketingLeads || !["super_admin", "management"].includes(user.role ?? "")) redirect("/leads/my");
  const [businessUnits, departments, campaigns] = await Promise.all([listBusinessUnits(), listDepartments(), listCampaigns()]);
  return <div className="mx-auto max-w-6xl">
    <PageHeader title="Lead Campaigns" description="Maintain the controlled campaign choices used by the restricted Marketing Lead Register." />
    <CampaignManager businessUnits={businessUnits} departments={departments} campaigns={campaigns} />
  </div>;
}
