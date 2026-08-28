// Shared row types for lib/data — mirrors docs/DATA_MODEL.md and supabase/migrations/0001_init.sql

export type Department = {
  id: string;
  name: string;
  slug: string | null;
  created_at: string;
  user_id: string | null;
  business_unit_id?: string | null;
};

export type Sop = {
  id: string;
  title: string;
  department_id: string | null;
  master_drive_link: string | null;
  version: string | null;
  content: string | null;
  created_at: string;
  user_id: string | null;
};

export type IdeaStatus = "idea" | "selected" | "tasked" | "archived";

export type ContentIdea = {
  id: string;
  title: string;
  platform: string | null;
  topic: string | null;
  status: IdeaStatus;
  suggested_tags: string | null;
  tags_source: string | null;
  tags_confidence: number | null;
  tags_review_status: string | null;
  created_at: string;
  user_id: string | null;
};

export type TaskStatus =
  | "assigned"
  | "in_progress"
  | "submitted"
  | "approved"
  | "amendment"
  | "posted";

export type ApprovalStatus = "pending" | "approved" | "amend" | null;

export type ContentTask = {
  id: string;
  idea_id: string | null;
  title: string;
  department_id: string | null;
  pic_name: string;
  platform: string | null;
  deadline: string | null;
  status: TaskStatus;
  work_link: string | null;
  approval_status: ApprovalStatus;
  approval_remarks: string | null;
  posted_url: string | null;
  posted_date: string | null;
  remarks: string | null;
  priority_score: number | null;
  priority_source: string | null;
  priority_confidence: number | null;
  priority_review_status: string | null;
  created_at: string;
  user_id: string | null;
};

export type FileType = "drive" | "canva" | "other";

export type WorkFile = {
  id: string;
  task_id: string;
  label: string | null;
  url: string;
  file_type: FileType | null;
  created_at: string;
  user_id: string | null;
};

export type KnowledgeItem = {
  id: string;
  title: string;
  category: string | null;
  body: string | null;
  tags: string[] | null;
  created_at: string;
  user_id: string | null;
};

export type ActivityAction =
  | "created"
  | "status_changed"
  | "link_attached"
  | "approved"
  | "amended"
  | "posted"
  | "deleted";

export type Activity = {
  id: string;
  task_id: string;
  action: ActivityAction;
  actor_name: string | null;
  detail: string | null;
  created_at: string;
  user_id: string | null;
};

// ── Milestone 1: Organisation / Business Unit / Team ────────────────────────

export type Organisation = {
  id: string;
  name: string;
  slug: string | null;
  created_at: string;
};

export type BusinessUnit = {
  id: string;
  organisation_id: string | null;
  name: string;
  slug: string | null;
  is_active: boolean;
  created_at: string;
};

export type Team = {
  id: string;
  department_id: string | null;
  name: string;
  created_at: string;
};

// ── Milestone 2: Auth / access model ────────────────────────────────────────

export type Role = "super_admin" | "management" | "staff" | "intern";

// ── Milestone 3: Content Core ───────────────────────────────────────────────

export type CampaignStatus = "active" | "completed" | "archived";

export type Campaign = {
  id: string;
  business_unit_id: string | null;
  department_id: string | null;
  name: string;
  description: string | null;
  status: CampaignStatus;
  start_date: string | null;
  end_date: string | null;
  user_id: string | null;
  created_at: string;
};

export type ContentItemStatus =
  | "draft"
  | "in_progress"
  | "awaiting_approval"
  | "revision_required"
  | "approved"
  | "scheduled_publishing"
  | "published"
  | "archived";

export type ContentItemApprovalStatus = "pending" | "approved" | "amend" | null;
export type ContentPriority = "low" | "medium" | "high" | null;

export type ContentItem = {
  id: string;
  business_unit_id: string | null;
  department_id: string | null;
  campaign_id: string | null;
  title: string;
  content_type: string | null;
  language: string | null;
  target_audience: string | null;
  priority: ContentPriority;
  pic_name: string | null;
  due_date: string | null;
  status: ContentItemStatus;
  approval_status: ContentItemApprovalStatus;
  approval_remarks: string | null;
  on_screen_wording: string | null;
  main_caption: string | null;
  cta: string | null;
  hashtags: string | null;
  media_drive_link: string | null;
  canva_link: string | null;
  final_artwork_link: string | null;
  suggested_tags: string | null;
  tags_source: string | null;
  tags_confidence: number | null;
  tags_review_status: string | null;
  priority_score: number | null;
  priority_source: string | null;
  priority_confidence: number | null;
  priority_review_status: string | null;
  remarks: string | null;
  user_id: string | null;
  created_at: string;
};

export type Platform = "instagram" | "facebook" | "tiktok" | "youtube_shorts" | "other";
export type PlatformPublicationStatus = "not_required" | "scheduled" | "published";

export type PlatformPublication = {
  id: string;
  content_item_id: string;
  platform: Platform;
  status: PlatformPublicationStatus;
  intended_date: string | null;
  published_at: string | null;
  published_url: string | null;
  published_by: string | null;
  caption_override: string | null;
  media_override_link: string | null;
  user_id: string | null;
  created_at: string;
};

export type Profile = {
  id: string;
  email: string;
  full_name: string | null;
  created_at: string;
};

export type UserRoleAssignment = {
  id: string;
  profile_id: string;
  role: Role;
  created_at: string;
};

export type UserBusinessUnitAccess = {
  id: string;
  profile_id: string;
  business_unit_id: string;
  created_at: string;
};

export type UserDepartmentAccess = {
  id: string;
  profile_id: string;
  department_id: string;
  created_at: string;
};
