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
  if (process.env.IEOS_LOCAL_UAT !== "1") {
    return { error: "Local UAT sign-in is disabled." };
  }

  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");
  const allowedAccounts = new Set([
    "director@stage1.ieos.test",
    "manager@stage1.ieos.test",
    "intern@stage1.ieos.test",
  ]);
  if (!allowedAccounts.has(email) || !password) {
    return { error: "Use one of the approved synthetic UAT accounts." };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    return { error: "Synthetic UAT sign-in failed." };
  }

  redirect("/work");
}

export async function signOutAction(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
}
