import { notFound } from "next/navigation";
import { getKnowledgeItem } from "@/lib/data/knowledge-items";
import { KnowledgeForm } from "@/components/knowledge-form";
import { PageHeader } from "@/components/ui";

export default async function EditKnowledgeItemPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const item = await getKnowledgeItem(id);
  if (!item) notFound();

  return (
    <div>
      <PageHeader title="Edit Knowledge Item" />
      <KnowledgeForm item={item} />
    </div>
  );
}
