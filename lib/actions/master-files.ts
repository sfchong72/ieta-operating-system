"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  MASTER_FILE_ACCESS_LEVELS,
  MASTER_FILE_SOURCE_SYSTEMS,
  MASTER_FILE_STATUSES,
  type MasterFileAccessLevel,
  type MasterFileSourceSystem,
} from "@/lib/master-files";

export type MasterFileActionState = { error?: string; success?: string };

function value(formData: FormData, name: string) {
  return String(formData.get(name) ?? "").trim();
}

function optional(formData: FormData, name: string) {
  return value(formData, name) || null;
}

function checked(formData: FormData, name: string) {
  return formData.get(name) === "on" || formData.get(name) === "true";
}

function safeMessage(error: unknown) {
  const message = error instanceof Error ? error.message : "The request could not be completed.";
  return message.replace(/https?:\/\/\S+/g, "[link hidden]").slice(0, 300);
}

function refresh(fileId?: string) {
  revalidatePath("/files");
  revalidatePath("/files/review");
  if (fileId) revalidatePath(`/files/${fileId}`);
}

function sharedRpcValues(formData: FormData) {
  const accessLevel = value(formData, "access_level") as MasterFileAccessLevel;
  const source = optional(formData, "source_system") as MasterFileSourceSystem | null;
  if (!MASTER_FILE_ACCESS_LEVELS.includes(accessLevel)) throw new Error("Choose a valid access level.");
  if (source && !MASTER_FILE_SOURCE_SYSTEMS.includes(source)) throw new Error("Choose a valid source system.");
  return {
    p_file_name: value(formData, "file_name"),
    p_business_unit_id: value(formData, "business_unit_id"),
    p_department_id: value(formData, "department_id"),
    p_category_slug: value(formData, "category_slug"),
    p_description: optional(formData, "description"),
    p_owner_profile_id: value(formData, "owner_profile_id"),
    p_access_level: accessLevel,
    p_master_url: optional(formData, "master_url"),
    p_folder_url: optional(formData, "folder_url"),
    p_source_system: source,
    p_project_reference: optional(formData, "project_reference"),
    p_password_reference: checked(formData, "password_reference"),
    p_remarks: optional(formData, "remarks"),
    p_data_handling_confirmed: checked(formData, "data_handling_confirmed"),
  };
}

export async function createMasterFileAction(
  _previous: MasterFileActionState,
  formData: FormData,
): Promise<MasterFileActionState> {
  try {
    const status = value(formData, "status");
    if (!MASTER_FILE_STATUSES.slice(0, 2).includes(status as "current" | "under_review")) {
      return { error: "New records must start as Current or Under Review." };
    }
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("create_master_file", {
      ...sharedRpcValues(formData),
      p_status: status,
      p_related_task_id: optional(formData, "related_task_id"),
    });
    if (error) throw error;
    refresh(String(data));
    redirect(`/files/${data}`);
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) throw error;
    return { error: safeMessage(error) };
  }
}

export async function updateMasterFileAction(
  _previous: MasterFileActionState,
  formData: FormData,
): Promise<MasterFileActionState> {
  const fileId = value(formData, "master_file_id");
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("update_master_file_metadata", {
      p_master_file_id: fileId,
      ...sharedRpcValues(formData),
    });
    if (error) throw error;
    refresh(fileId);
    redirect(`/files/${fileId}`);
  } catch (error) {
    if (error && typeof error === "object" && "digest" in error) throw error;
    return { error: safeMessage(error) };
  }
}

async function runFileRpc(
  fileId: string,
  rpc: string,
  args: Record<string, unknown>,
  success: string,
): Promise<MasterFileActionState> {
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc(rpc, args);
    if (error) throw error;
    refresh(fileId);
    return { success };
  } catch (error) {
    return { error: safeMessage(error) };
  }
}

export async function setMasterFileStatusAction(_previous: MasterFileActionState, formData: FormData) {
  const fileId = value(formData, "master_file_id");
  return runFileRpc(fileId, "set_master_file_status", {
    p_master_file_id: fileId,
    p_status: value(formData, "status"),
  }, "Status updated.");
}

export async function verifyMasterFileAction(_previous: MasterFileActionState, formData: FormData) {
  const fileId = value(formData, "master_file_id");
  return runFileRpc(fileId, "verify_master_file", { p_master_file_id: fileId }, "File record verified.");
}

export async function supersedeMasterFileAction(_previous: MasterFileActionState, formData: FormData) {
  const oldFileId = value(formData, "old_file_id");
  return runFileRpc(oldFileId, "supersede_master_file", {
    p_old_file_id: oldFileId,
    p_replacement_file_id: value(formData, "replacement_file_id"),
  }, "Replacement marked current and earlier record superseded.");
}

export async function markMasterFileDuplicateAction(_previous: MasterFileActionState, formData: FormData) {
  const duplicateFileId = value(formData, "duplicate_file_id");
  return runFileRpc(duplicateFileId, "mark_master_file_duplicate", {
    p_duplicate_file_id: duplicateFileId,
    p_canonical_file_id: value(formData, "canonical_file_id"),
  }, "Duplicate archived and linked to its canonical record.");
}

export async function grantMasterFileAccessAction(_previous: MasterFileActionState, formData: FormData) {
  const fileId = value(formData, "master_file_id");
  return runFileRpc(fileId, "grant_master_file_access", {
    p_master_file_id: fileId,
    p_profile_id: value(formData, "profile_id"),
    p_grant_type: value(formData, "grant_type"),
  }, "Access granted.");
}

export async function revokeMasterFileAccessAction(_previous: MasterFileActionState, formData: FormData) {
  const fileId = value(formData, "master_file_id");
  return runFileRpc(fileId, "revoke_master_file_access", {
    p_master_file_id: fileId,
    p_profile_id: value(formData, "profile_id"),
    p_grant_type: value(formData, "grant_type"),
  }, "Explicit access revoked.");
}

export async function linkMasterFileTaskAction(_previous: MasterFileActionState, formData: FormData) {
  const fileId = value(formData, "master_file_id");
  return runFileRpc(fileId, "link_master_file_task", {
    p_master_file_id: fileId,
    p_task_id: value(formData, "task_id"),
  }, "Task linked.");
}

export async function linkMasterFileArtifactAction(_previous: MasterFileActionState, formData: FormData) {
  const fileId = value(formData, "master_file_id");
  return runFileRpc(fileId, "link_master_file_artifact", {
    p_master_file_id: fileId,
    p_task_artifact_id: value(formData, "task_artifact_id"),
  }, "Task artifact linked.");
}
