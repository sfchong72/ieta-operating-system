import { KnowledgeForm } from "@/components/knowledge-form";
import { PageHeader } from "@/components/ui";
import { getCurrentUser } from "@/lib/data/access";
import { redirect } from "next/navigation";

export default async function NewKnowledgeItemPage() {
  if ((await getCurrentUser())?.role !== "super_admin") redirect("/knowledge");
  return (
    <div>
      <PageHeader title="New Knowledge Item" description="Add a reusable reference entry." />
      <KnowledgeForm />
    </div>
  );
}
