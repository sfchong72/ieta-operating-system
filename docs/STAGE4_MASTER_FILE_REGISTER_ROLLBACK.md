# Stage 4 Master File Register Rollback

Stage 4 remains local-only. Do not apply it to hosted Supabase without separate
production-change approval and a verified backup/restore procedure.

Before any future rollback:

1. Disable the File Register navigation and Stage 4 routes.
2. Preserve `master_files`, explicit access grants, task/artifact links,
   relationships, configuration, and immutable audit events for investigation or
   export.
3. Revoke Stage 4 function/table/view grants and drop Stage 4 views and functions
   in dependency order using a separately reviewed rollback migration.
4. Drop relationship, grant, event, settings, category, and master-file tables
   only after confirming that no later migration depends on them and preservation
   requirements have been satisfied.
5. Remove Stage 4 indexes and generated search support with the owning objects.
6. Replay Stages 1–3 and approval regressions in a disposable environment and
   confirm application typecheck, lint, and production build.

If Stage 4 has never been deployed outside the disposable/local worktree, no
hosted database rollback is required; revert or retire the local branch through
normal Git review.

Never edit Supabase migration history manually. Never delete legacy
`content_tasks`, `content_items`, existing work-task history, task artifacts, or
audit events as an ad-hoc rollback.

