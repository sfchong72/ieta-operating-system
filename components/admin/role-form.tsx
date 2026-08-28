"use client";

import { useActionState } from "react";
import {
  assignRoleAction,
  grantBusinessUnitAccessAction,
  grantDepartmentAccessAction,
  type ActionState,
} from "@/lib/actions/admin";
import type { BusinessUnit, Department, Profile, Role } from "@/lib/data/types";

const ROLES: Role[] = ["super_admin", "management", "staff", "intern"];
const initialState: ActionState = {};

export function RoleForm({ profile, currentRole }: { profile: Profile; currentRole?: Role }) {
  const [state, formAction] = useActionState(assignRoleAction, initialState);
  return (
    <form action={formAction} className="flex items-center gap-2">
      <input type="hidden" name="profile_id" value={profile.id} />
      <select
        name="role"
        defaultValue={currentRole ?? ""}
        className="rounded-md border border-neutral-300 px-2 py-1 text-xs"
      >
        <option value="" disabled>
          — role —
        </option>
        {ROLES.map((r) => (
          <option key={r} value={r}>
            {r}
          </option>
        ))}
      </select>
      <button type="submit" className="rounded-md border border-neutral-300 px-2 py-1 text-xs hover:bg-neutral-50">
        Set
      </button>
      {state.error && <span className="text-xs text-red-600">{state.error}</span>}
    </form>
  );
}

export function BusinessUnitAccessForm({
  profile,
  businessUnits,
}: {
  profile: Profile;
  businessUnits: BusinessUnit[];
}) {
  const [state, formAction] = useActionState(grantBusinessUnitAccessAction, initialState);
  return (
    <form action={formAction} className="flex items-center gap-2">
      <input type="hidden" name="profile_id" value={profile.id} />
      <select name="business_unit_id" className="rounded-md border border-neutral-300 px-2 py-1 text-xs">
        {businessUnits.map((bu) => (
          <option key={bu.id} value={bu.id}>
            {bu.name}
          </option>
        ))}
      </select>
      <button type="submit" className="rounded-md border border-neutral-300 px-2 py-1 text-xs hover:bg-neutral-50">
        + Grant BU access
      </button>
      {state.error && <span className="text-xs text-red-600">{state.error}</span>}
    </form>
  );
}

export function DepartmentAccessForm({
  profile,
  departments,
}: {
  profile: Profile;
  departments: Department[];
}) {
  const [state, formAction] = useActionState(grantDepartmentAccessAction, initialState);
  return (
    <form action={formAction} className="flex items-center gap-2">
      <input type="hidden" name="profile_id" value={profile.id} />
      <select name="department_id" className="rounded-md border border-neutral-300 px-2 py-1 text-xs">
        {departments.map((d) => (
          <option key={d.id} value={d.id}>
            {d.name}
          </option>
        ))}
      </select>
      <button type="submit" className="rounded-md border border-neutral-300 px-2 py-1 text-xs hover:bg-neutral-50">
        + Grant dept access
      </button>
      {state.error && <span className="text-xs text-red-600">{state.error}</span>}
    </form>
  );
}
