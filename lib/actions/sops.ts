"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createSop, updateSop, deleteSop as deleteSopRow } from "@/lib/data/sops";

export type ActionState = { error?: string; success?: boolean };

export async function createSopAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const title = String(formData.get("title") ?? "").trim();
  const department_id = String(formData.get("department_id") ?? "") || null;
  const master_drive_link = String(formData.get("master_drive_link") ?? "").trim() || null;
  const version = String(formData.get("version") ?? "").trim() || "v1";
  const content = String(formData.get("content") ?? "").trim() || null;

  if (!title) return { error: "SOP title is required." };
  if (master_drive_link) {
    try {
      new URL(master_drive_link);
    } catch {
      return { error: "Please enter a valid URL for the master Drive link." };
    }
  }

  const sop = await createSop({ title, department_id, master_drive_link, version, content });
  revalidatePath("/sops");
  redirect(`/sops/${sop.id}`);
}

export async function updateSopAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const department_id = String(formData.get("department_id") ?? "") || null;
  const master_drive_link = String(formData.get("master_drive_link") ?? "").trim() || null;
  const version = String(formData.get("version") ?? "").trim() || "v1";
  const content = String(formData.get("content") ?? "").trim() || null;

  if (!id) return { error: "Missing SOP." };
  if (!title) return { error: "SOP title is required." };
  if (master_drive_link) {
    try {
      new URL(master_drive_link);
    } catch {
      return { error: "Please enter a valid URL for the master Drive link." };
    }
  }

  await updateSop(id, { title, department_id, master_drive_link, version, content });
  revalidatePath("/sops");
  revalidatePath(`/sops/${id}`);
  redirect(`/sops/${id}`);
}

export async function deleteSopAction(formData: FormData): Promise<void> {
  const id = String(formData.get("id") ?? "");
  if (!id) return;
  await deleteSopRow(id);
  revalidatePath("/sops");
  redirect("/sops");
}
