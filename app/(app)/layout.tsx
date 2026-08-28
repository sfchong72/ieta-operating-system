import { redirect } from "next/navigation";
import { NavShell } from "@/components/nav-shell";
import { getCurrentUser } from "@/lib/data/access";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const currentUser = await getCurrentUser();
  if (!currentUser) redirect("/login");

  return <NavShell currentUser={currentUser}>{children}</NavShell>;
}
