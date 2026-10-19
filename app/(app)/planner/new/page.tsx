import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { listCampaigns } from "@/lib/data/campaigns";
import { listApprovalCategories } from "@/lib/data/approval-categories";
import { ContentItemForm } from "@/components/content-item-form";
import { PageHeader } from "@/components/ui";

export default async function NewContentItemPage() {
  const [businessUnits, departments, campaigns, approvalCategories] = await Promise.all([
    listBusinessUnits(),
    listDepartments(),
    listCampaigns(),
    listApprovalCategories(),
  ]);

  return (
    <div>
      <PageHeader title="New Content Item" description="Add a new item to the planner." />
      <ContentItemForm
        businessUnits={businessUnits}
        departments={departments}
        campaigns={campaigns}
        approvalCategories={approvalCategories}
      />
    </div>
  );
}
