# Argus Mode — Claude Code Plugin Design

- **Date:** 2026-07-09
- **Status:** Approved design, pending implementation
- **Repo:** `parsilver/argus-mode`

## Overview

Argus Mode is a Claude Code plugin that packages a Fable-5-style execution
workflow as reusable skills and agents. Like Argus Panoptes — the hundred-eyed
giant — every stage of work is watched by an independent verification eye.

Running `/argus-mode` puts the session through a disciplined engineering
pipeline: classify the task, run git intake (issue → branch/worktree → PR),
write a staged plan with failable verification checks, have an independent
agent review the plan before execution, execute TDD-first (delegating to
subagents adaptively), verify with real command output, and pass a skeptical
review gate before merge.

The workflow is quality-first by design. Its doctrine: code is written for
humans (docblocks on every public API), architecture is chosen deliberately
(SOLID, single-responsibility modules, justified design patterns), code stays
refactor-ready at all times, and TDD drives every implementation.

## Goals

1. `/argus-mode` — the full workflow, for sessions led by **Fable or Opus** only.
2. `/argus-consult` — the same pipeline for **Sonnet/Haiku** sessions, with
   mandatory consultation checkpoints against a pinned big-model advisor
   (`argus-oracle`) at the quality-critical decision points.
3. A small agent roster (4 agents) that the skills orchestrate.
4. Distributed as a Claude Code plugin with a self-hosted marketplace, so
   `/plugin marketplace add parsilver/argus-mode` + install just works.
5. All plugin content in English.

## Non-Goals (v0.1)

- No hooks, no MCP servers, no Workflow-tool orchestration scripts.
- No per-language lint/format configuration — the doctrine is
  language-agnostic; repos keep their own tooling.
- No standing agent roster beyond the 4 defined agents.

## Repository Structure

```
argus-mode/
├── .claude-plugin/
│   ├── plugin.json            # name "argus-mode", version, description, author
│   └── marketplace.json       # self-hosted marketplace listing this plugin
├── skills/
│   ├── argus-mode/
│   │   ├── SKILL.md           # main workflow — Fable/Opus lead (lean; ~200 lines)
│   │   └── references/
│   │       ├── pipeline.md    # git intake: issue → branch/worktree → TDD → PR → verify → merge
│   │       ├── delegation.md  # adaptive criteria: solo vs fan-out, brief right-sizing
│   │       ├── verification.md# failable checks, plan-review rubric, reviewer operating rules
│   │       ├── quality.md     # the quality doctrine (single source of truth)
│   │       └── on-track.md    # loop-breaking, context budget, clean handoff/resume
│   └── argus-consult/
│       └── SKILL.md           # small-model lead + oracle checkpoints (reuses ../argus-mode/references/)
├── agents/
│   ├── argus-oracle.md        # model: opus  — read-only advisor (plan review, arch consult, final gate)
│   ├── argus-explorer.md      # model: haiku — read-only codebase scout
│   ├── argus-implementer.md   # model: sonnet — TDD-first executor, quality bar embedded
│   └── argus-reviewer.md      # model: inherit — 5-dimension skeptical review gate
├── docs/superpowers/specs/    # design specs (this file)
├── CLAUDE.md                  # repo consistency invariants (see Repo Conventions)
├── README.md                  # install, usage, model matrix, philosophy
├── CHANGELOG.md
└── LICENSE                    # MIT
```

## Skill 1: `/argus-mode`

Target lead models: **Fable, Opus**. Stages:

### Stage 0 — Model Gate

First action: check the session model (the system prompt states
"You are powered by the model named …" / the model ID). Accepted: any
`claude-fable-*` or `claude-opus-*` model.

- Not accepted → **hard stop**. Tell the user their options:
  1. switch models (`/model`) and re-run `/argus-mode`, or
  2. run `/argus-consult`, which is built for smaller leads.
  Do not "warn and continue" — the workflow's quality promises assume a
  top-tier lead.

On passing the gate, recite the **Argus creed** verbatim as the first
thing in the response — a short fixed block naming the stages and the
commitments (tests before code, failable checks, independent eyes on the
plan and the diff, GREEN evidence before "done"). Reciting once makes the
discipline observable to the user and primes instruction-following;
never re-recite mid-pipeline. The creed text lives in SKILL.md.

### Stage 1 — Intake

- **Triviality check (escape hatch):** single trivial lookup or a 1–3 line
  mechanical edit → tell the user this task does not need the pipeline,
  handle it directly, stop. The pipeline must never feel like bureaucracy.
