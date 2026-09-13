import { createClient } from "@/lib/supabase/server";
import type {
  Profile,
  Role,
  UserRoleAssignment,
  UserBusinessUnitAccess,
  UserDepartmentAccess,
} from "./types";

export type CurrentUser = {
  profile: Profile;
  role: Role | null;
  businessUnitIds: string[];
  departmentIds: string[];
  canViewWorkDashboard: boolean;
  canAccessMarketingLeads: boolean;
};

/**
 * The logged-in user's profile + role + access grants, or null if signed
 * out. Errors on any of the four queries are checked explicitly (not
 * silently swallowed) — an error here must not be treated the same as "no
 * profile exists yet", which would wrongly bounce a real, fully-provisioned
 * user back to /login.
 */
export async function getCurrentUser(): Promise<CurrentUser | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const [profileRes, roleRes, buAccessRes, deptAccessRes, dashboardRes, leadsRes] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", user.id).maybeSingle(),
    supabase.from("user_role_assignment").select("*").eq("profile_id", user.id).maybeSingle(),
    supabase.from("user_business_unit_access").select("*").eq("profile_id", user.id),
    supabase.from("user_department_access").select("*").eq("profile_id", user.id),
    supabase.rpc("fn_wm_can_view_dashboard", { subject_uid: user.id }),
    supabase.rpc("fn_ml_can_access_module", { subject_uid: user.id }),
  ]);

  for (const res of [profileRes, roleRes, buAccessRes, deptAccessRes, dashboardRes, leadsRes]) {
    if (res.error) throw res.error;
  }

  if (!profileRes.data) return null;

  return {
    profile: profileRes.data,
    role: (roleRes.data?.role as Role) ?? null,
    businessUnitIds: (buAccessRes.data ?? []).map((r) => r.business_unit_id),
    departmentIds: (deptAccessRes.data ?? []).map((r) => r.department_id),
    canViewWorkDashboard: dashboardRes.data === true,
    canAccessMarketingLeads: leadsRes.data === true,
  };
}

export async function listProfiles(): Promise<Profile[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("profiles").select("*").order("created_at");
  if (error) throw error;
  return data ?? [];
}

export async function listRoleAssignments(): Promise<UserRoleAssignment[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("user_role_assignment").select("*");
  if (error) throw error;
  return data ?? [];
}

export async function listBusinessUnitAccess(): Promise<UserBusinessUnitAccess[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("user_business_unit_access").select("*");
  if (error) throw error;
  return data ?? [];
}

export async function listDepartmentAccess(): Promise<UserDepartmentAccess[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("user_department_access").select("*");
  if (error) throw error;
  return data ?? [];
}
