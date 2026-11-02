import { redirect } from "next/navigation";
import { NavShell } from "@/components/nav-shell";
import { getCurrentUser } from "@/lib/data/access";
import { createClient } from "@/lib/supabase/server";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const currentUser = await getCurrentUser();
  if (!currentUser) {
    // A valid Supabase session is not the same as authorised IEOS access.
    // Keep an authenticated but not-yet-provisioned user out of protected
    // modules without sending them back into the magic-link flow.
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    redirect(user ? "/access-pending" : "/login");
  }

  return <NavShell currentUser={currentUser}>{children}</NavShell>;
}
