---
name: run
description: The argus-mode engineering pipeline for Fable/Opus leads — staged plan with failable checks, independent oracle plan review, TDD execution with delegated agents, 6-dimension review gate before merge. Trigger when the user invokes /argus-mode:run or asks to run the argus pipeline on a task. Not for trivial lookups or 1-3 line edits.
---

# /argus-mode:run — the Argus Mode pipeline

The `${CLAUDE_PLUGIN_ROOT}/references/` files are the source of truth: on
any conflict between a summary in this file and a reference file, the
reference wins.

**Cost, up front:** a medium task pays the git ceremony (issue + branch/worktree + draft PR), at least one `argus-oracle` (opus) plan-review run — more on revise cycles — and an `argus-reviewer` review-gate run. Do **not** invoke this for a trivial lookup, a 1–3 line edit, or anything the Stage 1 triviality hatch covers — handle those directly instead.

## Agent availability check

Before Stage 0, check whether `argus-oracle`, `argus-explorer`, `argus-implementer`, and `argus-reviewer` exist as spawnable agents (true on a Claude Code plugin install; not true on a skills-only install, e.g. `npx skills add`).

- Missing → **announce this to the user now**, plainly. Never degrade silently.
- Stage 2.5 (oracle gate) and Stage 5 (review gate) then run **inline**, performed by the lead itself, applying the same rubrics from `${CLAUDE_PLUGIN_ROOT}/references/verification.md` and `${CLAUDE_PLUGIN_ROOT}/references/quality.md`.
- Stage 3 fan-out has no executors either: the lead executes every slice **solo**, in plan order, under the same TDD and verification rules.
- This is a **weaker gate** — the lead is grading its own work. State this plainly in the Deliver section of the final report.
- On a skills-only install `${CLAUDE_PLUGIN_ROOT}` may be unset and the `references/` files unreachable. If a "Read now" target can't be read, run from this file's summaries, announce that too, and treat the references as authoritative the moment they're available again.

## Stage 0 — Model gate

Check the session's model ID (system prompt: "You are powered by the model named …"). Accepted: the ID contains `fable` or `opus` as a substring — a substring match, not a prefix whitelist.

Not accepted → **hard stop**. Present exactly these three doors; do not proceed on any other outcome:

1. Switch model (`/model`) and re-run this skill.
2. Continue under the consult pipeline instead — offer this; on the user's yes, read `${CLAUDE_PLUGIN_ROOT}/skills/consult/SKILL.md` and follow it in that same turn, carrying the user's original request over so nothing is retyped.
3. User explicitly replies "proceed anyway" → run on the current model with reduced guarantees. Record the override and the user's stated reason in the final report.

Never warn-and-continue past a failed gate silently.

Exception: a task that plainly clears the Stage 1 triviality hatch may be handled directly without the model gate — announce the classification as usual. The gate protects the pipeline; work the pipeline itself would decline needs no protecting.

## Stage 1 — Intake

### Triviality escape hatch

Canonical definition lives in `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md`. Summary: trivial = ALL of ≤3 changed lines, one file, no public-API or behavior change (a bugfix changes behavior — a bugfix is never trivial), no new test warranted. (Read-only lookups: trivial if answerable from one file.)

Trivial → announce the classification ("this is a trivial edit — skipping the pipeline"), handle it directly, stop. No creed, no ceremony.

**Re-entry rule:** if the "trivial" edit turns out to need a second edit, a second file, or its first check fails → stop, announce the reclassification, re-enter at Stage 1 proper (full pipeline, from git intake). The hatch is not a bypass valve for the pipeline.

**Non-trivial read-only work** (analysis or a question needing more than one file) takes `pipeline.md`'s read-only route — plan, oracle review, explore, report; no git intake, no PR. It re-enters the git intake the moment it turns into a code change.

### Pipeline engagement

Once the task clears the triviality check, the pipeline engages: **read `${CLAUDE_PLUGIN_ROOT}/references/creed.md` now and recite the Argus creed verbatim, once.** Never recite it again for the rest of this run.

### Git intake

**Read `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` and `${CLAUDE_PLUGIN_ROOT}/references/git-conventions.md` now** — pipeline.md is the flow (follow it exactly, including its degradation rules); git-conventions.md is the naming and message standard every artifact below follows:

