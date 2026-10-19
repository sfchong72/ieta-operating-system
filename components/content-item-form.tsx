"use client";

import { useActionState } from "react";
import {
  createContentItemAction,
  updateContentItemAction,
  type ActionState,
} from "@/lib/actions/content-items";
import { SubmitButton } from "@/components/submit-button";
import { FormError } from "@/components/ui";
import type { BusinessUnit, Department, Campaign, ApprovalCategory } from "@/lib/data/types";
import type { ContentItemWithPublications } from "@/lib/data/content-items";

const PLATFORMS: { value: string; label: string }[] = [
  { value: "instagram", label: "Instagram" },
  { value: "facebook", label: "Facebook" },
  { value: "tiktok", label: "TikTok" },
  { value: "youtube_shorts", label: "YouTube Shorts" },
  { value: "other", label: "Other" },
];

const PRIORITIES = ["low", "medium", "high"];

const initialState: ActionState = {};

export function ContentItemForm({
  businessUnits,
  departments,
  campaigns,
  approvalCategories,
  item,
}: {
  businessUnits: BusinessUnit[];
  departments: Department[];
  campaigns: Campaign[];
  approvalCategories: ApprovalCategory[];
  /** When provided, the form edits this content item instead of creating a new one. */
  item?: ContentItemWithPublications;
}) {
  const isEdit = Boolean(item);
  const [state, formAction] = useActionState(
    isEdit ? updateContentItemAction : createContentItemAction,
    initialState,
  );

  return (
    <form action={formAction} className="max-w-xl space-y-4">
      <FormError message={state.error} />
      {item && <input type="hidden" name="content_item_id" value={item.id} />}

      <div>
        <label htmlFor="title" className="block text-sm font-medium">
          Title <span className="text-red-600">*</span>
        </label>
        <input
          id="title"
          name="title"
          required
          defaultValue={item?.title}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          placeholder="e.g. IETA Open Day — Reel"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="business_unit_id" className="block text-sm font-medium">
            Business unit
          </label>
          <select
            id="business_unit_id"
            name="business_unit_id"
            defaultValue={item?.business_unit_id ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            <option value="">—</option>
            {businessUnits.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="department_id" className="block text-sm font-medium">
            Department
          </label>
          <select
            id="department_id"
            name="department_id"
            defaultValue={item?.department_id ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            <option value="">—</option>
            {departments.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="campaign_id" className="block text-sm font-medium">
            Campaign
          </label>
          <select
            id="campaign_id"
            name="campaign_id"
            defaultValue={item?.campaign_id ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            <option value="">— None —</option>
            {campaigns.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label htmlFor="approval_category_id" className="block text-sm font-medium">
            Escalation category
          </label>
          <select
            id="approval_category_id"
            name="approval_category_id"
            defaultValue={item?.approval_category_id ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            <option value="">— Routine (Management) —</option>
            {approvalCategories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="content_type" className="block text-sm font-medium">
            Content type
          </label>
          <input
            id="content_type"
            name="content_type"
            defaultValue={item?.content_type ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
            placeholder="e.g. Reel, Carousel, Story"
          />
        </div>
        <div>
          <label htmlFor="priority" className="block text-sm font-medium">
            Priority
          </label>
          <select
            id="priority"
            name="priority"
            defaultValue={item?.priority ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          >
            <option value="">—</option>
            {PRIORITIES.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="language" className="block text-sm font-medium">
            Language
          </label>
          <input
            id="language"
            name="language"
            defaultValue={item?.language ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label htmlFor="target_audience" className="block text-sm font-medium">
            Target audience
          </label>
          <input
            id="target_audience"
            name="target_audience"
            defaultValue={item?.target_audience ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="pic_name" className="block text-sm font-medium">
            PIC name
          </label>
          <input
            id="pic_name"
            name="pic_name"
            defaultValue={item?.pic_name ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label htmlFor="due_date" className="block text-sm font-medium">
            Due date
          </label>
          <input
            type="date"
            id="due_date"
            name="due_date"
            defaultValue={item?.due_date ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
      </div>

      {!isEdit && (
        <div>
          <span className="block text-sm font-medium">Platforms</span>
          <div className="mt-1 flex flex-wrap gap-3">
            {PLATFORMS.map((p) => (
              <label key={p.value} className="flex items-center gap-1.5 text-sm">
                <input type="checkbox" name="platforms" value={p.value} />
                {p.label}
              </label>
            ))}
          </div>
          <p className="mt-1 text-xs text-neutral-500">
            Sets which platforms this item publishes to. Publishing status per platform is
            managed after creation.
          </p>
        </div>
      )}

      {isEdit && item && item.platform_publications.length > 0 && (
        <div>
          <span className="block text-sm font-medium">Platforms</span>
          <p className="mt-1 text-xs text-neutral-500">
            {item.platform_publications.map((p) => p.platform.replace("_", " ")).join(", ")} —
            managed separately from this form.
          </p>
        </div>
      )}

      <div>
        <label htmlFor="on_screen_wording" className="block text-sm font-medium">
          On-screen wording
        </label>
        <textarea
          id="on_screen_wording"
          name="on_screen_wording"
          rows={2}
          defaultValue={item?.on_screen_wording ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      <div>
        <label htmlFor="main_caption" className="block text-sm font-medium">
          Caption
        </label>
        <textarea
          id="main_caption"
          name="main_caption"
          rows={3}
          defaultValue={item?.main_caption ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="cta" className="block text-sm font-medium">
            CTA
          </label>
          <input
            id="cta"
            name="cta"
            defaultValue={item?.cta ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label htmlFor="hashtags" className="block text-sm font-medium">
            Hashtags
          </label>
          <input
            id="hashtags"
            name="hashtags"
            defaultValue={item?.hashtags ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="media_drive_link" className="block text-sm font-medium">
            Media / Drive link
          </label>
          <input
            id="media_drive_link"
            name="media_drive_link"
            defaultValue={item?.media_drive_link ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
            placeholder="https://drive.google.com/…"
          />
        </div>
        <div>
          <label htmlFor="canva_link" className="block text-sm font-medium">
            Canva link
          </label>
          <input
            id="canva_link"
            name="canva_link"
            defaultValue={item?.canva_link ?? ""}
            className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
            placeholder="https://canva.com/design/…"
          />
        </div>
      </div>

      <div>
        <label htmlFor="remarks" className="block text-sm font-medium">
          Remarks
        </label>
        <textarea
          id="remarks"
          name="remarks"
          rows={3}
          defaultValue={item?.remarks ?? ""}
          className="mt-1 w-full rounded-md border border-neutral-300 px-3 py-2 text-sm"
        />
      </div>

      <SubmitButton pendingText={isEdit ? "Saving…" : "Creating…"}>
        {isEdit ? "Save changes" : "Create content item"}
      </SubmitButton>
    </form>
  );
}
