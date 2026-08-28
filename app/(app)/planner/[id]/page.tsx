import Link from "next/link";
import { notFound } from "next/navigation";
import { getContentItem } from "@/lib/data/content-items";
import { WorkflowBadge, ApprovalBadge } from "@/components/planner/status-badges";
import { PlatformChips, PublishingProgress } from "@/components/planner/platform-progress";

export default async function ContentItemDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const item = await getContentItem(id);
  if (!item) notFound();

  return (
    <div className="max-w-2xl">
      <Link href="/planner" className="text-sm text-neutral-500 hover:underline">
        ← Planner
      </Link>
      <h1 className="mt-1 text-2xl font-bold tracking-tight">{item.title}</h1>
      <div className="mt-2 flex flex-wrap items-center gap-2">
        <WorkflowBadge status={item.status} />
        <ApprovalBadge status={item.approval_status} />
      </div>

      <dl className="mt-6 grid grid-cols-2 gap-4 rounded-lg border border-neutral-200 p-4 text-sm sm:grid-cols-3">
        <div>
          <dt className="text-xs uppercase text-neutral-500">PIC</dt>
          <dd className="mt-0.5 font-medium">{item.pic_name ?? "Unassigned"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Type</dt>
          <dd className="mt-0.5 font-medium">{item.content_type ?? "—"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Due date</dt>
          <dd className="mt-0.5 font-medium">{item.due_date ?? "—"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Language</dt>
          <dd className="mt-0.5 font-medium">{item.language ?? "—"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Priority</dt>
          <dd className="mt-0.5 font-medium">{item.priority ?? "—"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Publishing progress</dt>
          <dd className="mt-0.5">
            <PublishingProgress publications={item.platform_publications} />
          </dd>
        </div>
      </dl>

      {(item.on_screen_wording || item.main_caption || item.cta) && (
        <div className="mt-6 space-y-3 rounded-lg border border-neutral-200 p-4 text-sm">
          <h2 className="text-sm font-semibold">Creative content</h2>
          {item.on_screen_wording && (
            <p><span className="text-xs uppercase text-neutral-500">On-screen wording: </span>{item.on_screen_wording}</p>
          )}
          {item.main_caption && (
            <p><span className="text-xs uppercase text-neutral-500">Caption: </span>{item.main_caption}</p>
          )}
          {item.cta && <p><span className="text-xs uppercase text-neutral-500">CTA: </span>{item.cta}</p>}
        </div>
      )}

      <div className="mt-6">
        <h2 className="text-sm font-semibold">Platforms</h2>
        <div className="mt-2">
          <PlatformChips publications={item.platform_publications} />
        </div>
        <ul className="mt-3 space-y-2">
          {item.platform_publications.map((p) => (
            <li key={p.id} className="rounded-md border border-neutral-200 p-3 text-sm">
              <span className="font-medium capitalize">{p.platform.replace("_", " ")}</span>{" "}
              <span className="text-neutral-500">— {p.status.replace("_", " ")}</span>
              {p.published_url && (
                <div className="mt-1">
                  <a
                    href={p.published_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-xs hover:underline"
                  >
                    {p.published_url}
                  </a>
                  {p.published_at && (
                    <span className="ml-2 text-xs text-neutral-400">
                      {new Date(p.published_at).toLocaleDateString()}
                    </span>
                  )}
                </div>
              )}
            </li>
          ))}
        </ul>
      </div>

      {item.remarks && (
        <div className="mt-6 rounded-lg border border-neutral-200 p-4 text-sm">
          <h2 className="text-sm font-semibold">Remarks</h2>
          <p className="mt-1 text-neutral-600">{item.remarks}</p>
        </div>
      )}
    </div>
  );
}
