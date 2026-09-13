import Link from "next/link";
import { redirect } from "next/navigation";
import { LeadList } from "@/components/marketing-leads/lead-list";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { searchMarketingLeads } from "@/lib/data/marketing-leads";
export default async function MyLeadsPage() { const user=await getCurrentUser(); if(!user?.canAccessMarketingLeads) redirect("/work"); const leads=await searchMarketingLeads({myLeads:true}); return <div className="mx-auto max-w-[1500px]"><PageHeader title="My Leads" description="Leads assigned to you for active follow-up." action={<Link href="/leads/follow-up" className="rounded-md border px-3 py-2 text-sm font-medium">Follow-Up Due</Link>} /><LeadList leads={leads} emptyText="No leads are currently assigned to you." /></div>; }

