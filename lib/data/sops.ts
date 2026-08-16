import { createClient } from "@/lib/supabase/server";
import type { Sop } from "./types";

export async function listSops(): Promise<Sop[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("sops")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function getSop(id: string): Promise<Sop | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("sops")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function listSopsByDepartment(departmentId: string): Promise<Sop[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("sops")
    .select("*")
    .eq("department_id", departmentId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export type SopInput = {
  title: string;
  department_id: string | null;
  master_drive_link: string | null;
  version: string | null;
  content: string | null;
};

export async function createSop(input: SopInput): Promise<Sop> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("sops")
    .insert(input)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function updateSop(id: string, input: Partial<SopInput>): Promise<Sop> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("sops")
    .update(input)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data;
}

export async function deleteSop(id: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase.from("sops").delete().eq("id", id);
  if (error) throw error;
}
