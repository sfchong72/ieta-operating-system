import { redirect } from "next/navigation";
import { MasterFileFiltersForm } from "@/components/master-files/master-file-filters";
import { MasterFileList } from "@/components/master-files/master-file-list";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { listMasterFileCategories, listMasterFileProjects, searchMasterFiles } from "@/lib/data/master-files";
import { listWorkAssignees } from "@/lib/data/work-management";
import type { MasterFileFilters } from "@/lib/master-files";

function first(value: string | string[] | undefined) { return Array.isArray(value) ? value[0] : value; }

export default async function FileReviewPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const [user, params] = await Promise.all([getCurrentUser(), searchParams]);
  if (!user || !["super_admin", "management"].includes(user.role ?? "")) redirect("/files");
  const filters: MasterFileFilters = {
    q: first(params.q), businessUnit: first(params.businessUnit), department: first(params.department),
    category: first(params.category), owner: first(params.owner), project: first(params.project),
    status: first(params.status), access: first(params.access), includeHistory: true, reviewOnly: true,
  };
  const [files, businessUnits, departments, categories, owners, projects] = await Promise.all([
    searchMasterFiles(filters), listBusinessUnits(), listDepartments(), listMasterFileCategories(), listWorkAssignees(), listMasterFileProjects(),
  ]);
  return <div className="mx-auto max-w-[1500px]">
    <PageHeader title="File Review / Cleanup" description="Exceptions only: missing links, possible duplicates, unresolved replacements and stale verification." />
    <MasterFileFiltersForm values={filters} businessUnits={businessUnits} departments={departments} categories={categories} owners={owners} projects={projects} reviewMode />
    <MasterFileList files={files} emptyText="No visible file-governance exceptions match these filters." />
  </div>;
}

