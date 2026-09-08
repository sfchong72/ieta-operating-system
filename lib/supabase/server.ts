import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { cookies } from "next/headers";
import { fetchWithJwtClockSkewRetry } from "./retry";

// Defaults to "public" (production). Only set NEXT_PUBLIC_SUPABASE_SCHEMA=staging
// in a local/staging-only env file — never in the production Vercel env.
const schema = process.env.NEXT_PUBLIC_SUPABASE_SCHEMA || "public";

type CookieToSet = {
  name: string;
  value: string;
  options: CookieOptions;
};

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      db: { schema },
      global: { fetch: fetchWithJwtClockSkewRetry },
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
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
