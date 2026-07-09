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
  stalling, not diagnosis.

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
  **propose** a handoff to the user with per-stage status. "Almost
  done" does not cancel the proposal — propose anyway.
- **An authoritative low-context system warning** → hand off now, no
  proposal. This overrides the "two or more" count; one authoritative
  warning is sufficient on its own.

## Clean handoff

The pipeline is resumable by construction: the issue, the draft PR, and
the plan comment posted at Stage 2.5 already hold the durable state
(`pipeline.md`). Degraded mode (no GitHub remote, or no `gh`): the
equivalent state lives in `PLAN.md` in the worktree.

To hand off:

1. Commit work in progress (Conventional Commits — a WIP commit is still
   a real commit).
2. Update the plan comment (or `PLAN.md` in degraded mode) with
   per-stage status — done / in-flight / remaining — plus the next
   failable check for the in-flight stage.
3. Tell the user to start a fresh session. It resumes from the
   issue/PR state (or `PLAN.md`), not from a hand-written summary.

- Refusal condition: a handoff without an updated plan comment (or
  `PLAN.md`) is not a clean handoff — the resume point doesn't exist
  until the comment says so.

## Stage-transition marker

Print this line at every stage boundary, before starting the next stage:

```
Stage N done — failable check: <cmd> → GREEN | next: Stage N+1
```

**"Stage N" counts the approved plan's rows** (the execution stages the
plan defined), not the pipeline's fixed step numbers — gate steps like
the plan review produce a verdict, which is their own record, not a
marker.

Then update the plan comment (or `PLAN.md`) to match. The marker keeps
the discipline in recent context on long runs; the comment update is
what makes the per-stage status trustworthy at any point someone reads
it mid-run.
