import Link from "next/link";
import { notFound } from "next/navigation";
import { getSop } from "@/lib/data/sops";
import { getDepartment } from "@/lib/data/departments";

export default async function SopDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const sop = await getSop(id);
  if (!sop) notFound();
  const department = sop.department_id ? await getDepartment(sop.department_id) : null;

  return (
    <div className="max-w-2xl">
      <Link href="/sops" className="text-sm text-neutral-500 hover:underline">
        ← SOPs
      </Link>
      <h1 className="mt-1 text-2xl font-bold tracking-tight">{sop.title}</h1>
      <p className="mt-1 text-sm text-neutral-500">
        {department?.name ?? "No department"} · {sop.version}
      </p>
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
    </div>
  );
}
