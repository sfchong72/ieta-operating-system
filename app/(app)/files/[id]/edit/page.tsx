import { notFound, redirect } from "next/navigation";
import { MasterFileForm } from "@/components/master-files/master-file-form";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { canManageMasterFile, getMasterFile, listMasterFileCategories } from "@/lib/data/master-files";
import { listWorkAssignees } from "@/lib/data/work-management";

export default async function EditMasterFilePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const [user, file, canManage] = await Promise.all([getCurrentUser(), getMasterFile(id), canManageMasterFile(id)]);
  if (!file) notFound();
  if (!user || !canManage) redirect(`/files/${id}`);
  const [businessUnits, departments, categories, owners] = await Promise.all([listBusinessUnits(), listDepartments(), listMasterFileCategories(), listWorkAssignees()]);
  return <div className="mx-auto max-w-5xl"><PageHeader title={`Edit ${file.file_number}`} description="Update governed metadata. Use File Detail for status, supersede, duplicate and access actions." /><MasterFileForm file={file} businessUnits={businessUnits} departments={departments} categories={categories} owners={owners} tasks={[]} canSetPc={user.role === "super_admin"} /></div>;
}

