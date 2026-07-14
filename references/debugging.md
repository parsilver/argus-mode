# Debugging

The diagnose loop the lead runs when a failure needs root-causing — inside
Stage 3 or Stage 4, before any fix is proposed. Debugging is never
delegated (`delegation.md`): agents report failures; the lead diagnoses
them. Adapted, with credit, from the debug-mantra discipline in
[thananon/9arm-skills](https://github.com/thananon/9arm-skills) — if a
`debug-mantra` skill is installed in the session, prefer invoking it (see
the domain routing table in `delegation.md`); this file is the shipped
fallback.

Run the four steps in order. Do not propose a fix before step 1 holds.

## 1. Reproduce reliably

Build a runnable repro before anything else — a failing test, a script,
an exact command with its captured output.

- Flaky repro → raise the rate first (loop the trigger, add stress,
  narrow timing windows). A 50% flake is debuggable; a 1% flake is not.
- No repro at all → stop and say so. Ask the user for artifacts or
  access. Never hypothesize a fix against a failure you cannot trigger.
- Refusal condition: a fix proposed without a reliable repro is rejected
  on sight — there is no way to prove it fixed anything.

## 2. Know the fail path

Find *where* the code breaks and *what stops it from breaking*.

- Trace the code path end-to-end; enumerate every knob that can move the
  outcome (config flags, env vars, branch conditions, input shape,
  timing, concurrency). Flip one knob at a time — the differential
  narrows the search.
- Escalate to targeted instrumentation only when outside knobs can't
  move the failure. Tag every probe with one greppable prefix so cleanup
  is a single pass.

## 3. Falsify the hypothesis

- Generate 3–5 ranked hypotheses, not one — single-hypothesis thinking
  anchors on the first plausible idea.
- For the front-runner: what is the cleanest **disproof**? Run the
  disproof first. A hypothesis that survives falsification is real; one
  that dies just saved a wasted fix.
- Refusal condition: committing to a root cause that has not survived a
  falsification attempt.

## 4. Every run is a breadcrumb

Keep a ledger of every experiment: what changed, what happened, what it
ruled in or out.

- A new hypothesis must hold against **every** prior run, not just the
  latest — one contradicting breadcrumb kills or refines it.
- When in doubt, design the single experiment whose outcome makes the
  answer certain, and run that next instead of churning on adjacent runs.

## Where this loop hands back to the pipeline

- `on-track.md` still governs: the same failing command never runs a
  third time — two identical failures mean change approach or ask.
- `/argus-mode:consult`: the loop starts at the **first** failure — a
  deliberate, earlier entry than run's "resists one obvious correction"
  rule — because a stage's failable check failing twice is checkpoint-2
  trigger (c), and the ledger must already exist when it fires. Bring
  the ledger to `argus-oracle` instead of attempting a third run.
  Record one line per attempt on the plan comment as `command → result`
  (`pipeline.md`, plan-comment lifecycle) so a resumed consult arrives
  with the prior runs as evidence, not evidence-free.
- The fix, once found, is implementation work: it re-enters the pipeline
  (its test first, then the fix, then Stage 4 evidence). The diagnose
  loop ends at the root cause, not at the merge.

## How this document is used

- **Stage 3 (Execute)** — a red check that resists one obvious
  correction starts this loop before any further attempt (in
  `/argus-mode:consult`: from the first failure — see the hand-back
  section above).
- **Stage 4 (Verify)** — an unexplained red is diagnosed here, never
  merged over or rationalized away.
- **`delegation.md`** — debugging stays with the lead; this file is the
  discipline the lead applies while holding it.
