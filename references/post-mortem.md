# Post-mortem — when a gate misses

Every rejection is evidence about the gates. This pipeline improved
the most when its misses were audited; this file makes that audit a
rule instead of a memory.

## Triggers

Any of these events, once resolved, gets a post-mortem record:

- a `reject` verdict at the review gate,
- a rework-cap escalation (two cycles spent, the user decided),
- a post-merge rejection (the user rejected a result every gate
  passed),
- a non-converging acceptance hold (the same rejection reason returned
  with no new information).

## The record

Four fields, filed as a comment on the triggering issue — short enough
to write in two minutes, structured enough to compare across runs.
Written in the team voice (`git-conventions.md`), like everything else
that lands on git:

- **What the gate saw** — the decision as it happened, one line.
- **What it missed** — the defect or mismatch that surfaced later.
- **Which check should have caught it** — the plan-review item, review
  dimension, or stage check that came closest — or "none exists",
  which is itself the finding. Named as a dev would on the target
  repo's issue (content-vs-narration, `git-conventions.md`): "the
  design review's docs check" reads; internal numbering does not.
- **Proposed change** — the rule that would have caught it, stated
  concretely, and surfaced to the user in the final report. Changing
  the pipeline is the user's call — a proposal is never auto-filed
  anywhere else.

Degraded modes follow the pipeline's degradation table: issues
unavailable → the record lands in the PR description; no remote → a
section in `PLAN.md` on the branch; no repo → the final report
carries it. The landing spot degrades; the record never does.

- Refusal condition: a triggering event closed without its record is a
  gate miss the next run inherits — filing the record is part of
  resolving the event, not an optional epilogue.

## How this document is used

- **Stage 5 and the escalation points** — the triggers above fire it;
  the record lands on the issue before the final report closes the
  run.
- **`delegation.md`** — an installed post-mortem/RCA skill is
  preferred for a long-form writeup; this file is the shipped fallback
  and the minimum bar either way.
