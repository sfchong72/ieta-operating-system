import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getSop } from "@/lib/data/sops";
import { getDepartment } from "@/lib/data/departments";
import { listRecordEditLog } from "@/lib/data/record-edit-log";
import { DeleteButton } from "@/components/delete-button";
import { deleteSopAction } from "@/lib/actions/sops";

async function getDrafterName(userId: string | null): Promise<string | null> {
  if (!userId) return null;
  const supabase = await createClient();
  const { data } = await supabase
    .from("profiles")
    .select("full_name, email")
    .eq("id", userId)
    .maybeSingle();
  return data?.full_name ?? data?.email ?? null;
}

export default async function SopDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const sop = await getSop(id);
  if (!sop) notFound();
  const [department, drafterName, editLog] = await Promise.all([
    sop.department_id ? getDepartment(sop.department_id) : null,
    getDrafterName(sop.user_id),
    listRecordEditLog("sops", id),
  ]);

  return (
    <div className="max-w-2xl">
      <div className="flex items-start justify-between gap-4">
        <div>
          <Link href="/sops" className="text-sm text-neutral-500 hover:underline">
            ← SOPs
          </Link>
          <h1 className="mt-1 text-2xl font-bold tracking-tight">{sop.title}</h1>
          <p className="mt-1 text-sm text-neutral-500">
            {department?.name ?? "No department"} · {sop.version}
          </p>
          <p className="mt-1 text-xs text-neutral-400">
            Created {new Date(sop.created_at).toLocaleString()}
            {drafterName ? ` by ${drafterName}` : ""}
          </p>
        </div>
        <div className="flex shrink-0 gap-2">
          <Link
            href={`/sops/${sop.id}/edit`}
            className="rounded-md border border-neutral-300 px-3 py-1.5 text-sm font-medium hover:bg-neutral-50"
          >
            Edit
          </Link>
          <DeleteButton action={deleteSopAction} fields={{ id: sop.id }} itemLabel="SOP" />
        </div>
      </div>
      {sop.master_drive_link && (
        <a
          href={sop.master_drive_link}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-4 inline-block rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800"
        >
          Open master Drive link
        </a>
      )}
      {sop.content && (
        <div className="mt-6 whitespace-pre-wrap rounded-lg border border-neutral-200 p-4 text-sm">
          {sop.content}
        </div>
      )}

      <div className="mt-8">
        <h2 className="text-sm font-semibold">Edit history</h2>
        {editLog.length === 0 ? (
          <p className="mt-2 text-sm text-neutral-500">No edits yet.</p>
        ) : (
          <ul className="mt-2 space-y-2">
            {editLog.map((e) => (
              <li key={e.id} className="rounded-md border border-neutral-200 p-3 text-sm">
                <span className="font-medium">
                  {e.actor?.full_name ?? e.actor?.email ?? "Unknown"}
                </span>{" "}
                <span className="text-neutral-600">{e.summary}</span>
                <div className="mt-1 text-xs text-neutral-400">
                  {new Date(e.created_at).toLocaleString()}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
