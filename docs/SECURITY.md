# Security

## Secret handling
- Supabase URL + anon key: public-safe, exposed via `NEXT_PUBLIC_SUPABASE_*` env vars.
- Service role key: server-only, never in frontend. Used only in server actions if needed.
- No third-party API keys in v1.

## Permission model (v1 → lock-down)
**v1 (demo-first):** RLS enabled, permissive read/write policies — app works without login. Seed data renders on first visit.
**Lock-down sprint:** Replace permissive policies with `auth.uid() = user_id` scoped policies on every table. Users see only their own rows. Director role sees all (override policy).
- Roles: director, manager, training_manager, executive, intern — stored as text label on profile (later).
- Simple role-based UI: interns can create/update own tasks; managers can approve; director can delete.

## Approved-tools rule
Agents use named functions only (`detect_file_type`, `compute_priority_score`, `suggest_tags`). No raw SQL execution, no arbitrary API calls, no `run_any`/`send_any` patterns. Every agentic action is a typed server function.

## Audit principle
Every meaningful state change (task created, status changed, link attached, approved, posted, deleted) writes to `activities` with actor name, action, detail, timestamp. No silent writes.
