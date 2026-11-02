import { LoginForm } from "@/components/login-form";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/data/access";
import { createClient } from "@/lib/supabase/server";

export default async function LoginPage() {
  const localUat = process.env.IEOS_LOCAL_UAT === "1";

  if (!localUat) {
    const currentUser = await getCurrentUser();
    if (currentUser) redirect("/dashboard");

    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (user) redirect("/access-pending");
  }

  return (
    <main className="flex min-h-screen items-center justify-center p-8">
      <div className="w-full max-w-sm">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold tracking-tight">Inter Excel Operating System</h1>
          <p className="mt-1 text-xs text-neutral-400">IETA — Marketing &amp; Social Media</p>
        </div>
        <LoginForm localUat={localUat} />
      </div>
    </main>
  );
}
