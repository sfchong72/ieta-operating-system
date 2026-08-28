"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { signOutAction } from "@/lib/actions/auth";
import type { CurrentUser } from "@/lib/data/access";

const NAV_ITEMS = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/planner", label: "Planner" },
  { href: "/sops", label: "SOPs" },
  { href: "/ideas", label: "Content Ideas" },
  { href: "/tasks", label: "Tasks" },
  { href: "/knowledge", label: "Knowledge Base" },
];

const ADMIN_ITEM = { href: "/admin/users", label: "Admin · Users" };

function NavLinks({
  onNavigate,
  isSuperAdmin,
}: {
  onNavigate?: () => void;
  isSuperAdmin: boolean;
}) {
  const pathname = usePathname();
  const items = isSuperAdmin ? [...NAV_ITEMS, ADMIN_ITEM] : NAV_ITEMS;
  return (
    <nav aria-label="Main" className="flex flex-col gap-1">
      {items.map((item) => {
        const active = pathname === item.href || pathname.startsWith(item.href + "/");
        return (
          <Link
            key={item.href}
            href={item.href}
            onClick={onNavigate}
            aria-current={active ? "page" : undefined}
            className={`rounded-md px-3 py-2 text-sm font-medium transition-colors ${
              active
                ? "bg-neutral-900 text-white"
                : "text-neutral-700 hover:bg-neutral-100"
            }`}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}

function UserBadge({ currentUser }: { currentUser: CurrentUser }) {
  return (
    <div className="mt-auto border-t border-neutral-200 pt-4 text-sm">
      <p className="font-medium">{currentUser.profile.full_name ?? currentUser.profile.email}</p>
      <p className="text-xs uppercase text-neutral-500">{currentUser.role ?? "no role"}</p>
      <form action={signOutAction}>
        <button
          type="submit"
          className="mt-2 text-xs text-neutral-500 underline hover:text-neutral-900"
        >
          Sign out
        </button>
      </form>
    </div>
  );
}

export function NavShell({
  children,
  currentUser,
}: {
  children: React.ReactNode;
  currentUser: CurrentUser;
}) {
  const [open, setOpen] = useState(false);
  const isSuperAdmin = currentUser.role === "super_admin";

  return (
    <div className="min-h-screen md:flex">
      {/* Desktop sidebar */}
      <aside className="hidden md:flex md:w-60 md:shrink-0 md:flex-col md:border-r md:border-neutral-200 md:p-4">
        <div className="mb-6 px-2">
          <p className="text-lg font-bold tracking-tight">IEOS</p>
          <p className="text-xs text-neutral-500">Inter Excel Operations System</p>
          <p className="mt-1 text-xs font-medium text-neutral-600">IETA — Marketing &amp; Social Media</p>
        </div>
        <NavLinks isSuperAdmin={isSuperAdmin} />
        <UserBadge currentUser={currentUser} />
      </aside>

      {/* Mobile top bar */}
      <div className="flex items-center justify-between border-b border-neutral-200 p-4 md:hidden">
        <p className="font-bold tracking-tight">IEOS</p>
        <button
          type="button"
          onClick={() => setOpen((o) => !o)}
          aria-expanded={open}
          aria-controls="mobile-nav"
          aria-label="Toggle navigation menu"
          className="rounded-md border border-neutral-300 p-2"
        >
          <span aria-hidden="true">{open ? "✕" : "☰"}</span>
        </button>
      </div>
      {open && (
        <div id="mobile-nav" className="border-b border-neutral-200 p-4 md:hidden">
          <NavLinks onNavigate={() => setOpen(false)} isSuperAdmin={isSuperAdmin} />
          <UserBadge currentUser={currentUser} />
        </div>
      )}

      <main className="min-w-0 flex-1 p-4 md:p-8">{children}</main>
    </div>
  );
}
