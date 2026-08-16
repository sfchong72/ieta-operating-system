import { notFound } from "next/navigation";
import { getSop } from "@/lib/data/sops";
import { listDepartments } from "@/lib/data/departments";
import { SopForm } from "@/components/sop-form";
import { PageHeader } from "@/components/ui";

export default async function EditSopPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [sop, departments] = await Promise.all([getSop(id), listDepartments()]);
  if (!sop) notFound();

  return (
    <div>
      <PageHeader title="Edit SOP" />
      <SopForm departments={departments} sop={sop} />
    </div>
  );
}
