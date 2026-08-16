import { listKnowledgeItems } from "@/lib/data/knowledge-items";
import { PageHeader, EmptyState } from "@/components/ui";

export default async function KnowledgePage() {
  const items = await listKnowledgeItems();

  return (
    <div>
      <PageHeader title="Knowledge Base" description="Reusable reference material." />
      {items.length === 0 ? (
        <EmptyState title="No knowledge items yet — add your first one" />
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2">
          {items.map((item) => (
            <li key={item.id} className="rounded-lg border border-neutral-200 p-4">
              <p className="font-medium">{item.title}</p>
              <p className="mt-1 text-xs text-neutral-500">{item.category ?? "—"}</p>
              {item.body && (
                <p className="mt-2 line-clamp-3 text-sm text-neutral-600">{item.body}</p>
              )}
              {item.tags && item.tags.length > 0 && (
                <div className="mt-2 flex flex-wrap gap-1">
                  {item.tags.map((t) => (
                    <span
                      key={t}
                      className="rounded-full bg-neutral-100 px-2 py-0.5 text-xs text-neutral-600"
                    >
                      {t}
                    </span>
                  ))}
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
