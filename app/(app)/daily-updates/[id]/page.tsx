import Link from "next/link";
import { notFound } from "next/navigation";
import { DailyUpdateReviewForm } from "@/components/daily-output/daily-update-forms";
import { getCurrentUser } from "@/lib/data/access";
import { getDailyWorkUpdateDetail } from "@/lib/data/daily-output";
import { listWorkAssignees } from "@/lib/data/work-management";
import { humanise } from "@/components/work/work-ui";

export default async function DailyUpdateDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser();
  if (!user) return null;
  const detail = await getDailyWorkUpdateDetail(id);
  if (!detail.update || !detail.task) notFound();
  const { update, task, artifact, reviews } = detail;
  const canManage = user.role === "super_admin" || (user.role === "management" && user.businessUnitIds.includes(task.business_unit_id));
  const assignees = canManage ? await listWorkAssignees() : [];
  const names = new Map(assignees.map((person) => [person.profile_id, person.full_name]));
  names.set(user.profile.id, user.profile.full_name ?? user.profile.email);

  return <div className="mx-auto max-w-4xl space-y-6">
    <header><Link href="/daily-updates" className="text-sm underline">← Daily updates</Link><p className="mt-5 text-xs font-medium text-neutral-500">{task.task_number} · {update.work_date}</p><h1 className="mt-1 text-2xl font-bold tracking-tight">{task.title}</h1></header>
    <section className="grid gap-4 rounded-lg border border-neutral-200 p-5 sm:grid-cols-2"><Info label="Submitted by" value={names.get(update.staff_id) ?? "Assigned staff"} /><Info label="What was done today" value={update.what_done_today} /><Info label="Quantity" value={update.quantity ?? "—"} /><Info label="Result / output" value={update.result_or_output} /><Info label="Deliverable completed" value={update.deliverable_completed ? "Yes" : "No"} />{update.blocker_or_help && <Info label="Blocker / need help" value={update.blocker_or_help} />}{artifact && <div><p className="text-xs uppercase text-neutral-500">Work / evidence</p><a href={artifact.url} target="_blank" rel="noreferrer" className="mt-1 block break-all text-sm font-medium underline">{artifact.label ?? "Open link"}</a></div>}</section>
    <section className="grid gap-6 lg:grid-cols-2"><div className="rounded-lg border border-neutral-200 p-5"><h2 className="mb-4 font-semibold">Supervisor review history</h2>{reviews.length ? <ul className="space-y-3">{reviews.map((review) => <li key={review.id} className="rounded-md bg-neutral-50 p-3 text-sm"><p className="font-medium">{humanise(review.review_status)}</p>{review.supervisor_comment && <p className="mt-2 whitespace-pre-wrap text-neutral-700">{review.supervisor_comment}</p>}<p className="mt-2 text-xs text-neutral-500">{names.get(review.reviewer_id) ?? "Supervisor"} · {new Date(review.created_at).toLocaleString("en-MY")}</p></li>)}</ul> : <p className="text-sm text-neutral-500">Pending supervisor review.</p>}</div>{canManage && <div className="rounded-lg border border-neutral-200 p-5"><h2 className="mb-4 font-semibold">Add supervisor review</h2><DailyUpdateReviewForm updateId={update.id} /></div>}</section>
  </div>;
}

function Info({ label, value }: { label: string; value: string }) { return <div><p className="text-xs uppercase text-neutral-500">{label}</p><p className="mt-1 whitespace-pre-wrap text-sm leading-6">{value}</p></div>; }
