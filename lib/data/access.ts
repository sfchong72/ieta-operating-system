import { createClient } from "@/lib/supabase/server";
import { withJwtClockSkewRetry } from "@/lib/supabase/retry";
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
};

/**
 * The logged-in user's profile + role + access grants, or null if signed
 * out. This is the very first query made after a fresh login (called from
 * the (app) layout before anything else renders), so it's the most likely
 * place to hit the PGRST303 "JWT issued at future" clock-skew race —
 * wrapped in a retry rather than silently treating a query error the same
 * as "no profile exists yet", which would otherwise wrongly bounce a real,
 * fully-provisioned user back to /login.
 */
export async function getCurrentUser(): Promise<CurrentUser | null> {
  return withJwtClockSkewRetry(async () => {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return null;

    const [profileRes, roleRes, buAccessRes, deptAccessRes] = await Promise.all([
      supabase.from("profiles").select("*").eq("id", user.id).maybeSingle(),
      supabase.from("user_role_assignment").select("*").eq("profile_id", user.id).maybeSingle(),
      supabase.from("user_business_unit_access").select("*").eq("profile_id", user.id),
      supabase.from("user_department_access").select("*").eq("profile_id", user.id),
    ]);

    for (const res of [profileRes, roleRes, buAccessRes, deptAccessRes]) {
      if (res.error) throw res.error;
    }

    if (!profileRes.data) return null;

    return {
      profile: profileRes.data,
      role: (roleRes.data?.role as Role) ?? null,
      businessUnitIds: (buAccessRes.data ?? []).map((r) => r.business_unit_id),
      departmentIds: (deptAccessRes.data ?? []).map((r) => r.department_id),
    };
  });
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
