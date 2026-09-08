# IEOS Stage 1 Rollback Notes

No hosted migration or deployment is authorised by this document.

## Before any future production change

1. Verify a recoverable Supabase backup and perform a restore rehearsal.
2. Record the deployed application commit and schema migration ledger.
3. Export the six Stage 1 tables if they contain real records.
4. Schedule a maintenance window before any destructive rollback.

## Application rollback

Redeploy the previously recorded application commit. The additive Stage 1
tables may remain dormant; legacy `content_tasks` and `content_items` are not
modified and continue to serve the existing screens.

## Database rollback

Prefer a forward repair. If removal is explicitly approved, first export Stage
1 data, then remove in dependency order: view, RPCs/policies/triggers, event and
grant tables, child tables, `work_tasks`, sequence, helper functions. Remove
`profiles.is_active` only after proving no later code depends on it.

This rollback is potentially destructive and must not be automated or executed
without a separate production-change approval. Expected application downtime
for the preferred application-only rollback is near zero; a destructive schema
rollback requires a planned maintenance window.
