import Link from "next/link";
import { listSops } from "@/lib/data/sops";
import { listDepartments } from "@/lib/data/departments";
import { PageHeader, EmptyState } from "@/components/ui";

export default async function SopsPage() {
  const [sops, departments] = await Promise.all([listSops(), listDepartments()]);
  const deptById = new Map(departments.map((d) => [d.id, d.name]));

  return (
    <div>
      <PageHeader title="SOPs" description="Standard procedures, grouped by department." />
      {sops.length === 0 ? (
        <EmptyState title="No SOPs yet — add your first procedure" />
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2">
          {sops.map((sop) => (
            <li key={sop.id} className="rounded-lg border border-neutral-200 p-4">
              <Link href={`/sops/${sop.id}`} className="font-medium hover:underline">
                {sop.title}
              </Link>
              <p className="mt-1 text-xs text-neutral-500">
                {sop.department_id ? deptById.get(sop.department_id) : "No department"} ·{" "}
                {sop.version}
              </p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
