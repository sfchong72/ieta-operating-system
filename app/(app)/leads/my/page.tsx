import Link from "next/link";
import { redirect } from "next/navigation";
import { LeadList } from "@/components/marketing-leads/lead-list";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { searchMarketingLeads } from "@/lib/data/marketing-leads";
export default async function MyLeadsPage() { const user=await getCurrentUser(); if(!user?.canAccessMarketingLeads) redirect("/work"); const leads=await searchMarketingLeads({myLeads:true}); return <div className="mx-auto max-w-[1500px]"><PageHeader title="My Leads" description="Your assigned leads, contact status and next actions at a glance." action={<Link href="/leads/follow-up" className="inline-flex min-h-11 w-full items-center justify-center rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-teal-700 sm:w-auto">View follow-ups due</Link>} /><p className="mb-3 text-sm font-medium text-slate-500">{leads.length} assigned lead{leads.length===1?"":"s"}</p><LeadList leads={leads} emptyText="No leads are currently assigned to you." /></div>; }
