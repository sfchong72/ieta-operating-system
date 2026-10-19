"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { signOutAction } from "@/lib/actions/auth";
import type { CurrentUser } from "@/lib/data/access";

const PERSONAL_ITEMS = [
  { href: "/work", label: "My Work" },
  { href: "/daily-updates", label: "Daily Update" },
];

const RESOURCE_ITEMS = [
  { href: "/files", label: "File Register" },
  { href: "/planner", label: "Planner" },
  { href: "/sops", label: "SOPs" },
  { href: "/ideas", label: "Content Ideas" },
  { href: "/tasks", label: "Legacy Content Tasks" },
  { href: "/knowledge", label: "Knowledge Base" },
];

const APPROVALS_ITEM = { href: "/approvals", label: "My Approvals" };
const TEAM_WORK_ITEMS = [
  { href: "/work/team", label: "Team Tasks" },
  { href: "/work/new", label: "Create Task" },
  { href: "/work/attention", label: "Needs Attention" },
];
const ADMIN_ITEM = { href: "/admin/users", label: "Admin · Users" };

function NavLinks({
  onNavigate,
  isSuperAdmin,
  isApprover,
  canViewWorkDashboard,
  canAccessMarketingLeads,
}: {
  onNavigate?: () => void;
  isSuperAdmin: boolean;
  isApprover: boolean;
  canViewWorkDashboard: boolean;
  canAccessMarketingLeads: boolean;
}) {
  const pathname = usePathname();
  const groups = [
    {
      label: "Overview",
      items: [
        ...(canViewWorkDashboard ? [{ href: "/dashboard", label: "Dashboard" }] : []),
        ...PERSONAL_ITEMS,
      ],
    },
    ...(canAccessMarketingLeads
      ? [{
          label: "Marketing leads",
          items: [
            ...(isApprover ? [{ href: "/leads", label: "Lead Register" }] : []),
            { href: "/leads/my", label: "My Leads" },
            { href: "/leads/follow-up", label: "Follow-Up Due" },
            ...(isApprover ? [{ href: "/leads/campaigns", label: "Lead Campaigns" }] : []),
          ],
        }]
      : []),
    { label: "Resources", items: RESOURCE_ITEMS },
    ...(isApprover
      ? [{ label: "Team management", items: [...TEAM_WORK_ITEMS, APPROVALS_ITEM] }]
      : []),
    ...(isSuperAdmin ? [{ label: "Administration", items: [ADMIN_ITEM] }] : []),
  ];
  return (
    <nav aria-label="Main" className="space-y-5">
      {groups.map((group) => (
        <div key={group.label}>
          <p className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-[0.18em] text-slate-500">
            {group.label}
          </p>
          <div className="flex flex-col gap-1">
            {group.items.map((item) => {
              const inLeadRegister = item.href === "/leads" && !["/leads/my", "/leads/follow-up", "/leads/campaigns"].some((href) => pathname === href || pathname.startsWith(href + "/"));
              const active = pathname === item.href || (inLeadRegister && pathname.startsWith("/leads/")) || (!["/work", "/leads"].includes(item.href) && pathname.startsWith(item.href + "/"));
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={onNavigate}
                  aria-current={active ? "page" : undefined}
                  className={`rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
                    active
                      ? "bg-teal-400 text-slate-950 shadow-sm"
                      : "text-slate-300 hover:bg-white/10 hover:text-white"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </div>
        </div>
      ))}
    </nav>
  );
}

function UserBadge({ currentUser }: { currentUser: CurrentUser }) {
  return (
    <div className="mt-auto rounded-2xl border border-white/10 bg-white/5 p-3 text-sm text-white">
      <p className="font-semibold">{currentUser.profile.full_name ?? currentUser.profile.email}</p>
      <p className="mt-0.5 text-[11px] font-semibold uppercase tracking-wider text-teal-300">{currentUser.role ?? "no role"}</p>
      <form action={signOutAction}>
        <button
          type="submit"
          className="mt-3 text-xs text-slate-400 underline underline-offset-4 hover:text-white"
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
  const isApprover = currentUser.role === "super_admin" || currentUser.role === "management";

  return (
    <div className="min-h-screen md:flex">
      {/* Desktop sidebar */}
      <aside className="hidden bg-slate-950 md:sticky md:top-0 md:flex md:h-screen md:w-72 md:shrink-0 md:flex-col md:overflow-y-auto md:p-4">
        <div className="mb-6 flex items-center gap-3 px-2 py-2">
          <div className="grid size-10 shrink-0 place-items-center rounded-xl bg-teal-400 text-sm font-black text-slate-950 shadow-lg shadow-teal-950/20">IE</div>
          <div className="min-w-0">
            <p className="text-sm font-bold leading-tight tracking-tight text-white">Inter Excel Operating System</p>
            <p className="mt-0.5 text-xs text-slate-400">Internal operations workspace</p>
          </div>
        </div>
        <NavLinks isSuperAdmin={isSuperAdmin} isApprover={isApprover} canViewWorkDashboard={currentUser.canViewWorkDashboard} canAccessMarketingLeads={currentUser.canAccessMarketingLeads} />
        <div className="mt-6"><UserBadge currentUser={currentUser} /></div>
      </aside>

      {/* Mobile top bar */}
      <div className="sticky top-0 z-20 flex items-center justify-between border-b border-slate-800 bg-slate-950 px-4 py-3 text-white md:hidden">
        <div className="flex min-w-0 items-center gap-2.5"><span className="grid size-9 shrink-0 place-items-center rounded-lg bg-teal-400 text-xs font-black text-slate-950">IE</span><div className="min-w-0"><p className="text-sm font-bold leading-tight tracking-tight">Inter Excel Operating System</p><p className="mt-0.5 text-[10px] text-slate-400">Internal operations workspace</p></div></div>
        <button
          type="button"
          onClick={() => setOpen((o) => !o)}
          aria-expanded={open}
          aria-controls="mobile-nav"
          aria-label="Toggle navigation menu"
          className="rounded-lg border border-white/15 bg-white/5 px-3 py-2 text-white"
        >
          <span aria-hidden="true">{open ? "✕" : "☰"}</span>
        </button>
      </div>
      {open && (
        <div id="mobile-nav" className="border-b border-slate-800 bg-slate-950 p-4 md:hidden">
          <NavLinks onNavigate={() => setOpen(false)} isSuperAdmin={isSuperAdmin} isApprover={isApprover} canViewWorkDashboard={currentUser.canViewWorkDashboard} canAccessMarketingLeads={currentUser.canAccessMarketingLeads} />
          <UserBadge currentUser={currentUser} />
        </div>
      )}

      <main className="min-w-0 flex-1 px-4 py-6 sm:px-6 md:px-8 md:py-10 xl:px-10">{children}</main>
    </div>
  );
}
