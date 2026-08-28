"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { getCurrentUser } from "@/lib/data/access";
import type { Role } from "@/lib/data/types";

export type ActionState = { error?: string; success?: boolean };

export async function assignRoleAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const profile_id = String(formData.get("profile_id") ?? "");
  const role = String(formData.get("role") ?? "") as Role;
  if (!profile_id || !role) return { error: "Missing profile or role." };

  const supabase = await createClient();
  const { error } = await supabase
    .from("user_role_assignment")
    .upsert({ profile_id, role }, { onConflict: "profile_id,role" });

  if (error) return { error: error.message };
  revalidatePath("/admin/users");
  return { success: true };
}

export async function grantBusinessUnitAccessAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const profile_id = String(formData.get("profile_id") ?? "");
  const business_unit_id = String(formData.get("business_unit_id") ?? "");
  if (!profile_id || !business_unit_id) return { error: "Missing profile or business unit." };

  const supabase = await createClient();
  const { error } = await supabase
    .from("user_business_unit_access")
    .upsert(
      { profile_id, business_unit_id },
      { onConflict: "profile_id,business_unit_id" },
    );

  if (error) return { error: error.message };
  revalidatePath("/admin/users");
  return { success: true };
}

export async function grantDepartmentAccessAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const profile_id = String(formData.get("profile_id") ?? "");
  const department_id = String(formData.get("department_id") ?? "");
  if (!profile_id || !department_id) return { error: "Missing profile or department." };

  const supabase = await createClient();
  const { error } = await supabase
    .from("user_department_access")
    .upsert({ profile_id, department_id }, { onConflict: "profile_id,department_id" });

  if (error) return { error: error.message };
  revalidatePath("/admin/users");
  return { success: true };
}

/**
 * Inviting a brand-new user needs the Supabase Auth Admin API
 * (auth.admin.inviteUserByEmail), which requires the service-role key and
 * therefore BYPASSES RLS entirely. Because there is no RLS safety net on
 * this path, this action independently re-verifies the caller is a Super
 * Admin server-side before doing anything privileged — it never trusts that
 * only the Admin Users page (itself already role-gated) could have called
 * it. A server action is reachable by anyone who can craft the POST, not
 * just through the UI that happens to render its form.
 */
export async function inviteUserAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const email = String(formData.get("email") ?? "").trim();
  if (!email || !email.includes("@")) return { error: "Enter a valid email address." };

  // Independent server-side permission check — do not trust the caller.
  const currentUser = await getCurrentUser();
  if (!currentUser || currentUser.role !== "super_admin") {
    return { error: "Only Super Admin can invite users." };
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return {
      error:
        "Inviting new users needs SUPABASE_SERVICE_ROLE_KEY configured on the server " +
        "(not yet set). Ask a Super Admin to add the user directly in the Supabase " +
        "dashboard for now, or add the service role key to enable this form.",
    };
  }

  const admin = createAdminClient();
  const { error } = await admin.auth.admin.inviteUserByEmail(email, {
    redirectTo: `${process.env.NEXT_PUBLIC_APP_URL ?? ""}/auth/callback`,
  });

  // Never surface the raw Admin API response to the client — only a message.
  if (error) return { error: error.message };

  revalidatePath("/admin/users");
  return { success: true };
}
