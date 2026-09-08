import Link from "next/link";
import { notFound } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import { getDepartment } from "@/lib/data/departments";
import { getWorkTaskDetail, listWorkAssignees } from "@/lib/data/work-management";
import { ArtifactForm, CommentForm, QuickUpdateForm, SupervisorForm } from "@/components/work/task-interactions";
import { AttentionBadges, humanise, PriorityLabel, WorkStatusBadge } from "@/components/work/work-ui";

export default async function WorkTaskDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser();
  if (!user) return null;
  const detail = await getWorkTaskDetail(id);
  if (!detail.task) notFound();
  const task = detail.task;
  const canManage = ["super_admin", "management"].includes(user.role ?? "");
  const [department, assignees] = await Promise.all([getDepartment(task.department_id), canManage ? listWorkAssignees() : Promise.resolve([])]);
  const names = new Map(assignees.map((person) => [person.profile_id, person.full_name]));
  names.set(user.profile.id, user.profile.full_name ?? user.profile.email);
  const nameFor = (profileId: string) => names.get(profileId) ?? (profileId === task.assigned_to ? "Assigned user" : "Supervisor");

  return <div className="mx-auto max-w-5xl space-y-6">
    <div className="flex flex-wrap items-start justify-between gap-4"><div><p className="text-xs font-medium text-neutral-500">{task.task_number}</p><h1 className="mt-1 text-2xl font-bold tracking-tight">{task.title}</h1><div className="mt-3 flex flex-wrap items-center gap-2"><WorkStatusBadge status={task.status} /><PriorityLabel priority={task.priority} /><AttentionBadges flags={detail.attention?.attention_flags ?? []} /></div></div><div className="flex gap-2">{canManage && <Link href={`/work/${id}/edit`} className="rounded-md border border-neutral-300 px-3 py-2 text-sm font-medium">Edit assignment</Link>}<Link href={`/work/${id}/quick-update`} className="rounded-md bg-neutral-900 px-3 py-2 text-sm font-medium text-white">Quick Update</Link></div></div>

    <section className="grid gap-4 rounded-lg border border-neutral-200 p-5 sm:grid-cols-2 lg:grid-cols-4"><Info label="Assigned to" value={nameFor(task.assigned_to)} /><Info label="Department" value={department?.name ?? "—"} /><Info label="Project / campaign" value={task.project_reference ?? "—"} /><Info label="Deadline" value={task.due_date ?? "—"} /><Info label="Progress" value={`${task.progress_percent}%`} /><Info label="Sensitivity" value={humanise(task.task_sensitivity)} /><Info label="Output required" value={task.output_required ? "Yes" : "No"} /><Info label="Last updated" value={new Date(task.updated_at).toLocaleString("en-MY")} /></section>

    <section className="grid gap-5 lg:grid-cols-2"><TextCard title="Instructions" text={task.instructions} /><TextCard title="Expected final output" text={task.expected_final_output ?? "No output description provided."} />{task.current_blocker && <TextCard title="Current blocker / need help" text={task.current_blocker} />}{task.next_action && <TextCard title="Supervisor next action" text={task.next_action} />}</section>

    <section className="grid gap-6 lg:grid-cols-2"><Panel title="Quick Update"><QuickUpdateForm task={task} /></Panel><Panel title="Add work / artwork / evidence link"><ArtifactForm taskId={task.id} canManage={canManage} /></Panel></section>
    <Panel title="Links and evidence">{detail.artifacts.length ? <ul className="divide-y divide-neutral-200">{detail.artifacts.map((artifact) => <li key={artifact.id} className="py-3"><div className="flex flex-wrap items-center gap-2"><a href={artifact.url} target="_blank" rel="noreferrer" className="font-medium underline">{artifact.label ?? humanise(artifact.artifact_type)}</a><span className="rounded bg-neutral-100 px-2 py-1 text-xs">{humanise(artifact.artifact_type)}</span><span className="text-xs text-neutral-500">{humanise(artifact.artifact_sensitivity)}</span></div><p className="mt-1 text-xs text-neutral-500">Added by {nameFor(artifact.added_by)} · {new Date(artifact.created_at).toLocaleString("en-MY")}</p></li>)}</ul> : <p className="text-sm text-neutral-500">No visible links yet.</p>}</Panel>
    <section className="grid gap-6 lg:grid-cols-2"><Panel title="Comments / feedback"><CommentForm taskId={task.id} /><div className="mt-5 space-y-3">{detail.comments.map((comment) => <div key={comment.id} className="rounded-md bg-neutral-50 p-3 text-sm"><div className="flex justify-between gap-3"><span className="font-medium">{nameFor(comment.author_id)}</span><span className="text-xs text-neutral-500">{new Date(comment.created_at).toLocaleString("en-MY")}</span></div><p className="mt-2 whitespace-pre-wrap">{comment.body}</p><p className="mt-2 text-xs text-neutral-500">{humanise(comment.comment_kind)}{comment.audience === "management_only" ? " · Management only" : ""}</p></div>)}{!detail.comments.length && <p className="text-sm text-neutral-500">No comments yet.</p>}</div></Panel>{canManage && <Panel title="Supervisor review"><SupervisorForm task={task} /></Panel>}</section>
    <Panel title="Update history">{detail.updates.length ? <ul className="space-y-2 text-sm">{detail.updates.map((update) => <li key={update.id} className="rounded-md border border-neutral-200 p-3"><span className="font-medium">{humanise(update.status)} · {update.progress_percent}%</span><span className="ml-2 text-xs text-neutral-500">{new Date(update.created_at).toLocaleString("en-MY")}</span>{update.blocker_or_help && <p className="mt-1 text-neutral-700">{update.blocker_or_help}</p>}</li>)}</ul> : <p className="text-sm text-neutral-500">No quick updates yet.</p>}</Panel>
  </div>;
}

function Info({ label, value }: { label: string; value: string }) { return <div><p className="text-xs uppercase text-neutral-500">{label}</p><p className="mt-1 text-sm font-medium">{value}</p></div>; }
function TextCard({ title, text }: { title: string; text: string }) { return <Panel title={title}><p className="whitespace-pre-wrap text-sm leading-6 text-neutral-700">{text}</p></Panel>; }
function Panel({ title, children }: { title: string; children: React.ReactNode }) { return <section className="rounded-lg border border-neutral-200 p-5"><h2 className="mb-4 text-base font-semibold">{title}</h2>{children}</section>; }
