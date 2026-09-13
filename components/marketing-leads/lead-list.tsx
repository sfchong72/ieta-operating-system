import Link from "next/link";
import type { MarketingLeadRow } from "@/lib/marketing-leads";
import { formatLeadDate, humaniseLead } from "@/lib/marketing-leads";

export function LeadStatusBadge({ status }: { status: string }) {
  const closed = ["signed_up", "not_suitable", "withdrawn", "closed_other"].includes(status);
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${closed ? "bg-neutral-100 text-neutral-700" : status === "new" ? "bg-blue-100 text-blue-800" : "bg-emerald-100 text-emerald-800"}`}>{humaniseLead(status)}</span>;
}

export function AttentionBadge({ reason }: { reason: string | null }) {
  if (!reason) return null;
  const urgent = reason.startsWith("OVERDUE");
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${urgent ? "bg-red-100 text-red-800" : "bg-amber-100 text-amber-900"}`}>{reason}</span>;
}

export function LeadList({ leads, emptyText }: { leads: MarketingLeadRow[]; emptyText: string }) {
  if (!leads.length) return <div className="rounded-lg border border-dashed border-neutral-300 p-10 text-center text-sm text-neutral-500">{emptyText}</div>;
  return <>
    <div className="hidden overflow-x-auto rounded-lg border border-neutral-200 lg:block">
      <table className="min-w-full divide-y divide-neutral-200 text-left text-sm">
        <thead className="bg-neutral-50 text-xs uppercase text-neutral-500"><tr><Th>Lead</Th><Th>Programme</Th><Th>Source</Th><Th>Assigned</Th><Th>Status</Th><Th>Follow-up</Th></tr></thead>
        <tbody className="divide-y divide-neutral-200 bg-white">{leads.map((lead) => <tr key={lead.id} className="align-top hover:bg-neutral-50">
          <Td><Link href={`/leads/${lead.id}`} className="font-semibold hover:underline">{lead.lead_number}</Link><p className="mt-1">{lead.name}</p><p className="text-xs text-neutral-500">{lead.contact_number}{lead.email ? ` · ${lead.email}` : ""}</p></Td>
          <Td>{lead.programme_interest}<p className="text-xs text-neutral-500">{lead.business_unit_name} · {lead.branch}</p></Td>
          <Td>{lead.source_label}<p className="text-xs text-neutral-500">{formatLeadDate(lead.date_received)}</p></Td>
          <Td>{lead.assigned_to_name}</Td>
          <Td><LeadStatusBadge status={lead.status} /><div className="mt-2"><AttentionBadge reason={lead.attention_reason} /></div></Td>
          <Td>{formatLeadDate(lead.next_follow_up_at)}<p className="mt-1 text-xs text-neutral-500">Last contact: {formatLeadDate(lead.last_contact_at)}</p></Td>
        </tr>)}</tbody>
      </table>
    </div>
    <div className="space-y-3 lg:hidden">{leads.map((lead) => <article key={lead.id} className="rounded-lg border border-neutral-200 p-4">
      <div className="flex items-start justify-between gap-3"><div><Link href={`/leads/${lead.id}`} className="font-semibold hover:underline">{lead.lead_number}</Link><p className="mt-1 text-sm">{lead.name}</p></div><LeadStatusBadge status={lead.status} /></div>
      <div className="mt-3"><AttentionBadge reason={lead.attention_reason} /></div>
      <dl className="mt-3 grid grid-cols-2 gap-3 text-sm"><div><dt className="text-xs text-neutral-500">Programme</dt><dd>{lead.programme_interest}</dd></div><div><dt className="text-xs text-neutral-500">Assigned</dt><dd>{lead.assigned_to_name}</dd></div><div><dt className="text-xs text-neutral-500">Source</dt><dd>{lead.source_label}</dd></div><div><dt className="text-xs text-neutral-500">Next follow-up</dt><dd>{formatLeadDate(lead.next_follow_up_at)}</dd></div></dl>
      <Link href={`/leads/${lead.id}`} className="mt-4 inline-block text-sm font-medium underline">Open lead</Link>
    </article>)}</div>
  </>;
}
function Th({ children }: { children: React.ReactNode }) { return <th className="px-4 py-3 font-medium">{children}</th>; }
function Td({ children }: { children: React.ReactNode }) { return <td className="px-4 py-4">{children}</td>; }

