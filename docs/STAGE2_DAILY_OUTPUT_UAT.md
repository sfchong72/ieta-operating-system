# Stage 2 Daily Output UAT

Use synthetic local identities and records only.

## Staff / intern

- Sign in as the synthetic intern.
- Confirm Daily Update lists only assigned active tasks.
- Submit a short update without a deliverable link.
- Confirm the update appears in immutable history and the task records activity.
- Select “Deliverable completed today?” without a link and confirm submission is
  rejected.
- Submit a completed deliverable with a synthetic HTTPS link and confirm the
  evidence is visible on both the update and task.
- Confirm another user’s task and daily history are not accessible.

## Manager

- Confirm scoped staff updates are visible and cross-business-unit updates are
  not accessible.
- Add Checked, Correction Required, and Approved review events.
- Confirm Correction Required needs a comment.
- Confirm each review is appended and earlier reviews remain unchanged.

## Responsive and cleanup

- Complete the submission flow at mobile width (390 × 844).
- Review history and add a supervisor review at desktop width.
- Confirm no empty Stage 3 dashboard capability was introduced.
- Signal PASS only after the checks succeed; confirm the harness stops the
  disposable stack and removes the temporary lab.
