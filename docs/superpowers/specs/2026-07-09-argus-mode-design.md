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
│   │       ├── verification.md# failable checks, plan-review rubric, skeptical self-review
│   │       └── quality.md     # the quality doctrine (single source of truth)
│   └── argus-consult/
│       └── SKILL.md           # small-model lead + oracle checkpoints (reuses ../argus-mode/references/)
├── agents/
│   ├── argus-oracle.md        # model: opus  — read-only advisor (plan review, arch consult, final gate)
│   ├── argus-explorer.md      # model: haiku — read-only codebase scout
│   ├── argus-implementer.md   # model: sonnet — TDD-first executor, quality bar embedded
│   └── argus-reviewer.md      # model: inherit — 5-dimension skeptical review gate
├── docs/superpowers/specs/    # design specs (this file)
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

- Do these stages actually reach the stated goal?
- Is every failable check real (can it go RED)?
- Is a test list present before each implementation stage?
- Does the chosen architecture hold under the doctrine in `quality.md`?
- Is any stage delegating a decision that belongs to the lead
  (architecture, debugging, review, merge)?

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
- **The lead never delegates:** architecture decisions, debugging, the
  review gate, verification sign-off, merge.
- All implementation is TDD: red → green → **refactor**. The refactor leg
  is a real step in the plan, not an afterthought.

### Stage 4 — Verify

Run the actual build/test/lint commands and read the output. GREEN evidence
is required before any "done/fixed/passing" claim. A red check is reported
as red — never merged over, never rationalized away.

### Stage 5 — Review & Deliver

- Spawn `argus-reviewer` on the diff. Review dimensions (rubric shared with
  `quality.md`):
  1. **Correctness** — does it do what the issue says; edge cases.
  2. **Readability** — docblocks present and truthful on all public API;
     names communicate intent.
  3. **Architecture fit** — boundaries respected; single responsibility.
  4. **Pattern justification** — patterns earn their complexity.
  5. **Test quality** — tests can actually fail; no tautologies.
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

`/argus-consult` also contains the reverse gate: if the session model is
already Fable/Opus, point the user to `/argus-mode` instead.

## Agents

All agent files state explicitly in their system prompt: *you inherit no
CLAUDE.md, no conversation history — the brief is your whole world.* Each
embeds the conventions it needs (Conventional Commits, the quality
doctrine, TDD).

| Agent | Model | Tools | Mandate |
|---|---|---|---|
| `argus-oracle` | `opus` (pinned) | read-only (Read, Grep, Glob, Bash read-only) | Advisor, never executor. Three duties: plan review (structured verdict), architecture consultation (decision + rationale + risks), final skeptical review. Returns analysis; never edits files. |
| `argus-explorer` | `haiku` | read-only | Fast codebase reconnaissance; returns findings as structured summaries with `file:line` references, not file dumps. |
| `argus-implementer` | `sonnet` | all | Executes one self-contained implementation slice TDD-first. Quality bar embedded: docblocks on public API, SOLID, small modules, justified patterns, refactor leg mandatory, Conventional Commits. |
| `argus-reviewer` | `inherit` | read-only + Bash (to run tests) | The 5-dimension review gate. Runs the test suite itself; verdict `approve`/`revise` with file:line findings. |

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

## Distribution

- `.claude-plugin/plugin.json` — plugin manifest (`name: "argus-mode"`).
- `.claude-plugin/marketplace.json` — the repo doubles as its own
  marketplace: `/plugin marketplace add parsilver/argus-mode`, then install
  `argus-mode`.
- Note: Claude Code may display plugin skills namespaced
  (`argus-mode:argus-mode`); typing `/argus-mode` resolves when unambiguous.
  Verify actual invocation UX during implementation and document it in the
  README.

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
