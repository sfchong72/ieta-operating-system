# Stage 0.5 Recovered-Work Commit Slices

The recovered work is preserved separately before these commits. These slices
make the local branch reviewable without implying production readiness.

1. **Runtime and tooling stability** — Supabase fetch retry behaviour, auth
   callback hardening, Next.js/ESLint/build corrections, and package metadata.
2. **Approval database and security acceptance** — staging migrations 006–008,
   local disposable harness, fixtures, and behavioural tests.
3. **Approval data/actions** — types, permission-aware data access, approval
   actions, campaign data, and edit-event data.
4. **Approval/planner interface** — recovered approval queue, planner forms,
   approval history, submit-review form, and navigation.
5. **Recovered edit support** — idea, knowledge, SOP, task, and work-file edit
   routes/actions/components.
6. **Stage 0.5 governance** — authoritative plan, guardrails, supersession
   notices, safety scripts, and push block.

Each commit remains local. Nothing in this sequence authorises a push, merge,
preview deployment, hosted migration, or production deployment.

