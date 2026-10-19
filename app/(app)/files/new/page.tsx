import { redirect } from "next/navigation";
import { MasterFileForm } from "@/components/master-files/master-file-form";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { listBusinessUnits } from "@/lib/data/business-units";
import { listDepartments } from "@/lib/data/departments";
import { listMasterFileCategories } from "@/lib/data/master-files";
import { listWorkAssignees, listWorkTasks } from "@/lib/data/work-management";

export default async function AddMasterFilePage() {
  const user = await getCurrentUser();
  if (!user || !["super_admin", "management"].includes(user.role ?? "")) redirect("/files");
  const [businessUnits, departments, categories, owners, tasks] = await Promise.all([
    listBusinessUnits(), listDepartments(), listMasterFileCategories(), listWorkAssignees(), listWorkTasks(),
  ]);
  return <div className="mx-auto max-w-5xl"><PageHeader title="Add File" description="Register the governed master link and ownership metadata. No file contents are copied into Inter Excel Operating System." /><MasterFileForm businessUnits={businessUnits} departments={departments} categories={categories} owners={owners} tasks={tasks} canSetPc={user.role === "super_admin"} /></div>;
}

