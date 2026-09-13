import Link from "next/link";
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

export default async function FileRegisterPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const [user, params] = await Promise.all([getCurrentUser(), searchParams]);
  if (!user) return null;
  const canManage = ["super_admin", "management"].includes(user.role ?? "");
  const filters: MasterFileFilters = {
    q: first(params.q),
    businessUnit: first(params.businessUnit),
    department: first(params.department),
    category: first(params.category),
    owner: first(params.owner),
    project: first(params.project),
    status: first(params.status),
    access: first(params.access),
    includeHistory: first(params.history) === "1",
  };
  const [files, businessUnits, departments, categories, owners, projects] = await Promise.all([
    searchMasterFiles(filters),
    listBusinessUnits(),
    listDepartments(),
    listMasterFileCategories(),
    canManage ? listWorkAssignees() : Promise.resolve([]),
    listMasterFileProjects(),
  ]);
  return <div className="mx-auto max-w-[1500px]">
    <PageHeader title="File Register" description="Find the governed current master, its owner, scope and external link." action={<div className="flex gap-2">{canManage && <Link href="/files/review" className="rounded-md border border-neutral-300 px-3 py-2 text-sm font-medium">Review / cleanup</Link>}{canManage && <Link href="/files/new" className="rounded-md bg-neutral-900 px-3 py-2 text-sm font-medium text-white">Add file</Link>}</div>} />
    <div className="mb-4 rounded-md border border-blue-200 bg-blue-50 p-3 text-sm text-blue-950">IEOS stores governed metadata and links only. Google Drive, Canva and other provider contents and permissions remain in their source systems.</div>
    <MasterFileFiltersForm values={filters} businessUnits={businessUnits} departments={departments} categories={categories} owners={owners} projects={projects} />
    <p className="mb-3 text-sm text-neutral-500">{files.length} visible record{files.length === 1 ? "" : "s"}. Current files are shown first.</p>
    <MasterFileList files={files} emptyText="No permitted file records match these filters." />
  </div>;
}

