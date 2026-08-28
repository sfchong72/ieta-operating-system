import type { PlatformPublication } from "@/lib/data/types";

const PLATFORM_LABELS: Record<string, string> = {
  instagram: "IG",
  facebook: "FB",
  tiktok: "TikTok",
  youtube_shorts: "YouTube",
  other: "Other",
};

const STATUS_STYLES: Record<string, string> = {
  published: "bg-emerald-100 text-emerald-700",
  scheduled: "bg-amber-100 text-amber-800",
  not_required: "bg-neutral-100 text-neutral-400",
};

const STATUS_LABELS: Record<string, string> = {
  published: "✓",
  scheduled: "Pending",
  not_required: "N/A",
};

/** Compact chip strip: IG ✓  FB ✓  TikTok Pending  YouTube N/A */
export function PlatformChips({ publications }: { publications: PlatformPublication[] }) {
  if (publications.length === 0) {
    return <span className="text-xs text-neutral-400">—</span>;
  }
  return (
    <div className="flex flex-wrap gap-1">
      {publications.map((p) => (
        <span
          key={p.id}
          title={p.published_url ?? undefined}
          className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${
            STATUS_STYLES[p.status] ?? STATUS_STYLES.scheduled
          }`}
        >
          {PLATFORM_LABELS[p.platform] ?? p.platform} {STATUS_LABELS[p.status] ?? p.status}
        </span>
      ))}
    </div>
  );
}

/** "2/3 Published" summary, counting required platforms only (excludes not_required). */
export function PublishingProgress({ publications }: { publications: PlatformPublication[] }) {
  const required = publications.filter((p) => p.status !== "not_required");
  const published = required.filter((p) => p.status === "published");
  if (required.length === 0) {
    return <span className="text-xs text-neutral-400">—</span>;
  }
  const complete = published.length === required.length;
  return (
    <span
      className={`text-sm font-medium ${complete ? "text-emerald-700" : "text-neutral-600"}`}
    >
      {published.length}/{required.length} Published
    </span>
  );
}
