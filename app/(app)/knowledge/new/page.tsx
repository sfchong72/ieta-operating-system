import { KnowledgeForm } from "@/components/knowledge-form";
import { PageHeader } from "@/components/ui";

export default function NewKnowledgeItemPage() {
  return (
    <div>
      <PageHeader title="New Knowledge Item" description="Add a reusable reference entry." />
      <KnowledgeForm />
    </div>
  );
}
