"use server";

import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export type ActionState = { error?: string; success?: boolean };

export async function sendMagicLinkAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const email = String(formData.get("email") ?? "").trim();
  if (!email || !email.includes("@")) {
    return { error: "Enter a valid email address." };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL ?? ""}/auth/callback`,
    },
  });

  if (error) {
    return { error: error.message };
  }
  return { success: true };
}

export async function signInLocalUatAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const endpoint = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
  const isLoopback = /^http:\/\/(127\.0\.0\.1|localhost|\[::1\]):\d+\/?$/.test(endpoint);
  if (process.env.IEOS_LOCAL_UAT !== "1" || process.env.NODE_ENV === "production" || !isLoopback) {
    return { error: "Local UAT sign-in is disabled." };
  }

  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");
  const allowedAccounts = new Set([
    "director@stage1.ieos.test",
    "manager@stage1.ieos.test",
    "intern@stage1.ieos.test",
    "staff@stage1.ieos.test",
    "inactive@stage1.ieos.test",
  ]);
  if (!allowedAccounts.has(email) || !password) {
    return { error: "Use one of the approved synthetic UAT accounts." };
  }

  const supabase = await createClient();
  const { data: signInData, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    return { error: "Synthetic UAT sign-in failed." };
  }

  const { data: profile, error: profileError } = await supabase
    .from("profiles").select("is_active").eq("id", signInData.user.id).maybeSingle();
  if (profileError || profile?.is_active !== true) {
    await supabase.auth.signOut();
    return { error: "This account is inactive or has no application access." };
  }

  redirect("/work");
}

export async function signOutAction(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
}
