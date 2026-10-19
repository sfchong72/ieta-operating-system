import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import { listApprovalQueue } from "@/lib/data/approval-actions";
import { listApprovalCategories } from "@/lib/data/approval-categories";
import { PageHeader, EmptyState } from "@/components/ui";
import { PlatformChips } from "@/components/planner/platform-progress";
import { ApprovalQueueForms } from "@/components/approvals/approval-forms";

export default async function ApprovalsPage() {
  const currentUser = await getCurrentUser();
  if (
    !currentUser ||
    (currentUser.role !== "super_admin" && currentUser.role !== "management")
  ) {
    redirect("/dashboard");
  }

  const [items, categories] = await Promise.all([
    listApprovalQueue(currentUser.role as "super_admin" | "management"),
    listApprovalCategories(),
  ]);
  const categoryById = new Map(categories.map((c) => [c.id, c.name]));

  return (
    <div>
      <PageHeader
        title="My Approvals"
        description={
          currentUser.role === "super_admin"
            ? "Escalated content awaiting your approval (major campaigns, pricing, sensitive content, etc.)"
            : "Routine content awaiting your approval."
        }
      />

      {items.length === 0 ? (
        <EmptyState title="Nothing waiting on your review right now." />
      ) : (
        <ul className="space-y-4">
          {items.map((item) => (
            <li key={item.id} className="rounded-lg border border-neutral-200 p-4">
              <div className="flex flex-wrap items-start justify-between gap-2">
                <div>
                  <Link href={`/planner/${item.id}`} className="font-medium hover:underline">
                    {item.title}
                  </Link>
                  <p className="mt-1 text-xs text-neutral-500">
                    PIC: {item.pic_name ?? "Unassigned"} · Due: {item.due_date ?? "—"}
                    {item.approval_category_id && (
                      <> · {categoryById.get(item.approval_category_id) ?? "Escalated"}</>
                    )}
                  </p>
                </div>
                <PlatformChips publications={item.platform_publications} />
              </div>
              <ApprovalQueueForms contentItemId={item.id} />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