- **Git intake** (when the project is a git repo):
  1. `git fetch origin` and fast-forward the default branch.
  2. Create a GitHub issue describing the work (`gh issue create`).
  3. Branch via `gh issue develop <n>` (or `git switch -c`). Use an isolated
     git worktree whenever the working tree is dirty or other work is in
     flight; a clean solo checkout may branch in place.
  4. Open a PR early with `Closes #<n>` once the first commit exists.
- **Degradation rules** (explicit, in `references/pipeline.md`):
  - No git repo → offer `git init`; if declined, run plan/execute/verify
    stages without the git layer and say so in the final report.
  - Git repo but no GitHub remote (or no `gh`) → local branch, skip
    issue/PR, note the skipped steps in the final report.
  - Never silently skip a pipeline step.

### Stage 2 — Plan

Write a staged plan as a task list (one todo per stage). **Plan template —
every stage must fill three columns:**

| Column | Content |
|---|---|
| What / Owner | The stage's deliverable, and who executes it (lead or which agent) |
| Failable check | A concrete verification that can actually go RED (command + expected output) |
| Architecture & patterns | Structures touched, patterns applied and why, test list (TDD: tests named before code) |

A check that cannot fail ("looks good", "review the code") is not a check.

### Stage 2.5 — Plan Review Gate

Spawn `argus-oracle` with the plan, the task statement, and relevant repo
context. The oracle reviews **goal-backward** against the rubric in
`references/verification.md`:

- **Simpler-alternative pass (mandatory, first):** should this work exist
  at all, and is there a smaller or more elegant route to the same goal —
  doing nothing, reusing something that already exists in the codebase,
  a 10%-of-the-risk change that solves 90% of the goal, or solving it at
  a different layer? Naming a better alternative is the most valuable
  possible output of the review.
- Do these stages actually reach the stated goal?
- Is every failable check real (can it go RED)?
- Is a test list present before each implementation stage?
- Does the chosen architecture hold under the doctrine in `quality.md`?
- Is any stage delegating a decision that belongs to the lead
  (architecture, debugging, review, merge)?

**Precondition refusal:** a plan arriving without failable checks, or
without a test list for an implementation stage, gets an instant `revise`
naming the missing precondition — the oracle does not attempt a full
review of an unreviewable plan.

