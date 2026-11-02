import { redirect } from "next/navigation";
import { signOutAction } from "@/lib/actions/auth";
import { getCurrentUser } from "@/lib/data/access";
import { createClient } from "@/lib/supabase/server";

export default async function AccessPendingPage() {
  const currentUser = await getCurrentUser();
  if (currentUser) redirect("/dashboard");

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return (
    <main className="flex min-h-screen items-center justify-center p-8">
      <div className="w-full max-w-md rounded-lg border border-neutral-200 bg-white p-6 shadow-sm">
        <h1 className="text-xl font-semibold">Sign-in successful</h1>
        <p className="mt-3 text-sm leading-6 text-neutral-600">
          Your IEOS account has not yet been assigned an application role and authorised company
          access. Please ask a Super Admin to complete your access setup.
        </p>
        <p className="mt-3 text-xs text-neutral-500">
          You do not need to request another magic link.
        </p>
        <form action={signOutAction} className="mt-6">
          <button
            type="submit"
            className="rounded-md border border-neutral-300 px-4 py-2 text-sm font-medium hover:bg-neutral-50"
          >
            Sign out
          </button>
        </form>
      </div>
    </main>
  );
}
