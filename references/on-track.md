# Staying on track

The check the lead runs between stages, in both skills. Long pipeline runs
fail three ways: looping, over-deliberating, running out of context. Read
this file at every Stage 3 boundary — don't run it from memory on a long
session.

## Loop signals

Any one of these is a signal, not a coincidence:

- Re-reading a file that hasn't changed since the last read.
- Re-running a command with the same arguments, expecting a different
  result.
- Returning to a hypothesis already tried and dropped.
- Two consecutive steps that gained no new information.

Break action: stop, state the blocker in one sentence, then take a
*different* action or ask the user one specific question.

- Refusal condition: never run the same failing command a third time.
  Two identical failures mean change approach or ask — a third run is
  stalling, not diagnosis. At that second failure, record the running
  attempt count on the plan comment — one line per attempt as
  `command → result` — before changing approach, anchored to the
  failure rather than the next stage boundary, so the retry bound
  survives a resume instead of restarting from zero (`pipeline.md`,
  plan-comment lifecycle).

## Edit hygiene

- Don't edit blind: read enough of the surrounding code to know the
  change is correct before making it.
- One edit → one check. Run the relevant check after every edit, before
  starting the next one — never stack unverified edits.

## Bounded deliberation

Past ~1000 words of reasoning without having acted: stop. Act on the
current best decision, or ask the user one sharp question. Deliberation
that keeps circling past this budget is a loop signal wearing a disguise.

## Context budget

Count signals, don't estimate remaining context by feel:

| Signal | Threshold |
|---|---|
| Turns into the task | 60+ |
| Files read this task | 25+ |
| Single file/log read | one read over ~50k tokens |
| Long output re-scrolled | scrolling back through the same long output repeatedly |

- **Two or more true** → finish the current atomic step, then
  **propose** a handoff to the user, pointing at the plan comment's
  checklist state. "Almost done" does not cancel the proposal —
  propose anyway.
- **An authoritative low-context system warning** → hand off now, no
  proposal. This overrides the "two or more" count; one authoritative
  warning is sufficient on its own.

## Stated budget

When the request states a budget — a token or cost ceiling, an effort
cap, a "keep this quick," a spend limit — track consumption against it
and treat roughly 80 percent as the action line. At ~80% of the stated
budget, stop and either escalate to the user or hand off (the clean
handoff below); never continue silently. Revise and rework cycles are
the usual reason a run nears the ceiling — a run that has already burned
most of a stated budget on gate cycles does not spend the remainder on
another; it reports where it stands and asks. Loop-engineering's
degrade-to-report-only is deliberately replaced with escalation here, to
hold the same never-silently-degrade contract the rest of the pipeline
keeps.

- Refusal condition: crossing ~80% of a stated budget and continuing
  without escalating or handing off is a silent degrade — the contract
  the whole pipeline holds forbids it.

## Clean handoff

The pipeline is resumable by construction: the issue, the draft PR, and
the plan comment posted at Stage 2.5 already hold the durable state
(`pipeline.md`). Degraded modes (no remote at all, or `gh` missing):
the equivalent state lives in `PLAN.md`, committed on the branch.

To hand off:

1. Commit work in progress (Conventional Commits — a WIP commit is still
   a real commit).
2. Update the plan comment (or `PLAN.md` in degraded mode): tick the
   finished items' checkboxes, mark the active item in progress, and
   record its next check as `command → expected result`
   (`pipeline.md`, plan-comment lifecycle).
3. Tell the user to start a fresh session. It resumes from the
   issue/PR state (or `PLAN.md`) via the Resume path (`pipeline.md`,
   Resume — the receiving side), not from a hand-written summary. On
   resume the branch's commit log outranks the comment — the update in
   step 2 makes the reconcile cheap, not optional.

- Refusal condition: a handoff without an updated plan comment (or
  `PLAN.md`) is not a clean handoff — the resume point doesn't exist
  until the comment says so.

## Stage-transition marker

Print this block at every stage boundary, before starting the next stage —
the marker line plus a compact status of where the run stands:

```
Stage N done — failable check: <cmd> → GREEN | next: Stage N+1
gates: revise 0/2 · rework 0/2 · attempt 0/3 (active: <next-cmd>)
degraded: <each active degradation, one clause each>
budget: <standing against the ~80% action line>
```

- **Line 1 — the marker.** Always. **"Stage N" counts the approved plan's
  rows** (the execution stages the plan defined), not the pipeline's fixed
  step numbers — gate steps like the plan review produce a verdict, which is
  their own record, not a marker.
- **`gates:` — always, all three counters with their caps, even at zero.**
  The point is seeing headroom *before* a cap escalates: `rework 2/2` is one
  verdict from escalation. `revise X/2` (the plan-review revise cycles) and
  `rework Y/2` (the review-gate rework cycles) are run-cumulative counts the
  plan comment records at each verdict, so they read forward at any boundary.
  `attempt Z/3` is the retry count of the **active check** — the incoming
  stage's check (`(active: <next-cmd>)`), not the completed one on line 1. At a
  fresh stage it reads zero of three; a resumed run that adopts a stage which
  already accumulated identical failures reads them back from the plan comment's
  retry-bound trace. The denominators do not read alike: `/2` is the last
  *permitted* cycle, but the retry bound escalates at the **second** identical
  failure and forbids the third run, so `attempt 2/3` is a next-run-refused
  warning, not one attempt of headroom left. The live warning at that second
  failure is the self-catch's own record (`pipeline.md`, plan-comment
  lifecycle), not a re-print of this block — the block prints at stage
  boundaries, where line 1 is a completed stage. These three are the caps
  **both skills** share; consult's mid-execution checkpoint-firing cap is a
  separate escalation tracked in consult's own section, not folded into this
  line.
- **`degraded:` — omit the row entirely when nothing is degraded** (never
  `degraded: none`). The capability preflight (`pipeline.md`) is the explicit
  degrade floor, announced once at intake; this row is the running delta on
  top of it, so an empty row is noise, not a dropped floor. When one or more
  degrades are active, name each in the degradation contract's own vocabulary.
- **`budget:` — only when the request stated a budget** (`## Stated budget`
  above), and **qualitative** against the ~80% action line: "well under the
  stated ceiling" below the line, "~80% of the stated ceiling reached —
  escalate or hand off, don't continue" at it. Never a fabricated numeric
  meter — no token or dollar counter exists to read, so printing `$3.10 / $4.00`
  would itself be the new tracking this block does not add.

Every value renders state that already exists — no counter is invented. The
revise and rework rounds are read back from the plan comment (recorded at each
verdict), the degradations from the degradation contract, the budget from the
stated ceiling; `attempt Z/3` is the active check's recorded retry count from the
plan comment's retry-bound trace — zero of three when that stage has no recorded
failures. The block adds no count of its own.

The block is session-only output — printed in the session, never posted to
GitHub. The plan-comment update that follows it is a git artifact: it carries
the same state in the team voice (`git-conventions.md`) — named checklist
items and `command → result` evidence, never the block's internal numbering.

Then update the plan comment (or `PLAN.md`) to match. The block keeps the
discipline in recent context on long runs; the comment update is what makes
the checklist state trustworthy at any point someone reads it mid-run.
