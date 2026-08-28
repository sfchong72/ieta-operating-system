import { redirect } from "next/navigation";
import {
  getCurrentUser,
  listProfiles,
  listRoleAssignments,
  listBusinessUnitAccess,
  listDepartmentAccess,
} from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { PageHeader } from "@/components/ui";
import { InviteForm } from "@/components/admin/invite-form";
import {
  RoleForm,
  BusinessUnitAccessForm,
  DepartmentAccessForm,
} from "@/components/admin/role-form";

export default async function AdminUsersPage() {
  const currentUser = await getCurrentUser();
  if (currentUser?.role !== "super_admin") {
    redirect("/dashboard");
  }

  const [profiles, roles, buAccess, deptAccess, businessUnits, departments] = await Promise.all([
    listProfiles(),
    listRoleAssignments(),
    listBusinessUnitAccess(),
    listDepartmentAccess(),
    listBusinessUnits(),
    listDepartments(),
  ]);

  const roleByProfile = new Map(roles.map((r) => [r.profile_id, r.role]));
  const buById = new Map(businessUnits.map((b) => [b.id, b.name]));
  const deptById = new Map(departments.map((d) => [d.id, d.name]));

  return (
    <div>
      <PageHeader
        title="Admin · Users"
        description="Manage roles and business-unit/department access. Super Admin only."
      />

      <div className="mb-8">
        <h2 className="mb-2 text-sm font-semibold">Invite a new user</h2>
        <InviteForm />
      </div>

      <div className="overflow-x-auto rounded-lg border border-neutral-200">
        <table className="w-full min-w-[900px] text-left text-sm">
          <thead className="bg-neutral-50 text-xs uppercase text-neutral-500">
            <tr>
              <th className="px-4 py-3 font-medium">User</th>
              <th className="px-4 py-3 font-medium">Role</th>
              <th className="px-4 py-3 font-medium">Business units</th>
              <th className="px-4 py-3 font-medium">Departments</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-200">
            {profiles.map((p) => {
              const myBu = buAccess.filter((a) => a.profile_id === p.id);
              const myDept = deptAccess.filter((a) => a.profile_id === p.id);
              return (
                <tr key={p.id} className="align-top">
                  <td className="px-4 py-3">
                    <p className="font-medium">{p.full_name ?? p.email}</p>
                    <p className="text-xs text-neutral-500">{p.email}</p>
                  </td>
                  <td className="px-4 py-3">
                    <RoleForm profile={p} currentRole={roleByProfile.get(p.id)} />
                  </td>
                  <td className="px-4 py-3">
                    <ul className="mb-2 space-y-0.5 text-xs">
                      {myBu.length === 0 ? (
                        <li className="text-neutral-400">none</li>
                      ) : (
                        myBu.map((a) => <li key={a.id}>{buById.get(a.business_unit_id)}</li>)
                      )}
                    </ul>
                    <BusinessUnitAccessForm profile={p} businessUnits={businessUnits} />
                  </td>
                  <td className="px-4 py-3">
                    <ul className="mb-2 space-y-0.5 text-xs">
                      {myDept.length === 0 ? (
                        <li className="text-neutral-400">none</li>
                      ) : (
                        myDept.map((a) => <li key={a.id}>{deptById.get(a.department_id)}</li>)
                      )}
                    </ul>
                    <DepartmentAccessForm profile={p} departments={departments} />
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
