# IEOS Stage 1 Manual UAT

Run only against a disposable local Supabase project with synthetic users.
Do not use production data, production credentials, or a hosted project.

## Desktop and mobile-width checks

- Sign in as Director: My Work, Team Tasks, Create Task, Needs Attention and
  Task Detail are usable; legacy content tasks remain available separately.
- Sign in as scoped Manager: only authorised business-unit/department tasks
  appear; create/edit/supervisor actions work only in scope.
- Sign in as Intern: only assigned permitted tasks appear; management
  navigation and fields do not appear.
- Create a task with clear instructions, output requirement and deadline.
- Use Quick Update for status/progress/blocker; blocked without a blocker fails.
- Paste a normal Canva/Drive link; it is stored as operational sensitivity for
  ordinary staff.
- Confirm completion fails without final/evidence, then succeeds after a final
  link is added.
- Confirm a Manager can complete an output-not-required task only after a
  reasoned waiver; the assignee cannot self-waive.
- Confirm restricted artifact links are absent for users without permission.
- At mobile width (375px), navigation opens, forms remain readable, controls do
  not overflow, and Task Detail actions remain reachable.

## P&C handling prompt

Every free-text form must show and require the confirmation that sensitive
personal information is not copied into a generic task. P&C work references
only a restricted record ID or authorised restricted artifact link.
