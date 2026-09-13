export const MASTER_FILE_ACCESS_LEVELS = [
  "operational",
  "appointed_personnel",
  "full_time_only",
  "management_only",
  "pc_restricted",
] as const;

export const MASTER_FILE_STATUSES = [
  "current",
  "under_review",
  "superseded",
  "archived",
] as const;

export const MASTER_FILE_SOURCE_SYSTEMS = [
  "google_drive",
  "google_docs",
  "google_sheets",
  "google_slides",
  "canva",
  "notion",
  "website",
  "other_url",
] as const;

export type MasterFileAccessLevel = (typeof MASTER_FILE_ACCESS_LEVELS)[number];
export type MasterFileStatus = (typeof MASTER_FILE_STATUSES)[number];
export type MasterFileSourceSystem = (typeof MASTER_FILE_SOURCE_SYSTEMS)[number];

export type MasterFileCategory = {
  slug: string;
  label: string;
  sort_order: number;
  is_active: boolean;
};

export type MasterFile = {
  id: string;
  file_number: string;
  file_name: string;
  business_unit_id: string;
  department_id: string;
  project_reference: string | null;
  category_slug: string;
  description: string | null;
  owner_profile_id: string;
  access_level: MasterFileAccessLevel;
  status: MasterFileStatus;
  master_url: string | null;
  folder_url: string | null;
  source_system: MasterFileSourceSystem;
  supersedes_file_id: string | null;
  duplicate_of_file_id: string | null;
  password_reference: boolean;
  created_by: string;
  created_at: string;
  updated_at: string;
  last_verified_at: string | null;
  archive_date: string | null;
  remarks: string | null;
  row_version: number;
};

export type MasterFileSearchRow = Pick<
  MasterFile,
  | "id"
  | "file_number"
  | "file_name"
  | "business_unit_id"
  | "department_id"
  | "category_slug"
  | "owner_profile_id"
  | "access_level"
  | "status"
  | "master_url"
  | "folder_url"
  | "source_system"
  | "project_reference"
  | "last_verified_at"
  | "updated_at"
> & {
  business_unit_name: string;
  department_name: string;
  category_label: string;
  owner_name: string;
  review_flags: string[];
};

export type MasterFileAuditEvent = {
  event_id: number;
  event_type: string;
  actor_id: string;
  actor_name: string;
  metadata: Record<string, unknown>;
  created_at: string;
};

export type MasterFileTaskLink = {
  task_id: string;
  task_number: string;
  task_title: string;
};

export type MasterFileArtifactLink = {
  task_artifact_id: string;
  label: string | null;
  artifact_type: string;
  artifact_sensitivity: string;
  url: string;
};

export type MasterFileAccessGrant = {
  profile_id: string;
  grant_type: "appointed_personnel" | "pc_restricted";
  grant_reason: "owner" | "explicit";
  created_at: string;
};

export type MasterFileFilters = {
  q?: string;
  businessUnit?: string;
  department?: string;
  category?: string;
  owner?: string;
  project?: string;
  status?: string;
  access?: string;
  includeHistory?: boolean;
  reviewOnly?: boolean;
};

export function humaniseMasterFile(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (character) => character.toUpperCase());
}

