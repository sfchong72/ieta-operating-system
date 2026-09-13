import Link from "next/link";
import { redirect } from "next/navigation";
import { LeadList } from "@/components/marketing-leads/lead-list";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { searchMarketingLeads } from "@/lib/data/marketing-leads";
export default async function FollowUpDuePage() { const user=await getCurrentUser(); if(!user?.canAccessMarketingLeads) redirect("/work"); const leads=await searchMarketingLeads({dueOnly:true,myLeads:!["super_admin","management"].includes(user.role??"")}); return <div className="mx-auto max-w-[1500px]"><PageHeader title="Follow-Up Due" description="Overdue, due today, new/uncontacted and upcoming consultation exceptions." action={<Link href="/leads" className="rounded-md border px-3 py-2 text-sm font-medium">Lead Register</Link>} /><LeadList leads={leads} emptyText="No permitted leads currently need attention." /></div>; }

