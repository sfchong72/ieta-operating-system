import Link from "next/link";
import { notFound } from "next/navigation";
import { getContentItem } from "@/lib/data/content-items";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { listCampaigns } from "@/lib/data/campaigns";
import { listApprovalCategories } from "@/lib/data/approval-categories";
import { ContentItemForm } from "@/components/content-item-form";
import { PageHeader } from "@/components/ui";

export default async function EditContentItemPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [item, businessUnits, departments, campaigns, approvalCategories] = await Promise.all([
    getContentItem(id),
    listBusinessUnits(),
    listDepartments(),
    listCampaigns(),
    listApprovalCategories(),
  ]);
  if (!item) notFound();

  return (
    <div>
      <Link href={`/planner/${item.id}`} className="text-sm text-neutral-500 hover:underline">
        ← Back to content item
      </Link>
      <PageHeader title="Edit Content Item" description="Update details for this content item." />
      <ContentItemForm
        businessUnits={businessUnits}
        departments={departments}
        campaigns={campaigns}
        approvalCategories={approvalCategories}
        item={item}
      />
    </div>
  );
}
