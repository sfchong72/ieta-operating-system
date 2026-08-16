"use client";

import { useEffect } from "react";

export default function AppError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-[50vh] items-center justify-center p-8">
      <div className="max-w-sm rounded-lg border border-red-200 bg-red-50 p-6 text-center">
        <p className="text-sm font-medium text-red-800">
          Could not save — check connection and try again.
        </p>
        <button
          type="button"
          onClick={() => reset()}
          className="mt-4 rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800"
        >
          Retry
        </button>
      </div>
    </div>
  );
}
