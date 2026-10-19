"use client";

import { useActionState } from "react";
import {
  sendMagicLinkAction,
  signInLocalUatAction,
  type ActionState,
} from "@/lib/actions/auth";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function LoginForm({ localUat = false }: { localUat?: boolean }) {
  const [state, formAction] = useActionState(
    localUat ? signInLocalUatAction : sendMagicLinkAction,
    initialState,
  );

  if (state.success) {
    return (
      <div className="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
        Check your email for a sign-in link.
      </div>
    );
  }

  return (
    <form action={formAction} className="space-y-4">
      <FormError message={state.error} />
      {localUat ? (
        <p className="rounded-md border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900">
          Disposable local UAT only. Production authentication is unchanged.
        </p>
      ) : null}
      <div>
        <label htmlFor="email" className="block text-sm font-medium">
          Work email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          autoFocus
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="you@interexcel.com"
        />
      </div>
      {localUat ? (
        <div>
          <label htmlFor="password" className="block text-sm font-medium">
            Synthetic password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            required
            autoComplete="current-password"
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
      ) : null}
      <SubmitButton pendingText={localUat ? "Signing in…" : "Sending…"} className="w-full rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-800 disabled:opacity-50">
        {localUat ? "Sign in to local UAT" : "Send magic link"}
      </SubmitButton>
    </form>
  );
}
