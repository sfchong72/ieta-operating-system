import Link from "next/link";
import { listTasks } from "@/lib/data/content-tasks";
import { listIdeas } from "@/lib/data/content-ideas";
import { PageHeader, StatusBadge } from "@/components/ui";

function StatCard({ label, value, href }: { label: string; value: number; href?: string }) {
  const inner = (
    <div className="rounded-lg border border-neutral-200 p-4">
      <p className="text-xs uppercase text-neutral-500">{label}</p>
      <p className="mt-1 text-2xl font-bold">{value}</p>
    </div>
  );
  return href ? <Link href={href}>{inner}</Link> : inner;
}

export default async function DashboardPage() {
  const [tasks, ideas] = await Promise.all([listTasks(), listIdeas()]);

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const delayed = tasks.filter(
    (t) => t.deadline && new Date(t.deadline) < today && t.status !== "posted",
  );
  const pendingApproval = tasks.filter((t) => t.status === "submitted");
  const posted = tasks.filter((t) => t.status === "posted");
  const inProgress = tasks.filter((t) => t.status === "in_progress");

  const byPic = new Map<string, number>();
  for (const t of tasks) {
    if (t.status === "posted") continue;
    byPic.set(t.pic_name, (byPic.get(t.pic_name) ?? 0) + 1);
  }

  const attentionNeeded = tasks
    .filter((t) => t.status !== "posted")
    .sort((a, b) => (b.priority_score ?? 0) - (a.priority_score ?? 0))
    .slice(0, 5);

  return (
    <div>
      <PageHeader
        title="Dashboard"
        description="Who's doing what, what's delayed, what needs approval."
      />

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        <StatCard label="Ideas" value={ideas.length} href="/ideas" />
        <StatCard label="In progress" value={inProgress.length} href="/tasks" />
        <StatCard label="Pending approval" value={pendingApproval.length} href="/tasks" />
        <StatCard label="Posted" value={posted.length} href="/tasks" />
        <StatCard label="Delayed" value={delayed.length} href="/tasks" />
      </div>

      <div className="mt-8">
        <h2 className="text-sm font-semibold">Attention Needed</h2>
        <p className="text-xs text-neutral-500">
          Ranked by priority score (deadline pressure, awaiting approval, missing work link).
        </p>
        {attentionNeeded.length === 0 ? (
          <p className="mt-2 text-sm text-neutral-500">Nothing urgent right now.</p>
        ) : (
          <ul className="mt-2 space-y-2">
            {attentionNeeded.map((t) => (
              <li
                key={t.id}
                className="flex items-center justify-between gap-3 rounded-md border border-neutral-200 p-3 text-sm"
              >
                <div className="min-w-0">
                  <Link href={`/tasks/${t.id}`} className="font-medium hover:underline">
                    {t.title}
                  </Link>
                  <p className="truncate text-xs text-neutral-500">{t.pic_name}</p>
                </div>
                <div className="flex shrink-0 items-center gap-2">
                  {(t.priority_score ?? 0) >= 0.7 && (
                    <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
                      urgent
                    </span>
                  )}
                  <StatusBadge status={t.status} />
                  <span className="text-xs text-neutral-400">
                    {((t.priority_score ?? 0) * 100).toFixed(0)}%
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="mt-8 grid gap-6 lg:grid-cols-2">
        <div>
          <h2 className="text-sm font-semibold">Pending Approval</h2>
          {pendingApproval.length === 0 ? (
            <p className="mt-2 text-sm text-neutral-500">Nothing waiting on review.</p>
          ) : (
            <ul className="mt-2 space-y-2">
              {pendingApproval.map((t) => (
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

        <div>
          <h2 className="text-sm font-semibold">Delayed tasks</h2>
          {delayed.length === 0 ? (
            <p className="mt-2 text-sm text-neutral-500">Nothing overdue.</p>
          ) : (
            <ul className="mt-2 space-y-2">
              {delayed.map((t) => (
                <li
                  key={t.id}
                  className="flex items-center justify-between rounded-md border border-red-200 bg-red-50/40 p-3 text-sm"
                >
                  <Link href={`/tasks/${t.id}`} className="hover:underline">
                    {t.title}
                  </Link>
                  <span className="text-xs text-red-600">due {t.deadline}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      <div className="mt-8">
        <h2 className="text-sm font-semibold">Who&apos;s doing what</h2>
        {byPic.size === 0 ? (
          <p className="mt-2 text-sm text-neutral-500">No active tasks assigned.</p>
        ) : (
          <ul className="mt-2 grid gap-2 sm:grid-cols-3">
            {Array.from(byPic.entries()).map(([pic, count]) => (
              <li
                key={pic}
                className="flex items-center justify-between rounded-md border border-neutral-200 p-3 text-sm"
              >
                <span>{pic}</span>
                <span className="font-medium">{count} active</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
