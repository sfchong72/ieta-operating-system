import { createBrowserClient } from "@supabase/ssr";

// Defaults to "public" (production). Only set NEXT_PUBLIC_SUPABASE_SCHEMA=staging
// in a local/staging-only env file — never in the production Vercel env.
const schema = process.env.NEXT_PUBLIC_SUPABASE_SCHEMA || "public";

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { db: { schema } },
  );
}
