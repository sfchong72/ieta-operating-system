import { createClient } from "@/lib/supabase/server";

export type RecordEditLogEntry = {
  id: string;
  table_name: "sops" | "content_ideas" | "knowledge_items";
  record_id: string;
  actor_id: string | null;
  summary: string;
  created_at: string;
  actor: { full_name: string | null; email: string } | null;
};

/** Generic edit audit trail for tables without their own activity table (sops, content_ideas, knowledge_items). */
export async function listRecordEditLog(
  tableName: RecordEditLogEntry["table_name"],
  recordId: string,
): Promise<RecordEditLogEntry[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("record_edit_log")
    .select("*, actor:profiles(full_name, email)")
    .eq("table_name", tableName)
    .eq("record_id", recordId)
    .order("created_at", { ascending: true });
  if (error) throw error;
  return (data ?? []) as unknown as RecordEditLogEntry[];
}
