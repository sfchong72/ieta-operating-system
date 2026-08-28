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
};

/** The logged-in user's profile + role + access grants, or null if signed out. */
export async function getCurrentUser(): Promise<CurrentUser | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const [{ data: profile }, { data: roleRow }, { data: buAccess }, { data: deptAccess }] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", user.id).maybeSingle(),
      supabase.from("user_role_assignment").select("*").eq("profile_id", user.id).maybeSingle(),
      supabase.from("user_business_unit_access").select("*").eq("profile_id", user.id),
      supabase.from("user_department_access").select("*").eq("profile_id", user.id),
    ]);

  if (!profile) return null;

  return {
    profile,
    role: (roleRow?.role as Role) ?? null,
    businessUnitIds: (buAccess ?? []).map((r) => r.business_unit_id),
    departmentIds: (deptAccess ?? []).map((r) => r.department_id),
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