1. `git fetch origin`, fast-forward the default branch.
2. `gh issue create` describing the work.
3. Branch via `gh issue develop <n>` (or `git switch -c`). Use an isolated worktree when the tree is dirty or other work is in flight; a clean solo checkout may branch in place.
4. Empty bootstrap commit, open a **draft** PR with `Closes #<n>` immediately.

Every degraded form — no git repo, git repo but no GitHub remote/`gh`, issues disabled, or user opt-out — is defined in `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md`. Apply the matching one and **name it in the final report**. Never silently skip a step.

## Stage 2 — Plan

**Read `${CLAUDE_PLUGIN_ROOT}/references/delegation.md` now** for the domain routing table, and **`${CLAUDE_PLUGIN_ROOT}/references/quality.md` now** — the plan's "Architecture & patterns" column is written against the doctrine, not graded against it for the first time at the gate.

Write the plan as a task list, one row per stage, three columns filled for every row:

| What / owner | Failable check | Architecture & patterns |
|---|---|---|
| The stage's deliverable, and who executes it (lead or which agent) | A concrete check that can actually go RED (command + expected output) | Structures touched, patterns applied and why, test list (name tests before code) |

A check that cannot fail ("looks good", "review the code") is not a check — rewrite it before moving on.

**Domain skill routing:** record which domains the task touches (UI/visual, shadcn project, data viz, database, …) against the table in `${CLAUDE_PLUGIN_ROOT}/references/delegation.md`. Detect matches from the **session's actual available-skills listing** — never invent a skill name from memory or training data. Plugin-namespaced variants count as matches. If no installed skill matches a domain the task touches, say so explicitly in the plan ("no matching skill installed for `<domain>`") and proceed on the quality doctrine alone — never a silent degrade.

## Stage 2.5 — Plan review gate

**Read `${CLAUDE_PLUGIN_ROOT}/references/verification.md` and `${CLAUDE_PLUGIN_ROOT}/references/quality.md` now.**

Spawn `argus-oracle` (or, if unavailable, apply this rubric inline per the Agent availability check above) with the plan, the task statement, and relevant repo context. Review order:

1. **Simpler-alternative pass (mandatory, first):** should this work exist at all? Is there a smaller or more elegant route to the same goal — doing nothing, reusing something that already exists, a 10%-of-the-risk change that solves 90% of the goal, or a different layer?
2. Do these stages actually reach the stated goal?
3. Is every failable check real (can it go RED)?
4. Is a test list present before each implementation stage?
5. Does the chosen architecture hold under `quality.md`?
6. Is any stage delegating a decision that belongs to the lead (architecture, debugging, review, merge)?
7. Does the domain-skill routing match the surfaces the task touches?

**Precondition refusal:** a plan arriving without failable checks, or without a test list for an implementation stage, gets an instant `revise` naming the missing precondition — do not attempt a full review of an unreviewable plan.

Verdict is structured: `approve` or `revise` + reasons.

