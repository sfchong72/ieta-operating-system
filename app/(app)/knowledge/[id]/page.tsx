import Link from "next/link";
import { notFound } from "next/navigation";
import { getKnowledgeItem } from "@/lib/data/knowledge-items";
import { DeleteButton } from "@/components/delete-button";
import { deleteKnowledgeItemAction } from "@/lib/actions/knowledge";

export default async function KnowledgeItemPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const item = await getKnowledgeItem(id);
  if (!item) notFound();

  return (
    <div className="max-w-2xl">
      <div className="flex items-start justify-between gap-4">
        <div>
          <Link href="/knowledge" className="text-sm text-neutral-500 hover:underline">
            ← Knowledge Base
          </Link>
          <h1 className="mt-1 text-2xl font-bold tracking-tight">{item.title}</h1>
          <p className="mt-1 text-sm text-neutral-500">{item.category ?? "—"}</p>
        </div>
        <div className="flex shrink-0 gap-2">
          <Link
            href={`/knowledge/${item.id}/edit`}
            className="rounded-md border border-neutral-300 px-3 py-1.5 text-sm font-medium hover:bg-neutral-50"
          >
            Edit
          </Link>
          <DeleteButton
            action={deleteKnowledgeItemAction}
            fields={{ id: item.id }}
            itemLabel="knowledge item"
          />
        </div>
      </div>

      {item.body && (
        <div className="mt-6 whitespace-pre-wrap rounded-lg border border-neutral-200 p-4 text-sm">
          {item.body}
        </div>
      )}

      {item.tags && item.tags.length > 0 && (
        <div className="mt-4 flex flex-wrap gap-1">
          {item.tags.map((t) => (
            <span key={t} className="rounded-full bg-neutral-100 px-2 py-0.5 text-xs text-neutral-600">
              {t}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
