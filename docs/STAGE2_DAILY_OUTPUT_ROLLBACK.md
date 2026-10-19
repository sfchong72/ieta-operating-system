# Stage 2 Daily Output Rollback

Stage 2 is additive and must not be applied to hosted Supabase without a
separate production-change approval and verified backup/restore procedure.

Before a future rollback:

1. Disable the Daily Update navigation and submission UI.
2. Export and preserve `daily_work_updates`, `daily_update_reviews`, linked
   `work_task_artifacts`, and related `work_task_events`.
3. Deploy a separately reviewed rollback migration that removes Stage 2 grants,
   policies, RPCs, views, triggers, tables, and `work_tasks.last_activity_at` in
   dependency order.
4. Restore the Stage 1 `work_task_attention` view definition and Stage 1 event
   constraint.
5. Replay and validate the rollback in a disposable environment first.

Never edit Supabase migration history manually and never delete production
daily-output history as an ad-hoc rollback.