- `revise` → update the plan, resubmit. Cap: **two revise cycles.** On a third disagreement, present both positions (the plan and the oracle's reasons) to the user, proceed per their call, and note it in the final report.
- A `revise` may be overridden only with an explicit, user-visible justification.
- The oracle always runs at its pinned `opus` tier, regardless of the lead's model.

**On `approve`, the plan becomes durable:** post the plan as an issue comment and mirror the link in the draft PR — or the degraded location from `pipeline.md`'s table (`PLAN.md` with no remote; the PR description when only issues are unavailable). The comment is a git artifact: written in the team voice per `git-conventions.md` (headed "Implementation plan", named checkbox items, `command → result` evidence) — run the lexicon check before posting and before every edit. This comment is the exact resume point — update it at every stage boundary from here on.

## Stage 3 — Execute

**Read `${CLAUDE_PLUGIN_ROOT}/references/delegation.md` now** for the adaptive criteria, brief discipline, and isolation model.

### Solo vs. fan-out

- **Solo** (lead executes in the main loop): single-file changes, tightly coupled edits, anything where briefing an agent costs more than doing the work.
- **Fan-out** (delegate, parallel where independent): multi-file or multi-component work, broad searches, independent test suites.
  - `argus-explorer` — read-only reconnaissance.
  - `argus-implementer` — one self-contained implementation slice per spawn. Every brief: absolute paths, explicit acceptance criteria, no "the file we discussed" references, quality bar restated. Estimate the context footprint before delegating; split large or many-file work into bounded per-file/per-directory slices.

### Non-negotiables

- The lead verifies every delegated slice against its acceptance criteria before accepting it — a cheaper executor is less reliable by construction.
- **Implementers never commit.** They edit files and report; the lead verifies each slice, then commits it (serialized, Conventional Commits).
- Parallel fan-out is allowed only across **disjoint file sets** — two executors never mutate the same file or share a working tree concurrently.
- The lead never delegates: architecture decisions, debugging, the review gate, verification sign-off, merge, or security-sensitive edits.
- All implementation is TDD: red → green → **refactor**. The refactor leg is a real, planned step — not an afterthought.

### Self-catch rules (apply continuously)

- Caught writing implementation code before its test exists → stop, return to the plan's test list.
- Caught claiming progress without running a check → stop, run the stage's failable check.
- Caught re-running the same failing command a third time → stop, change approach or ask the user.

### Between every stage

Run the on-track check — **read `${CLAUDE_PLUGIN_ROOT}/references/on-track.md` now**: loop signals, bounded deliberation, context budget.

Then, before starting the next stage, print the mandatory transition marker and update the plan comment:

```
Stage N done — failable check: <cmd> → GREEN | next: Stage N+1
```

The marker is session-only — printed here, never posted to GitHub. The plan-comment update that accompanies it is a git artifact and follows the team-voice contract in `git-conventions.md`.

## Stage 4 — Verify

Run the actual build/test/lint commands and read the output. GREEN evidence is required before any "done / fixed / passing" claim. A red check is reported as red — never merged over, never rationalized away.

A red check that resists one obvious correction is a debugging event, not a retry event: **read `${CLAUDE_PLUGIN_ROOT}/references/debugging.md` now** and run the diagnose loop (reproduce → fail path → falsify → ledger) before any further attempt. If a `debug-mantra` skill is installed in the session, invoke it instead (domain routing, `references/delegation.md`).

## Stage 5 — Review & deliver

**Read `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` again now** for the verdict→action mapping and the degraded merge semantics.

Spawn `argus-reviewer` on the diff (or, if unavailable, apply this rubric inline per the Agent availability check above). **The brief must attach the verbatim Stage 4 command and its full output** — the reviewer's precondition demands it — **and name the issue and PR under review** so the reviewer can read their text with its read-only `gh` grant (dimension 2 covers the artifacts this run produced). **Precondition refusal:** the reviewer refuses a diff whose test suite is not shown GREEN — it returns immediately naming the missing precondition.

Review dimensions (rubric shared with `quality.md`):

1. **Correctness** — does it do what the issue says; edge cases.
2. **Readability** — docblocks present, truthful, and free of filler prose on all public API; names communicate intent.
3. **Architecture fit** — boundaries respected; single responsibility.
4. **Pattern justification** — patterns earn their complexity.
5. **Test quality** — tests can actually fail; no tautologies.
6. **Security** — injection surfaces, authz seams, secrets in the diff, unsafe defaults. Checked on every review, not only "security tasks".

**Read `${CLAUDE_PLUGIN_ROOT}/references/verification.md` now** for the reviewer operating rules: end-to-end, not diff-local (trace the call graph through the unchanged code around the diff — bugs hide at the seams); no rubber-stamps ("LGTM" is not an output — report what was traced and what was checked); every finding cites `file:line`; report format per finding is **Finding / Why it matters / Evidence / Suggested change**, ordered by severity.

**Verdict → action mapping (exact):**

| Verdict | Action |
|---|---|
| `ship` | Merge. |
| `fix-then-ship` | Fix the findings, re-run Stage 4, merge. No fresh review required. |
| `rework` | Return to Stage 3 (or Stage 2 if the plan is implicated). A fresh Stage 5 review is mandatory afterward. Cap: two rework cycles, then escalate to the user. |
| `reject` | Stop. Do not merge. Report the reviewer's reason to the user. |

On merge: update the PR description's "How it was verified" section with the Stage 4 command and its result — PR text in the team voice per `git-conventions.md` — flip the draft PR to ready, merge — the issue auto-closes. (Degraded modes: local `git merge --no-ff` into the default branch per `pipeline.md`.)

### Deliver

Report to the user:

- What shipped, with evidence (test output, PR link).
- Every degraded, skipped, or overridden step, named plainly — never omitted.
