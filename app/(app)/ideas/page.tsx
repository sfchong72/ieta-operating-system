import Link from "next/link";
import { listIdeas } from "@/lib/data/content-ideas";
import { PageHeader, EmptyState } from "@/components/ui";

const STATUS_STYLES: Record<string, string> = {
  idea: "bg-neutral-100 text-neutral-700",
  selected: "bg-blue-100 text-blue-700",
  tasked: "bg-amber-100 text-amber-800",
  archived: "bg-neutral-200 text-neutral-500",
};

export default async function IdeasPage() {
  const ideas = await listIdeas();

  return (
    <div>
      <PageHeader
        title="Content Ideas"
        description="The idea pipeline before it becomes a task."
        action={
          <Link
            href="/ideas/new"
            className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800"
          >
            New Idea
          </Link>
        }
      />
      {ideas.length === 0 ? (
        <EmptyState title="No content ideas yet — add your first idea" cta="New Idea" href="/ideas/new" />
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {ideas.map((idea) => (
            <li key={idea.id} className="rounded-lg border border-neutral-200 p-4">
              <Link href={`/ideas/${idea.id}`} className="font-medium hover:underline">
                {idea.title}
              </Link>
              <p className="mt-1 text-xs text-neutral-500">
                {idea.platform ?? "—"} · {idea.topic ?? "—"}
              </p>
              <span
                className={`mt-2 inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${
                  STATUS_STYLES[idea.status] ?? STATUS_STYLES.idea
                }`}
              >
                {idea.status}
              </span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
