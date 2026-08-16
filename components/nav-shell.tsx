"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";

const NAV_ITEMS = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/sops", label: "SOPs" },
  { href: "/ideas", label: "Content Ideas" },
  { href: "/tasks", label: "Tasks" },
  { href: "/knowledge", label: "Knowledge Base" },
];

function NavLinks({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  return (
    <nav aria-label="Main" className="flex flex-col gap-1">
      {NAV_ITEMS.map((item) => {
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

export function NavShell({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="min-h-screen md:flex">
      {/* Desktop sidebar */}
      <aside className="hidden md:flex md:w-60 md:shrink-0 md:flex-col md:border-r md:border-neutral-200 md:p-4">
        <div className="mb-6 px-2">
          <p className="text-lg font-bold tracking-tight">IE Operating System</p>
          <p className="text-xs text-neutral-500">IETA content &amp; ops</p>
        </div>
        <NavLinks />
      </aside>

      {/* Mobile top bar */}
      <div className="flex items-center justify-between border-b border-neutral-200 p-4 md:hidden">
        <p className="font-bold tracking-tight">IE Operating System</p>
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
          <NavLinks onNavigate={() => setOpen(false)} />
        </div>
      )}

      <main className="min-w-0 flex-1 p-4 md:p-8">{children}</main>
    </div>
  );
}
