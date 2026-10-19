# Stage 3 Manager Dashboard Rollback

Stage 3 remains local-only. Do not apply it to hosted Supabase without separate
production-change approval and a verified backup/restore procedure.

Before any future rollback:

1. Disable the Dashboard and enhanced Needs Attention navigation/UI.
2. Preserve the current `work_dashboard_settings`,
   `work_dashboard_access_grants`, and `work_tasks.status_changed_at` values.
3. Revoke Stage 3 grants and drop Stage 3 dashboard views/functions in
   dependency order using a separately reviewed rollback migration.
4. Restore the Stage 2 `work_task_attention` definition and the prior
   `touch_work_task()` definition.
5. Remove Stage 3 indexes, tables, and `work_tasks.status_changed_at` only after
   confirming that no later migration depends on them.
6. Replay Stage 1, Stage 2, and approval regressions in a disposable environment
   and confirm application typecheck, lint, and production build.

Never edit Supabase migration history manually. Never remove immutable task,
daily-update, review, artifact, or audit-event history as an ad-hoc rollback.

