import { NextResponse, type NextRequest } from "next/server";
import { createServerClient, type CookieOptions } from "@supabase/ssr";

// Handles the redirect from a Supabase magic-link email: exchanges the code
// for a session, then sends the user into the app.
//
// Cookies are written directly onto the exact response object this handler
// returns (`response.cookies.set(...)`), rather than relying on the ambient
// next/headers `cookies()` store to auto-apply its mutations onto a
// manually-constructed NextResponse.redirect(). This is the more explicit,
// bulletproof pattern for auth callback route handlers specifically.
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");

  if (code) {
    const response = NextResponse.redirect(`${origin}/dashboard`);

    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        db: { schema: process.env.NEXT_PUBLIC_SUPABASE_SCHEMA || "public" },
        cookies: {
          getAll() {
            return request.cookies.getAll();
          },
          setAll(cookiesToSet: { name: string; value: string; options: CookieOptions }[]) {
            cookiesToSet.forEach(({ name, value, options }) => {
              response.cookies.set(name, value, options);
            });
          },
        },
      },
    );

    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return response;
    }

    console.error("auth/callback: exchangeCodeForSession failed", error.message);
  }

  return NextResponse.redirect(`${origin}/login?error=auth_callback_failed`);
}
