import { notFound } from "next/navigation";
import { getIdea } from "@/lib/data/content-ideas";
import { IdeaForm } from "@/components/idea-form";
import { PageHeader } from "@/components/ui";

export default async function EditIdeaPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const idea = await getIdea(id);
  if (!idea) notFound();

  return (
    <div>
      <PageHeader title="Edit Idea" />
      <IdeaForm idea={idea} />
    </div>
  );
}
