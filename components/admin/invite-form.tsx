"use client";

import { useActionState } from "react";
import { inviteUserAction, type ActionState } from "@/lib/actions/admin";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";

const initialState: ActionState = {};

export function InviteForm() {
  const [state, formAction] = useActionState(inviteUserAction, initialState);
  return (
    <form action={formAction} className="flex max-w-md items-start gap-2">
      <div className="flex-1">
        <input
          name="email"
          type="email"
          required
          placeholder="new.staff@interexcel.com"
          className="w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
        <FormError message={state.error} />
      </div>
      <SubmitButton pendingText="Inviting…">Invite</SubmitButton>
    </form>
  );
}
