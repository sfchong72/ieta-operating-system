import Link from "next/link";
import { notFound } from "next/navigation";
import { getTask } from "@/lib/data/content-tasks";
import { getDepartment } from "@/lib/data/departments";
import { listSopsByDepartment } from "@/lib/data/sops";
import { getIdea } from "@/lib/data/content-ideas";
import { listWorkFiles } from "@/lib/data/work-files";
import { listActivitiesForTask } from "@/lib/data/activities";
import { StatusBadge } from "@/components/ui";
import { DeleteButton } from "@/components/delete-button";
import { deleteTaskAction } from "@/lib/actions/tasks";
import { AttachLinkForm } from "@/components/task-actions/attach-link-form";
import { SubmitReviewForm } from "@/components/task-actions/submit-review-form";
import { ApprovalForms } from "@/components/task-actions/approval-forms";
import { MarkPostedForm } from "@/components/task-actions/mark-posted-form";

export default async function TaskDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const task = await getTask(id);
  if (!task) notFound();

  const [department, idea, workFiles, activities] = await Promise.all([
    task.department_id ? getDepartment(task.department_id) : null,
    task.idea_id ? getIdea(task.idea_id) : null,
    listWorkFiles(task.id),
    listActivitiesForTask(task.id),
  ]);
  const sops = task.department_id ? await listSopsByDepartment(task.department_id) : [];

  const canAttachLink = task.status !== "posted";
  const canSubmit = task.status === "in_progress" || task.status === "amendment";
  const canReview = task.status === "submitted";
  const canMarkPosted = task.status === "approved";

  return (
    <div className="max-w-3xl">
      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <Link href="/tasks" className="text-sm text-neutral-500 hover:underline">
            ← Tasks
          </Link>
          <h1 className="mt-1 text-2xl font-bold tracking-tight">{task.title}</h1>
          <div className="mt-2 flex flex-wrap items-center gap-2">
            <StatusBadge status={task.status} />
            {task.approval_status && (
              <span className="text-xs text-neutral-500">
                approval: {task.approval_status}
              </span>
            )}
          </div>
        </div>
        <DeleteButton
          action={deleteTaskAction}
          fields={{ task_id: task.id }}
          itemLabel="task"
        />
      </div>

      <dl className="mb-6 grid grid-cols-2 gap-4 rounded-lg border border-neutral-200 p-4 text-sm sm:grid-cols-3">
        <div>
          <dt className="text-xs uppercase text-neutral-500">PIC</dt>
          <dd className="mt-0.5 font-medium">{task.pic_name}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Department</dt>
          <dd className="mt-0.5 font-medium">{department?.name ?? "—"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Platform</dt>
          <dd className="mt-0.5 font-medium">{task.platform ?? "—"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Deadline</dt>
          <dd className="mt-0.5 font-medium">{task.deadline ?? "—"}</dd>
        </div>
        <div>
          <dt className="text-xs uppercase text-neutral-500">Linked idea</dt>
          <dd className="mt-0.5 font-medium">{idea?.title ?? "—"}</dd>
        </div>
        {task.remarks && (
          <div className="col-span-2 sm:col-span-3">
            <dt className="text-xs uppercase text-neutral-500">Remarks</dt>
            <dd className="mt-0.5">{task.remarks}</dd>
          </div>
        )}
      </dl>

      {sops.length > 0 && (
        <div className="mb-6 rounded-lg border border-neutral-200 p-4">
          <h2 className="text-sm font-semibold">SOPs for {department?.name}</h2>
          <ul className="mt-2 space-y-1">
            {sops.map((sop) => (
              <li key={sop.id} className="text-sm">
                <Link href={`/sops/${sop.id}`} className="hover:underline">
                  {sop.title}
                </Link>{" "}
                {sop.master_drive_link && (
                  <a
                    href={sop.master_drive_link}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-neutral-500 hover:underline"
                  >
                    (master file)
                  </a>
                )}
              </li>
            ))}
          </ul>
        </div>
      )}

      {workFiles.length > 0 && (
        <div className="mb-6 rounded-lg border border-neutral-200 p-4">
          <h2 className="text-sm font-semibold">Work files</h2>
          <ul className="mt-2 space-y-1">
            {workFiles.map((f) => (
              <li key={f.id} className="text-sm">
                <a
                  href={f.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:underline"
                >
                  {f.label || f.url}
                </a>{" "}
                <span className="text-xs text-neutral-500">({f.file_type})</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {task.status === "posted" && task.posted_url && (
        <div className="mb-6 rounded-lg border border-purple-200 bg-purple-50/40 p-4 text-sm">
          <h2 className="text-sm font-semibold">Posted</h2>
          <p className="mt-1">
            <a
              href={task.posted_url}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:underline"
            >
              {task.posted_url}
            </a>{" "}
            on {task.posted_date}
          </p>
        </div>
      )}

      <div className="space-y-4">
        {canAttachLink && <AttachLinkForm taskId={task.id} />}
        {canSubmit && <SubmitReviewForm taskId={task.id} />}
        {canReview && <ApprovalForms taskId={task.id} />}
        {canMarkPosted && <MarkPostedForm taskId={task.id} />}
      </div>

      <div className="mt-8">
        <h2 className="text-sm font-semibold">Activity trail</h2>
        {activities.length === 0 ? (
          <p className="mt-2 text-sm text-neutral-500">No activity yet.</p>
        ) : (
          <ul className="mt-2 space-y-2">
            {activities.map((a) => (
              <li key={a.id} className="rounded-md border border-neutral-200 p-3 text-sm">
                <span className="font-medium">{a.actor_name ?? "system"}</span>{" "}
                <span className="text-neutral-500">{a.action.replace("_", " ")}</span>
                {a.detail && <span className="text-neutral-600"> — {a.detail}</span>}
                <div className="mt-1 text-xs text-neutral-400">
                  {new Date(a.created_at).toLocaleString()}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
