import Link from "next/link";
import type { MarketingLeadRow } from "@/lib/marketing-leads";
import { formatLeadDate, humaniseLead } from "@/lib/marketing-leads";

export function LeadStatusBadge({ status }: { status: string }) {
  const closed = ["signed_up", "not_suitable", "withdrawn", "closed_other"].includes(status);
  return <span className={`inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-semibold ${closed ? "bg-slate-100 text-slate-700" : status === "new" ? "bg-blue-100 text-blue-800" : "bg-emerald-100 text-emerald-800"}`}>{humaniseLead(status)}</span>;
}

export function AttentionBadge({ reason }: { reason: string | null }) {
  if (!reason) return null;
  const urgent = reason.startsWith("OVERDUE");
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold leading-4 ${urgent ? "bg-red-100 text-red-800" : "bg-amber-100 text-amber-900"}`}>{reason}</span>;
}

export function LeadList({ leads, emptyText }: { leads: MarketingLeadRow[]; emptyText: string }) {
  if (!leads.length) return <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-5 py-12 text-center text-sm leading-6 text-slate-500 shadow-sm">{emptyText}</div>;
  return <>
    <div className="hidden overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm xl:block">
      <table className="w-full table-fixed divide-y divide-slate-200 text-left text-sm">
        <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><Th>Lead</Th><Th>Programme</Th><Th>Source</Th><Th>Assigned</Th><Th>Status</Th><Th>Follow-up</Th></tr></thead>
        <tbody className="divide-y divide-slate-100 bg-white">{leads.map((lead) => <tr key={lead.id} className="align-top transition-colors hover:bg-teal-50/40">
          <Td><Link href={`/leads/${lead.id}`} className="font-semibold text-teal-700 underline-offset-4 hover:underline">{lead.lead_number}</Link><p className="mt-1 font-medium text-slate-900">{lead.name}</p><p className="mt-0.5 max-w-64 break-words text-xs leading-5 text-slate-500">{lead.contact_number}{lead.email ? ` · ${lead.email}` : ""}</p></Td>
          <Td><span className="font-medium text-slate-800">{lead.programme_interest}</span><p className="mt-1 text-xs leading-5 text-slate-500">{lead.business_unit_name} · {lead.branch}</p></Td>
          <Td>{lead.source_label}<p className="mt-1 text-xs text-slate-500">{formatLeadDate(lead.date_received)}</p></Td>
          <Td>{lead.assigned_to_name}</Td>
          <Td><LeadStatusBadge status={lead.status} /><div className="mt-2"><AttentionBadge reason={lead.attention_reason} /></div></Td>
          <Td><span className="font-medium text-slate-800">{formatLeadDate(lead.next_follow_up_at)}</span><p className="mt-1 text-xs leading-5 text-slate-500">Last contact: {formatLeadDate(lead.last_contact_at)}</p></Td>
        </tr>)}</tbody>
      </table>
    </div>
    <div className="space-y-3 xl:hidden">{leads.map((lead) => <article key={lead.id} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:p-5">
      <div className="flex items-start justify-between gap-3"><div className="min-w-0"><Link href={`/leads/${lead.id}`} className="font-semibold text-teal-700 underline-offset-4 hover:underline">{lead.lead_number}</Link><p className="mt-1 truncate text-sm font-semibold text-slate-900">{lead.name}</p></div><LeadStatusBadge status={lead.status} /></div>
      {lead.attention_reason && <div className="mt-3"><AttentionBadge reason={lead.attention_reason} /></div>}
      <dl className="mt-4 grid grid-cols-2 gap-x-4 gap-y-3 border-t border-slate-100 pt-4 text-sm"><div><dt className="text-xs text-slate-500">Programme</dt><dd className="mt-1 font-medium text-slate-800">{lead.programme_interest}</dd></div><div><dt className="text-xs text-slate-500">Assigned</dt><dd className="mt-1 text-slate-700">{lead.assigned_to_name}</dd></div><div><dt className="text-xs text-slate-500">Source</dt><dd className="mt-1 text-slate-700">{lead.source_label}</dd></div><div><dt className="text-xs text-slate-500">Next follow-up</dt><dd className="mt-1 font-medium text-slate-800">{formatLeadDate(lead.next_follow_up_at)}</dd></div></dl>
      <Link href={`/leads/${lead.id}`} className="mt-4 inline-flex min-h-10 w-full items-center justify-center rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700 transition-colors hover:border-teal-300 hover:bg-teal-50 hover:text-teal-800 sm:w-auto">Open lead <span aria-hidden="true" className="ml-1">→</span></Link>
    </article>)}</div>
  </>;
}
function Th({ children }: { children: React.ReactNode }) { return <th scope="col" className="px-5 py-3 font-semibold">{children}</th>; }
function Td({ children }: { children: React.ReactNode }) { return <td className="px-5 py-4 text-slate-700">{children}</td>; }
