import Link from "next/link";
import type { MasterFileSearchRow } from "@/lib/master-files";
import { FileLink, MasterFileAccessBadge, MasterFileStatusBadge, ReviewFlags } from "./master-file-ui";

export function MasterFileList({ files, emptyText }: { files: MasterFileSearchRow[]; emptyText: string }) {
  if (!files.length) return <div className="rounded-lg border border-dashed border-neutral-300 p-10 text-center text-sm text-neutral-500">{emptyText}</div>;
  return <>
    <div className="hidden overflow-x-auto rounded-lg border border-neutral-200 lg:block">
      <table className="min-w-full divide-y divide-neutral-200 text-left text-sm">
        <thead className="bg-neutral-50 text-xs uppercase text-neutral-500"><tr><Th>File</Th><Th>Scope</Th><Th>Category / project</Th><Th>Owner</Th><Th>Status</Th><Th>Verified</Th><Th>Master link</Th></tr></thead>
        <tbody className="divide-y divide-neutral-200 bg-white">{files.map((file) => <tr key={file.id} className="align-top hover:bg-neutral-50">
          <Td><Link href={`/files/${file.id}`} className="font-semibold text-neutral-950 hover:underline">{file.file_name}</Link><p className="mt-1 text-xs text-neutral-500">{file.file_number}</p><div className="mt-2"><ReviewFlags flags={file.review_flags} /></div></Td>
          <Td><p>{file.business_unit_name}</p><p className="text-xs text-neutral-500">{file.department_name}</p></Td>
          <Td><p>{file.category_label}</p><p className="text-xs text-neutral-500">{file.project_reference ?? "No project"}</p></Td>
          <Td>{file.owner_name}</Td>
          <Td><div className="space-y-2"><MasterFileStatusBadge status={file.status} /><br /><MasterFileAccessBadge access={file.access_level} /></div></Td>
          <Td>{formatDate(file.last_verified_at)}</Td>
          <Td><FileLink href={file.master_url}>Open file</FileLink></Td>
        </tr>)}</tbody>
      </table>
    </div>
    <div className="space-y-3 lg:hidden">{files.map((file) => <article key={file.id} className="rounded-lg border border-neutral-200 p-4">
      <div className="flex items-start justify-between gap-3"><div><Link href={`/files/${file.id}`} className="font-semibold hover:underline">{file.file_name}</Link><p className="mt-1 text-xs text-neutral-500">{file.file_number} · {file.category_label}</p></div><MasterFileStatusBadge status={file.status} /></div>
      <div className="mt-3"><ReviewFlags flags={file.review_flags} /></div>
      <dl className="mt-3 grid grid-cols-2 gap-3 text-sm"><div><dt className="text-xs text-neutral-500">Owner</dt><dd>{file.owner_name}</dd></div><div><dt className="text-xs text-neutral-500">Department</dt><dd>{file.department_name}</dd></div><div><dt className="text-xs text-neutral-500">Verified</dt><dd>{formatDate(file.last_verified_at)}</dd></div><div><dt className="text-xs text-neutral-500">Access</dt><dd className="mt-1"><MasterFileAccessBadge access={file.access_level} /></dd></div></dl>
      <div className="mt-4 flex gap-4 text-sm"><Link href={`/files/${file.id}`} className="font-medium underline">View details</Link><FileLink href={file.master_url}>Open file</FileLink></div>
    </article>)}</div>
  </>;
}

function Th({ children }: { children: React.ReactNode }) { return <th className="px-4 py-3 font-medium">{children}</th>; }
function Td({ children }: { children: React.ReactNode }) { return <td className="px-4 py-4">{children}</td>; }
function formatDate(value: string | null) { return value ? new Date(value).toLocaleDateString("en-MY") : "Not verified"; }

