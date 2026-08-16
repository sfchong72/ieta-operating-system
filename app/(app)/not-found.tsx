import Link from "next/link";

export default function AppNotFound() {
  return (
    <div className="flex min-h-[50vh] items-center justify-center p-8">
      <div className="max-w-sm text-center">
        <p className="text-lg font-semibold">Not found</p>
        <p className="mt-1 text-sm text-neutral-500">
          This item doesn&apos;t exist or may have been deleted.
        </p>
        <Link
          href="/dashboard"
          className="mt-4 inline-block rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800"
        >
          Back to Dashboard
        </Link>
      </div>
    </div>
  );
}
