import { listDepartments } from "@/lib/data/departments";
import { SopForm } from "@/components/sop-form";
import { PageHeader } from "@/components/ui";

export default async function NewSopPage() {
  const departments = await listDepartments();
  return (
    <div>
      <PageHeader title="New SOP" description="Add a standard procedure with its master file link." />
      <SopForm departments={departments} />
    </div>
  );
}
