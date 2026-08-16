import { IdeaForm } from "@/components/idea-form";
import { PageHeader } from "@/components/ui";

export default function NewIdeaPage() {
  return (
    <div>
      <PageHeader title="New Content Idea" description="Add an idea to the pipeline." />
      <IdeaForm />
    </div>
  );
}
