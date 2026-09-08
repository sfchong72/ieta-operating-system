# IEOS Controlled Development Guardrails

This document is authoritative for every agent and developer working in this
repository. If a historical document conflicts with it, this document wins.

## Controlled workspace

- Use `codex-ieos-stage1-task-tracker` for the approved Stage 1 scope.
- The pre-governance state is preserved outside the repository as a ZIP, Git
  bundle, exact file tree, and manifest.
- Do not let Hermes and Codex edit this worktree concurrently.
- Repository-local push protection must remain enabled until Claire explicitly
  authorises a push.

## Allowed in Stage 1

- Read repository code, history, and documentation.
- Preserve local files and refs.
- Implement Task Tracker, Task Detail, Create/Update Task, Quick Update,
  comments, artifacts, attention filters, scoped access, and immutable audit.
- Run local typecheck, lint, build, and disposable tests.
- Produce reports.

## Prohibited

- Stage 2 Daily Output Log, Stage 3 Manager Dashboard, or later modules.
- Git push, merge, pull request, or Vercel deployment.
- Hosted Supabase migration, SQL execution, linking, or database reset.
- `vercel env pull`, production environment retrieval, or secret display.
- GitHub, Supabase, or Vercel ownership changes.
- DNS or production-domain changes.
- Hermes Telegram changes.
- Destructive Git reset/checkout or deletion of recovered files.

## Database isolation

- Local Supabase/Docker only.
- `supabase/.temp/project-ref` must be absent for disposable test runs.
- Disposable harnesses must reject hosted database connection variables and
  accept only loopback hosts (`localhost`, `127.0.0.1`, or `::1`).
- Use synthetic test users and records only.
- Stop and remove disposable resources after each acceptance run.
- Local `.env*` files remain ignored and must never be printed, staged, copied
  into reports, or treated as authorisation to contact a hosted service.

## Deployment isolation

- The existing ignored `.vercel/project.json` is evidence of a historical
  local link; its presence does not authorise any Vercel command.
- Auto-deployment is prevented by blocking Git push from this controlled
  workspace.
- Do not change, unlink, or inspect live Vercel project settings during Stage
  0.5.

## Stage approval gates

1. Stage 0.5 completion report and Claire approval.
2. Stage 1 local implementation and acceptance report.
3. Separate preview/UAT approval if requested.
4. Verified production backup and restore method.
5. Separate production-change approval.