Verdict is structured: `approve` or `revise` + reasons. On `revise`, the
lead updates the plan and re-submits. The lead may not silently override a
`revise`. (In `/argus-mode` the lead may pass a model override to run the
oracle on the lead's own tier.)

### Stage 3 — Execute (adaptive)

- **Solo** (lead executes in the main loop): single-file changes, tightly
  coupled edits, anything where briefing an agent costs more than the work.
- **Fan-out** (delegate to agents, parallel where independent): multi-file
  or multi-component work, broad searches, independent test suites.
  - `argus-explorer` for read-only reconnaissance.
  - `argus-implementer` for implementation slices — every brief is
    self-contained (agents inherit no conversation context) and restates
    the quality bar and conventions the slice touches.
  - **Brief discipline** (`references/delegation.md`): absolute paths,
    explicit acceptance criteria, no references to "the file we
    discussed"; the reference includes a bad/good brief pair as the
    teaching example. Estimate the context footprint before delegating —
    work that reads large or many files is split into bounded
    per-file/per-directory slices.
  - **The lead verifies every delegated slice against its acceptance
    criteria before accepting it** — a cheaper executor is less reliable
    by construction.
- **The lead never delegates:** architecture decisions, debugging, the
  review gate, verification sign-off, merge, or security-sensitive edits.
- All implementation is TDD: red → green → **refactor**. The refactor leg
  is a real step in the plan, not an afterthought.
- **Self-catch rules** (in SKILL.md, applied continuously): caught
  writing implementation code before its test exists → stop, return to
  the plan's test list. Caught claiming progress without running a check
  → stop, run the stage's failable check. Caught re-running a failing
  command a third time → stop, change approach or ask the user.
- **Between stages, run the on-track check** (`references/on-track.md`):
  loop signals, bounded deliberation, context budget.

### Stage 4 — Verify

Run the actual build/test/lint commands and read the output. GREEN evidence
is required before any "done/fixed/passing" claim. A red check is reported
as red — never merged over, never rationalized away.

### Stage 5 — Review & Deliver

- Spawn `argus-reviewer` on the diff. **Precondition refusal:** the
  reviewer refuses a diff whose test suite is not GREEN — reviewing
  failing code wastes the gate; it returns immediately naming the missing
  precondition.
- Review dimensions (rubric shared with `quality.md`):
  1. **Correctness** — does it do what the issue says; edge cases.
  2. **Readability** — docblocks present and truthful on all public API;
     names communicate intent.
  3. **Architecture fit** — boundaries respected; single responsibility.
  4. **Pattern justification** — patterns earn their complexity.
  5. **Test quality** — tests can actually fail; no tautologies.
- Reviewer operating rules (`references/verification.md`):
  - **End-to-end, not diff-local.** The diff is the entry point, not the
    scope — trace the call graph through the unchanged code around it;
    bugs hide at the seams.
  - **No rubber-stamps.** "LGTM" is not an output. Finding nothing means
    reporting *what was traced and what was checked*, so the lead can
    judge whether the review covered the surface that mattered.
  - **Cite or it didn't happen.** Every finding references `file:line`.
  - Report format per finding: **Finding / Why it matters / Evidence /
    Suggested change**, ordered by severity. Closing verdict is one of
    `ship / fix-then-ship / rework / reject` with the single biggest
    reason.
- Fix findings, re-verify, then merge the PR (issue auto-closes).
- Final report to the user: what shipped, evidence (test output, PR link),
  anything skipped and why.

## Skill 2: `/argus-consult`

Target lead models: **Sonnet, Haiku** (also usable by any non-Fable/Opus
lead). Same pipeline, same references, with three **mandatory oracle
checkpoints** — the big model is paid for only at quality-critical decision
points while the cheap model does all execution:

1. **After Plan:** same Stage 2.5 gate, with the oracle always at its pinned
   `opus` tier (no tier-override option here); the lead must apply the verdict.
2. **On any architecture/design uncertainty during Execute:** do not guess —
   consult `argus-oracle` with full context (goal, constraints, options
   considered) and follow or explicitly justify divergence to the user.
3. **Before Deliver:** the oracle performs the final skeptical review
   (replacing the small model's self-review; `argus-reviewer` runs
   `model: inherit`, so on a small lead the final gate must come from the
   oracle instead).

`/argus-consult` recites the same Argus creed after its gate passes
(small leads benefit from the recital the most), and contains the reverse
gate: if the session model is already Fable/Opus, point the user to
`/argus-mode` instead.

## Agents

All agent files state explicitly in their system prompt: *you inherit no
CLAUDE.md, no conversation history — the brief is your whole world.* Each
embeds the conventions it needs (Conventional Commits, the quality
doctrine, TDD).

| Agent | Model | Tools | Mandate |
|---|---|---|---|
| `argus-oracle` | `opus` (pinned) | read-only (Read, Grep, Glob, Bash read-only) | Advisor, never executor. Three duties: plan review (mandatory simpler-alternative pass, then the goal-backward rubric; structured verdict; instant `revise` on missing preconditions), architecture consultation (decision + rationale + risks), final skeptical review. Returns analysis; never edits files. |
| `argus-explorer` | `haiku` | read-only | Fast codebase reconnaissance; returns findings as structured summaries with `file:line` references, not file dumps. |
| `argus-implementer` | `sonnet` | all | Executes one self-contained implementation slice TDD-first. Quality bar embedded: docblocks on public API, SOLID, small modules, justified patterns, refactor leg mandatory, Conventional Commits. |
| `argus-reviewer` | `inherit` | read-only + Bash (to run tests) | The 5-dimension review gate. Refuses non-GREEN diffs; runs the test suite itself; traces beyond the diff; never rubber-stamps; findings cite `file:line`; verdict `ship / fix-then-ship / rework / reject`. |

## Quality Doctrine (`references/quality.md`)

The single source of truth, referenced by the plan template, implementer
brief requirements, oracle rubric, and reviewer rubric — writer and
reviewer always hold the same standard:

1. **Code for humans.** Docblocks on every public class/method/function
   (PHPDoc/JSDoc/rustdoc/etc. per language). Meaningful names. Code a new
   teammate can read without guessing.
2. **Architecture before code.** SOLID; small single-responsibility
   composable modules; explicit layer boundaries. Maintainable and scalable
   by construction, not by later heroics.
3. **Design patterns that earn their keep.** Chosen in the plan with a
   written justification; a pattern that doesn't reduce maintenance cost
   doesn't ship.
4. **Refactor-ready, always.** Boy-scout rule; no god files; test coverage
   is the license to refactor at any time.
5. **TDD, non-negotiable.** Red → green → refactor. Tests are named in the
   plan before implementation code exists; the refactor leg is a planned
   step.

## Staying on Track (`references/on-track.md`)

Long pipeline runs fail three ways: looping, over-deliberating, and
running out of context. The lead runs this check between stages:

- **Loop signals:** re-reading an unchanged file, re-running a command
  with the same args expecting a different result, returning to a
  hypothesis already tried and dropped, two consecutive steps that gained
  no new information. On a signal: stop, state the blocker in one
  sentence, then take a *different* action or ask the user one specific
  question. Never run the same failing command a third time.
- **Edit hygiene:** don't edit blind — read enough to know the change is
  correct before editing; one edit → one check before the next step.
- **Bounded deliberation:** past ~1000 words of reasoning without acting,
  act on the current best decision or ask the user one sharp question.
- **Context budget — count signals, don't estimate:** 20+ turns into the
  task; 5+ files read (or one huge file/log); long outputs being
  re-scrolled; 3+ plan stages still left. Two or more true → finish the
  current atomic step, then hand off. "Almost done" does not cancel a
  hand-off.
- **Clean handoff — the pipeline is resumable by construction:** the
  issue, the PR, and the plan (posted as a PR/issue comment) already hold
  the durable state. To hand off: commit work in progress, update the
  plan comment with per-stage status (done / in-flight / remaining, plus
  the next failable check), then tell the user to start a fresh session —
  it resumes from the issue/PR state instead of a hand-written summary.

## Distribution

- `.claude-plugin/plugin.json` — plugin manifest (`name: "argus-mode"`).
- `.claude-plugin/marketplace.json` — the repo doubles as its own
  marketplace: `/plugin marketplace add parsilver/argus-mode`, then install
  `argus-mode`.
- Also installable via `npx skills add parsilver/argus-mode` (the
  cross-agent skills installer) for users on agents other than Claude
  Code; document both paths in the README.
- Note: Claude Code may display plugin skills namespaced
  (`argus-mode:argus-mode`); typing `/argus-mode` resolves when unambiguous.
  Verify actual invocation UX during implementation and document it in the
  README.

## Repo Conventions (root `CLAUDE.md`)

The repo carries a root `CLAUDE.md` locking consistency invariants, so
any future session editing this repo preserves them automatically:

- Every skill has an entry in the top-level `README.md` (name linked to
  its `SKILL.md`) and is listed in `.claude-plugin/plugin.json`.
- Every agent appears in the README agent table with its model + mandate.
- `references/` files are shared by both skills — a change there changes
  both pipelines; re-read both SKILL.md files to confirm they still hold.
- Version bumps update `plugin.json` and `CHANGELOG.md` together.

## Validation

Before tagging `v0.1.0`:

1. `plugin-dev:plugin-validator` agent — structural validation of
   plugin.json / marketplace.json / skills / agents.
2. `plugin-dev:skill-reviewer` agent — quality review of both SKILL.md
   files (triggering, clarity, progressive disclosure).
3. Manual smoke tests:
   - `/argus-mode` on an Opus session → pipeline runs end-to-end on a toy task.
   - `/argus-mode` on a Sonnet session → hard stop with the two options.
   - `/argus-consult` on a Sonnet/Haiku session → oracle checkpoints fire.
   - A trivial task → escape hatch declines the pipeline.

## Future Ideas (explicitly out of scope for v0.1)

- A `PreToolUse` hook enforcing the model gate mechanically.
- Workflow-tool orchestration scripts for large fan-outs.
- Per-language quality profiles (e.g., PHP/Laravel, TypeScript presets).

## Influences

- The staged-execution discipline mirrors how Fable-5-class leads
  operate: written plan, adaptive delegation, failable verification,
  skeptical review.
- Several mechanics are adapted from
  [thananon/9arm-skills](https://github.com/thananon/9arm-skills):
  the verbatim recital and self-catch rules (`debug-mantra`); the
  mandatory simpler-alternative pass, no-rubber-stamp rule, and
  Finding/Why/Evidence/Fix report format (`scrutinize`); precondition
  refusal (`post-mortem`); self-contained brief discipline with
  acceptance criteria and context-footprint sizing (`qwen-agent`); and
  the loop-break / context-budget / clean-handoff rules (`qwenchance`).
