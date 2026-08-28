import Link from "next/link";
import { listContentItems } from "@/lib/data/content-items";
import { PageHeader, EmptyState } from "@/components/ui";
import { WorkflowBadge, ApprovalBadge } from "@/components/planner/status-badges";
import { PlatformChips, PublishingProgress } from "@/components/planner/platform-progress";

export default async function PlannerPage() {
  const items = await listContentItems();

  return (
    <div>
      <PageHeader
        title="Social Media Planner"
        description="Every content item, its platforms, and where it stands."
      />

      {items.length === 0 ? (
        <EmptyState title="No content items yet — create your first one" />
      ) : (
        <div className="overflow-x-auto rounded-lg border border-neutral-200">
          <table className="w-full min-w-[980px] text-left text-sm">
            <thead className="bg-neutral-50 text-xs uppercase text-neutral-500">
              <tr>
                <th className="px-4 py-3 font-medium">Date</th>
                <th className="px-4 py-3 font-medium">Content</th>
                <th className="px-4 py-3 font-medium">Type</th>
                <th className="px-4 py-3 font-medium">Platforms</th>
                <th className="px-4 py-3 font-medium">PIC</th>
                <th className="px-4 py-3 font-medium">Workflow</th>
                <th className="px-4 py-3 font-medium">Approval</th>
                <th className="px-4 py-3 font-medium">Publishing Progress</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {items.map((item) => (
                <tr key={item.id} className="hover:bg-neutral-50">
                  <td className="whitespace-nowrap px-4 py-3 text-neutral-600">
                    {item.due_date ?? "—"}
                  </td>
                  <td className="px-4 py-3">
                    <Link href={`/planner/${item.id}`} className="font-medium hover:underline">
                      {item.title}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-neutral-600">{item.content_type ?? "—"}</td>
                  <td className="px-4 py-3">
                    <PlatformChips publications={item.platform_publications} />
                  </td>
                  <td className="px-4 py-3 text-neutral-600">{item.pic_name ?? "Unassigned"}</td>
                  <td className="px-4 py-3">
                    <WorkflowBadge status={item.status} />
                  </td>
                  <td className="px-4 py-3">
                    <ApprovalBadge status={item.approval_status} />
                  </td>
                  <td className="px-4 py-3">
                    <PublishingProgress publications={item.platform_publications} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
