import Link from "next/link";
import { notFound } from "next/navigation";
import { MasterFileGovernanceActions } from "@/components/master-files/master-file-actions";
import { BackToRegister, DetailItem, FileLink, MasterFileAccessBadge, MasterFileStatusBadge, ReviewFlags } from "@/components/master-files/master-file-ui";
import { getCurrentUser } from "@/lib/data/access";
import { canManageMasterFile, getMasterFileDetail } from "@/lib/data/master-files";
import { listWorkAssignees, listWorkTasks } from "@/lib/data/work-management";
import { humaniseMasterFile } from "@/lib/master-files";

export default async function MasterFileDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const [user, detail, canManage] = await Promise.all([getCurrentUser(), getMasterFileDetail(id), canManageMasterFile(id)]);
  if (!user || !detail) notFound();
  const { file, summary } = detail;
  const [people, tasks] = canManage ? await Promise.all([listWorkAssignees(), listWorkTasks()]) : [[], []];
  const earlier = file.supersedes_file_id ? detail.visibleFiles.find((item) => item.id === file.supersedes_file_id) : null;
  const canonical = file.duplicate_of_file_id ? detail.visibleFiles.find((item) => item.id === file.duplicate_of_file_id) : null;

  return <div className="mx-auto max-w-6xl space-y-6">
    <BackToRegister />
    <header className="flex flex-wrap items-start justify-between gap-4">
      <div><p className="text-xs font-medium text-neutral-500">{file.file_number}</p><h1 className="mt-1 text-2xl font-bold tracking-tight">{file.file_name}</h1><div className="mt-3 flex flex-wrap gap-2"><MasterFileStatusBadge status={file.status} /><MasterFileAccessBadge access={file.access_level} />{summary && <ReviewFlags flags={summary.review_flags} />}</div></div>
      <div className="flex flex-wrap gap-2">{file.master_url && <a href={file.master_url} target="_blank" rel="noreferrer" className="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white">Open master file</a>}{canManage && <Link href={`/files/${file.id}/edit`} className="rounded-md border border-neutral-300 px-4 py-2 text-sm font-medium">Edit metadata</Link>}</div>
    </header>

    {file.access_level === "pc_restricted" && <div className="rounded-md border border-rose-200 bg-rose-50 p-3 text-sm text-rose-950">P&C restricted metadata. Do not copy confidential content or credentials into Inter Excel Operating System.</div>}

    <section className="rounded-lg border border-neutral-200 p-5"><dl className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
      <DetailItem label="Business unit">{summary?.business_unit_name ?? "—"}</DetailItem>
      <DetailItem label="Department">{summary?.department_name ?? "—"}</DetailItem>
      <DetailItem label="Category">{summary?.category_label ?? humaniseMasterFile(file.category_slug)}</DetailItem>
      <DetailItem label="Owner">{summary?.owner_name ?? "Appointed owner"}</DetailItem>
      <DetailItem label="Project / campaign">{file.project_reference ?? "—"}</DetailItem>
      <DetailItem label="Source system">{humaniseMasterFile(file.source_system)}</DetailItem>
      <DetailItem label="Last verified">{formatDateTime(file.last_verified_at)}</DetailItem>
      <DetailItem label="Last metadata update">{formatDateTime(file.updated_at)}</DetailItem>
      <DetailItem label="Master link"><FileLink href={file.master_url}>Open governed master</FileLink></DetailItem>
      <DetailItem label="Folder link"><FileLink href={file.folder_url}>Open folder</FileLink></DetailItem>
      <DetailItem label="Archive date">{file.archive_date ?? "—"}</DetailItem>
      <DetailItem label="Record version">{file.row_version}</DetailItem>
    </dl></section>

    <section className="grid gap-5 lg:grid-cols-2"><TextPanel title="Description" text={file.description} /><TextPanel title="Remarks" text={file.remarks} /></section>

    <section className="grid gap-5 lg:grid-cols-2">
      <Panel title="Version and duplicate relationships"><ul className="space-y-2 text-sm">{earlier && <Relationship label="Supersedes" id={earlier.id} number={earlier.file_number} name={earlier.file_name} />}{canonical && <Relationship label="Duplicate of" id={canonical.id} number={canonical.file_number} name={canonical.file_name} />}{detail.replacements.map((item) => <Relationship key={item.id} label="Replaced by" id={item.id} number={item.file_number} name={item.file_name} />)}{detail.duplicates.map((item) => <Relationship key={item.id} label="Duplicate record" id={item.id} number={item.file_number} name={item.file_name} />)}{!earlier && !canonical && !detail.replacements.length && !detail.duplicates.length && <li className="text-neutral-500">No visible version or duplicate relationships.</li>}</ul></Panel>
      <Panel title="Related tasks"><ul className="space-y-2 text-sm">{detail.taskLinks.map((task) => <li key={task.task_id}><Link href={`/work/${task.task_id}`} className="font-medium underline">{task.task_number} · {task.task_title}</Link></li>)}{!detail.taskLinks.length && <li className="text-neutral-500">No visible task links.</li>}</ul></Panel>
    </section>

    <Panel title="Related task artifacts"><ul className="divide-y divide-neutral-200">{detail.artifactLinks.map((artifact) => <li key={artifact.task_artifact_id} className="py-3 text-sm"><FileLink href={artifact.url}>{artifact.label ?? humaniseMasterFile(artifact.artifact_type)}</FileLink><p className="mt-1 text-xs text-neutral-500">{humaniseMasterFile(artifact.artifact_type)} · {humaniseMasterFile(artifact.artifact_sensitivity)}</p></li>)}{!detail.artifactLinks.length && <li className="text-sm text-neutral-500">No visible task-artifact links.</li>}</ul></Panel>

    {canManage && <Panel title="File governance"><MasterFileGovernanceActions file={file} candidates={detail.visibleFiles} people={people} tasks={tasks} grants={detail.accessGrants} /></Panel>}

    <Panel title="Audit history"><ol className="space-y-3">{detail.audit.map((event) => <li key={event.event_id} className="rounded-md bg-neutral-50 p-3 text-sm"><div className="flex flex-wrap justify-between gap-2"><span className="font-medium">{humaniseMasterFile(event.event_type)}</span><time className="text-xs text-neutral-500">{formatDateTime(event.created_at)}</time></div><p className="mt-1 text-xs text-neutral-600">{event.actor_name}</p>{Object.keys(event.metadata).length > 0 && <p className="mt-2 break-words text-xs text-neutral-500">{auditSummary(event.metadata)}</p>}</li>)}{!detail.audit.length && <li className="text-sm text-neutral-500">No visible audit events.</li>}</ol></Panel>
  </div>;
}

function Relationship({ label, id, number, name }: { label: string; id: string; number: string; name: string }) { return <li><span className="text-neutral-500">{label}: </span><Link href={`/files/${id}`} className="font-medium underline">{number} · {name}</Link></li>; }
function Panel({ title, children }: { title: string; children: React.ReactNode }) { return <section className="rounded-lg border border-neutral-200 p-5"><h2 className="mb-4 text-base font-semibold">{title}</h2>{children}</section>; }
function TextPanel({ title, text }: { title: string; text: string | null }) { return <Panel title={title}><p className="whitespace-pre-wrap text-sm leading-6 text-neutral-700">{text ?? "—"}</p></Panel>; }
function formatDateTime(value: string | null) { return value ? new Date(value).toLocaleString("en-MY") : "—"; }
function auditSummary(metadata: Record<string, unknown>) { return Object.entries(metadata).map(([key, value]) => `${humaniseMasterFile(key)}: ${String(value)}`).join(" · "); }

