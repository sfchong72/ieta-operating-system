// Rule-based "agentic layer" v1 — docs/AGENTIC_LAYER.md + docs/INTELLIGENCE_LAYER.md
// No external AI calls. Every function here is a named, typed, auditable tool.
import type { FileType, ContentTask } from "@/lib/data/types";

/** detect_file_type(url) -> drive | canva | other */
export function detectFileType(url: string): FileType {
  const u = url.toLowerCase();
  if (u.includes("drive.google.com") || u.includes("docs.google.com")) return "drive";
  if (u.includes("canva.com")) return "canva";
  return "other";
}

const PLATFORM_KEYWORDS: Record<string, string> = {
  instagram: "Instagram",
  insta: "Instagram",
  reel: "Instagram",
  tiktok: "TikTok",
  youtube: "YouTube",
  shorts: "YouTube",
  facebook: "Facebook",
  fb: "Facebook",
};

/** Best-effort platform guess from a title, for auto-filling new task/idea forms. */
export function detectPlatformFromTitle(title: string): string | null {
  const t = title.toLowerCase();
  for (const [kw, platform] of Object.entries(PLATFORM_KEYWORDS)) {
    if (t.includes(kw)) return platform;
  }
  return null;
}

export type PriorityResult = { score: number; reason: string };

/** compute_priority_score(task) -> 0-1 + reason, per docs/INTELLIGENCE_LAYER.md scoring rules */
export function computePriorityScore(
  task: Pick<ContentTask, "deadline" | "status" | "work_link" | "department_id" | "created_at">,
  marketingDepartmentId: string | null,
): PriorityResult {
  let score = 0;
  const reasons: string[] = [];

  if (task.deadline) {
    const days = Math.ceil(
      (new Date(task.deadline).getTime() - Date.now()) / (1000 * 60 * 60 * 24),
    );
    if (days <= 2 && task.status !== "submitted") {
      score += 0.4;
      reasons.push("deadline in ≤ 2 days");
    }
  }

  if (task.status === "submitted") {
    score += 0.3;
    reasons.push("awaiting approval");
  }

  if (!task.work_link && task.status === "in_progress") {
    score += 0.2;
    reasons.push("no work link attached");
  }

  if (marketingDepartmentId && task.department_id === marketingDepartmentId) {
    score += 0.1;
    reasons.push("Marketing department");
  }

  score = Math.min(1, Math.round(score * 100) / 100);
  return {
    score,
    reason: reasons.length ? reasons.join(" + ") : "no urgency signals",
  };
}

const TAG_KEYWORDS = [
  "onboarding",
  "welcome",
  "reel",
  "testimonial",
  "student",
  "launch",
  "poster",
  "announcement",
  "bts",
  "culture",
  "tips",
  "carousel",
  "educational",
  "promo",
  "greeting",
];

export type TagSuggestion = { tags: string[]; confidence: number };

/** suggest_tags(text) -> string[] + confidence, rule-based v1 (keyword match) */
export function suggestTags(text: string): TagSuggestion {
  const t = text.toLowerCase();
  const tags = TAG_KEYWORDS.filter((kw) => t.includes(kw));
  const confidence = tags.length === 0 ? 0.3 : Math.min(0.95, 0.5 + tags.length * 0.15);
  return { tags, confidence: Math.round(confidence * 100) / 100 };
}
