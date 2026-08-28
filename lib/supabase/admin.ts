import "server-only";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";

/**
 * Service-role Supabase client. SERVER-ONLY — the `server-only` import above
 * makes any accidental import from a Client Component fail at build time,
 * not just at runtime. `SUPABASE_SERVICE_ROLE_KEY` has no `NEXT_PUBLIC_`
 * prefix, so Next.js never inlines it into a browser bundle. Never log this
 * client, never return its key or any of its raw responses to the browser —
 * every caller must shape its own return value.
 *
 * Use only for privileged Auth Admin API calls (inviteUserByEmail,
 * generateLink, listUsers) that the anon-key client cannot perform. Every
 * regular data read/write still goes through lib/supabase/server.ts under
 * normal RLS — this client bypasses RLS entirely, so callers must do their
 * own authorization check before using it (see lib/actions/admin.ts).
 */
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY is not configured on the server.");
  }
  return createSupabaseClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
