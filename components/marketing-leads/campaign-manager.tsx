"use client";

import { useActionState, useState } from "react";
import { createMarketingCampaignAction, type LeadActionState } from "@/lib/actions/marketing-leads";
import type { BusinessUnit, Campaign, Department } from "@/lib/data/types";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const EMPTY: LeadActionState = {};
const input = "mt-1 w-full rounded-lg border border-neutral-300 bg-white px-3 py-2.5 text-sm shadow-sm focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20";

export function CampaignManager({ businessUnits, departments, campaigns }: {
  businessUnits: BusinessUnit[];
  departments: Department[];
  campaigns: Campaign[];
}) {
  const [businessUnitId, setBusinessUnitId] = useState("");
  const [state, action] = useActionState(async (previous: LeadActionState, formData: FormData) => {
    const result = await createMarketingCampaignAction(previous, formData);
    if (result.success) setBusinessUnitId("");
    return result;
  }, EMPTY);
  const availableDepartments = departments.filter((department) => department.business_unit_id === businessUnitId);

  return <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(320px,0.7fr)]">
    <section className="rounded-2xl border border-neutral-200 bg-white p-5 shadow-sm">
      <h2 className="text-lg font-semibold">Configured campaigns</h2>
      <p className="mt-1 text-sm text-neutral-600">These choices appear in Add Lead and Edit Lead.</p>
      {campaigns.length ? <div className="mt-4 divide-y divide-neutral-100">
        {campaigns.map((campaign) => <div key={campaign.id} className="flex items-start justify-between gap-3 py-3">
          <div><p className="font-medium text-neutral-900">{campaign.name}</p><p className="mt-0.5 text-xs text-neutral-500">{businessUnits.find((unit) => unit.id === campaign.business_unit_id)?.name ?? "All units"} · {departments.find((department) => department.id === campaign.department_id)?.name ?? "All departments"}</p></div>
          <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700">{campaign.status}</span>
        </div>)}
      </div> : <p className="mt-4 rounded-xl border border-dashed border-neutral-300 bg-neutral-50 p-5 text-sm text-neutral-600">No campaigns have been configured in your permitted scope yet.</p>}
    </section>

    <form action={action} className="h-fit space-y-4 rounded-2xl border border-neutral-200 bg-white p-5 shadow-sm">
      <div><h2 className="text-lg font-semibold">Add campaign</h2><p className="mt-1 text-sm text-neutral-600">Campaigns are scoped to one business unit and department.</p></div>
      <FormError message={state.error} />
      {state.success && <p className="rounded-lg bg-emerald-50 p-3 text-sm text-emerald-800">{state.success}</p>}
      <label className="block text-sm font-medium">Business unit<select name="business_unit_id" required value={businessUnitId} onChange={(event) => setBusinessUnitId(event.target.value)} className={input}><option value="">Select business unit</option>{businessUnits.map((unit) => <option key={unit.id} value={unit.id}>{unit.name}</option>)}</select></label>
      <label className="block text-sm font-medium">Department<select key={businessUnitId} name="department_id" required defaultValue="" disabled={!businessUnitId} className={input}><option value="">{businessUnitId ? "Select department" : "Select business unit first"}</option>{availableDepartments.map((department) => <option key={department.id} value={department.id}>{department.name}</option>)}</select></label>
      <label className="block text-sm font-medium">Campaign name<input name="name" required maxLength={160} className={input} placeholder="e.g. September 2026 Intake" /></label>
      <SubmitButton pendingText="Adding…">Add campaign</SubmitButton>
      <p className="text-xs leading-relaxed text-neutral-500">If a company has no available department, your account has not been granted that organisational scope.</p>
    </form>
  </div>;
}
