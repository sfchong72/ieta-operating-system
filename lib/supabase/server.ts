import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// Defaults to "public" (production). Only set NEXT_PUBLIC_SUPABASE_SCHEMA=staging
// in a local/staging-only env file — never in the production Vercel env.
const schema = process.env.NEXT_PUBLIC_SUPABASE_SCHEMA || "public";

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      db: { schema },
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Server Components can't set cookies; middleware handles session refresh
          }
        },
      },
    },
  );
}
