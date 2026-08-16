import Link from "next/link";
import type { TaskStatus } from "@/lib/data/types";

const STATUS_STYLES: Record<TaskStatus, string> = {
  assigned: "bg-neutral-100 text-neutral-700",
  in_progress: "bg-blue-100 text-blue-700",
  submitted: "bg-amber-100 text-amber-800",
  approved: "bg-emerald-100 text-emerald-700",
  amendment: "bg-orange-100 text-orange-800",
  posted: "bg-purple-100 text-purple-700",
};

export function StatusBadge({ status }: { status: TaskStatus }) {
  return (
    <span
      className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${STATUS_STYLES[status]}`}
    >
      {status.replace("_", " ")}
    </span>
  );
}

export function FormError({ message }: { message?: string }) {
  if (!message) return null;
  return (
    <p role="alert" className="text-sm font-medium text-red-600">
      {message}
    </p>
  );
}

export function EmptyState({
  title,
  cta,
  href,
}: {
  title: string;
  cta?: string;
  href?: string;
}) {
  return (
    <div className="rounded-lg border border-dashed border-neutral-300 p-10 text-center">
      <p className="text-sm text-neutral-500">{title}</p>
      {cta && href && (
        <Link
          href={href}
          className="mt-4 inline-block rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800"
        >
          {cta}
        </Link>
      )}
    </div>
  );
}

export function PageHeader({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{title}</h1>
        {description && <p className="mt-1 text-sm text-neutral-500">{description}</p>}
      </div>
      {action}
    </div>
  );
}
