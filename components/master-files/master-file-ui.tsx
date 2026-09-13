import Link from "next/link";
import type { MasterFileAccessLevel, MasterFileStatus } from "@/lib/master-files";
import { humaniseMasterFile } from "@/lib/master-files";

const STATUS_STYLE: Record<MasterFileStatus, string> = {
  current: "bg-emerald-100 text-emerald-800",
  under_review: "bg-amber-100 text-amber-900",
  superseded: "bg-neutral-200 text-neutral-700",
  archived: "bg-slate-200 text-slate-700",
};

const ACCESS_STYLE: Record<MasterFileAccessLevel, string> = {
  operational: "bg-blue-50 text-blue-800",
  appointed_personnel: "bg-violet-100 text-violet-800",
  full_time_only: "bg-cyan-100 text-cyan-900",
  management_only: "bg-orange-100 text-orange-900",
  pc_restricted: "bg-rose-100 text-rose-900",
};

export function MasterFileStatusBadge({ status }: { status: MasterFileStatus }) {
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${STATUS_STYLE[status]}`}>{humaniseMasterFile(status)}</span>;
}

export function MasterFileAccessBadge({ access }: { access: MasterFileAccessLevel }) {
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${ACCESS_STYLE[access]}`}>{access === "pc_restricted" ? "P&C Restricted" : humaniseMasterFile(access)}</span>;
}

export function FileLink({ href, children }: { href: string | null; children: React.ReactNode }) {
  if (!href) return <span className="text-neutral-400">—</span>;
  return <a href={href} target="_blank" rel="noreferrer" className="font-medium text-blue-700 underline decoration-blue-300 underline-offset-2 hover:text-blue-900">{children}</a>;
}

export function ReviewFlags({ flags }: { flags: string[] }) {
  if (!flags.length) return null;
  return <div className="flex flex-wrap gap-1.5">{flags.map((flag) => <span key={flag} className="rounded bg-amber-100 px-2 py-1 text-[11px] font-semibold text-amber-900">{flag}</span>)}</div>;
}

export function BackToRegister() {
  return <Link href="/files" className="text-sm font-medium text-neutral-600 underline hover:text-neutral-950">← File Register</Link>;
}

export function DetailItem({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><dt className="text-xs font-medium uppercase tracking-wide text-neutral-500">{label}</dt><dd className="mt-1 text-sm text-neutral-900">{children}</dd></div>;
}

