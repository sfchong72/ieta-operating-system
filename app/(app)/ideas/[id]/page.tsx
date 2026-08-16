import Link from "next/link";
import { notFound } from "next/navigation";
import { getIdea } from "@/lib/data/content-ideas";
import { listTasksByIdea } from "@/lib/data/content-tasks";
import { StatusBadge } from "@/components/ui";
import { DeleteButton } from "@/components/delete-button";
import { deleteIdeaAction } from "@/lib/actions/ideas";

const STATUS_STYLES: Record<string, string> = {
  idea: "bg-neutral-100 text-neutral-700",
  selected: "bg-blue-100 text-blue-700",
  tasked: "bg-amber-100 text-amber-800",
  archived: "bg-neutral-200 text-neutral-500",
};

export default async function IdeaDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const idea = await getIdea(id);
  if (!idea) notFound();
  const tasks = await listTasksByIdea(id);

  const tags = idea.suggested_tags ? idea.suggested_tags.split(",").filter(Boolean) : [];

  return (
    <div className="max-w-2xl">
      <div className="flex items-start justify-between gap-4">
        <div>
          <Link href="/ideas" className="text-sm text-neutral-500 hover:underline">
            ← Content Ideas
          </Link>
          <h1 className="mt-1 text-2xl font-bold tracking-tight">{idea.title}</h1>
          <p className="mt-1 text-sm text-neutral-500">
            {idea.platform ?? "—"} · {idea.topic ?? "—"}
          </p>
          <span
            className={`mt-2 inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${
              STATUS_STYLES[idea.status] ?? STATUS_STYLES.idea
            }`}
          >
            {idea.status}
          </span>
        </div>
        <div className="flex shrink-0 gap-2">
          <Link
            href={`/ideas/${idea.id}/edit`}
            className="rounded-md border border-neutral-300 px-3 py-1.5 text-sm font-medium hover:bg-neutral-50"
          >
            Edit
          </Link>
          <DeleteButton action={deleteIdeaAction} fields={{ id: idea.id }} itemLabel="idea" />
        </div>
      </div>

      {tags.length > 0 && (
        <div className="mt-4">
          <p className="text-xs uppercase text-neutral-500">
            Suggested tags {idea.tags_confidence ? `(${Math.round(idea.tags_confidence * 100)}% confidence)` : ""}
          </p>
          <div className="mt-1 flex flex-wrap gap-1">
            {tags.map((t) => (
              <span key={t} className="rounded-full bg-neutral-100 px-2 py-0.5 text-xs text-neutral-600">
                {t}
              </span>
            ))}
          </div>
        </div>
      )}

      <div className="mt-6">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold">Linked tasks</h2>
          <Link
            href={`/tasks/new?idea_id=${idea.id}`}
            className="rounded-md bg-neutral-900 px-3 py-1.5 text-sm font-medium text-white hover:bg-neutral-800"
          >
            New task from this idea
          </Link>
        </div>
        {tasks.length === 0 ? (
          <p className="mt-2 text-sm text-neutral-500">No tasks created from this idea yet.</p>
        ) : (
          <ul className="mt-2 space-y-2">
            {tasks.map((t) => (
              <li
                key={t.id}
                className="flex items-center justify-between rounded-md border border-neutral-200 p-3 text-sm"
              >
                <Link href={`/tasks/${t.id}`} className="hover:underline">
                  {t.title}
                </Link>
                <StatusBadge status={t.status} />
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
