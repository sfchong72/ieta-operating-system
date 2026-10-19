"use client";

import { useEffect } from "react";
import { signOutAction } from "@/lib/actions/auth";

export default function AppError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const sessionError = /PGRST303|JWT issued at future|JWT expired/i.test(error.message);
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-[50vh] items-center justify-center p-8">
      <div className="max-w-sm rounded-lg border border-red-200 bg-red-50 p-6 text-center">
        <p className="text-base font-semibold text-red-900">{sessionError ? "Your local test session needs to be refreshed." : "This page could not be loaded."}</p>
        <p className="mt-2 text-sm text-red-800">{sessionError ? "Sign in again, then retry the change. Your form was not submitted from this error screen." : "Retry the page. If the issue continues, sign out and start a fresh test session."}</p>
        <button
          type="button"
          onClick={() => reset()}
          className="mt-4 rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800"
        >
          Retry
        </button>
        <form action={signOutAction} className="mt-3">
          <button type="submit" className="text-sm font-medium text-red-800 underline underline-offset-4">Sign in again</button>
        </form>
      </div>
    </div>
  );
}
