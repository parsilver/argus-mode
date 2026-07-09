# Argus Mode — Claude Code Plugin Design

- **Date:** 2026-07-09
- **Status:** Approved design, revised after independent multi-lens review — pending implementation
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

> **Naming note:** Claude Code always namespaces plugin skills, so the
> real commands are `/argus-mode:run` and `/argus-mode:consult` (the
> skills are deliberately named `run` and `consult` so the namespaced
> commands read naturally). This spec writes `/argus-mode` and
> `/argus-consult` as shorthand for readability.

## Non-Goals (v0.1)

- No hooks, no MCP servers, no Workflow-tool orchestration scripts.
- No per-language lint/format configuration — the doctrine is
  language-agnostic; repos keep their own tooling.
- No standing agent roster beyond the 4 defined agents. Considered and
  rejected: a **designer** agent (domain expertise routes in as skills the
  lead invokes — see Domain skill routing in Stage 2; a plugin-shipped
  designer would either depend on skills the user may not have installed
  or duplicate their content and drift), a **debugger** (debugging is
  never delegated), a **tester** (splitting test-writing from the
  implementer breaks the red-green-refactor loop), a **security auditor**
  (a review dimension, not an agent), and a **documenter** (docblocks are
  the implementer's job; a separate doc-writer drifts from the code).

## Repository Structure

```
argus-mode/
├── .claude-plugin/
│   ├── plugin.json            # name "argus-mode", version, description, author
│   └── marketplace.json       # self-hosted marketplace (dual role — verify: see Validation)
├── references/                # shared by BOTH skills — resolved via ${CLAUDE_PLUGIN_ROOT}/references/
│   ├── creed.md               # the verbatim Argus creed (single copy — no drift between skills)
│   ├── pipeline.md            # git intake: issue → branch/worktree → TDD → PR → verify → merge
│   ├── delegation.md          # adaptive criteria, brief right-sizing, isolation model, domain table
│   ├── verification.md        # failable checks, plan-review rubric, reviewer operating rules
│   ├── quality.md             # the quality doctrine (single source of truth)
│   └── on-track.md            # loop-breaking, context budget, clean handoff/resume
├── skills/
│   ├── run/
│   │   └── SKILL.md           # /argus-mode:run — main workflow, Fable/Opus lead (lean; ~200 lines)
│   └── consult/
│       └── SKILL.md           # /argus-mode:consult — small-model lead + oracle checkpoints
├── agents/
│   ├── argus-oracle.md        # model: opus  — read-only advisor (plan review, arch consult, final gate)
│   ├── argus-explorer.md      # model: haiku — read-only codebase scout
│   ├── argus-implementer.md   # model: sonnet — TDD-first executor, quality bar embedded
│   └── argus-reviewer.md      # model: inherit — 6-dimension skeptical review gate
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
model ID containing the tier token `fable` or `opus` — a substring
match, not a prefix whitelist, because ID formats change across
generations.

- Not accepted → **hard stop** with three doors:
  1. switch models (`/model`) and re-run, or
  2. have the `/argus-consult` pipeline run immediately in this same
     turn (offer to do it — don't make the user retype), or
  3. the user explicitly replies "proceed anyway" → run on the smaller
     model with reduced guarantees; the override and its reason are
     recorded in the final report.
  Never warn-and-continue silently — the workflow's quality promises
  assume a top-tier lead.

The **Argus creed** is recited verbatim once the pipeline actually
engages — after the gate passes AND Stage 1's triviality check confirms
the task warrants the pipeline (a solemn recital followed by "this
doesn't need the pipeline" would be exactly the bureaucracy Stage 1
forbids). Reciting once makes the discipline observable and primes
instruction-following; never re-recite mid-pipeline. The canonical text
lives in `references/creed.md`, read by both skills:

> **The Argus creed**
> 1. A hundred eyes, one standard — independent eyes review the plan
>    and the diff; I do not grade my own work.
> 2. No code before its test; no claim before its check.
> 3. Every stage carries a check that can fail — and I run it.
> 4. GREEN evidence before "done" — a red check is reported, never
>    buried.

### Stage 1 — Intake

- **Triviality check (escape hatch):** trivial means ALL of — ≤3 changed
  lines, one file, no public-API or behavior change, no new test
  warranted (for lookups: answerable read-only from one file). Trivial →
  announce the classification, handle it directly, stop — no creed, no
  ceremony. **Re-entry rule:** if the "trivial" edit turns out to need a
  second edit, a second file, or its first check fails, stop and enter
  the pipeline at Stage 1. The pipeline must never feel like bureaucracy
  — and the hatch must never become the pipeline's bypass valve.
- **Git intake** (when the project is a git repo):
  1. `git fetch origin` and fast-forward the default branch.
  2. Create a GitHub issue describing the work (`gh issue create`).
  3. Branch via `gh issue develop <n>` (or `git switch -c`). Use an isolated
     git worktree whenever the working tree is dirty or other work is in
     flight; a clean solo checkout may branch in place.
  4. Create an empty bootstrap commit and open a **draft** PR with
     `Closes #<n>` immediately — it flips to ready at Stage 5. The draft
     PR is the durable home for the plan comment and stage status.
- **Degradation rules** (explicit, in `references/pipeline.md`) — every
  stage has a defined degraded form, including review and merge:
  - No git repo → offer `git init`; if declined, run ALL stages without
    the git layer: the plan lives in the final report, reviewer scope =
    files created/modified this session, "merge" = n/a, deliver = the
    final report.
  - Git repo but no GitHub remote (or no `gh`) → local branch; skip
    issue/PR; the plan lives in a `PLAN.md` in the worktree; reviewer
    scope = `git diff <default-branch>...HEAD`; "merge" = local
    `git merge --no-ff` into the default branch after the review gate.
  - Issues disabled on the repo, or no permission to create them →
    branch + PR without an issue, noted in the report.
  - The user opts out ("no issue for this one") → honor it, noted in
    the report.
  - Never silently skip a pipeline step — every degraded form is named
    in the final report.

### Stage 2 — Plan

Write a staged plan as a task list (one todo per stage). **Plan template —
every stage must fill three columns:**

| Column | Content |
|---|---|
| What / Owner | The stage's deliverable, and who executes it (lead or which agent) |
| Failable check | A concrete verification that can actually go RED (command + expected output) |
| Architecture & patterns | Structures touched, patterns applied and why, test list (TDD: tests named before code) |

A check that cannot fail ("looks good", "review the code") is not a check.

**Domain skill routing.** The plan header records the domains the task
touches (UI/visual, shadcn project, data viz, database, …) and which
installed domain skills will be consulted (`frontend-design`, `shadcn`,
`dataviz`, …). Skills compose, agents multiply: domain expertise enters
the pipeline as a skill the **lead** invokes at the right stage —
subagents cannot be assumed to see user-installed skills, so the skill's
output (aesthetic direction, token system, component conventions) flows
into executor briefs. If a matching skill is not installed, the plan says
so explicitly and proceeds on the quality doctrine alone — never a silent
degrade.

Detection is mechanical, never from memory: the lead consults the
session's available-skills listing (guessing skill names from training
data invents skills that aren't installed), matching by name and
description against a small domain→candidate table shipped in
`references/delegation.md` (UI/visual → frontend-design;
`components.json` present → shadcn; charts/plots → dataviz; …).
Plugin-namespaced variants count as matches.

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
- Does the domain-skill routing match the surfaces the task touches?

**Precondition refusal:** a plan arriving without failable checks, or
without a test list for an implementation stage, gets an instant `revise`
naming the missing precondition — the oracle does not attempt a full
review of an unreviewable plan.

Verdict is structured: `approve` or `revise` + reasons. On `revise`, the
lead updates the plan and re-submits — capped at **two revise cycles**;
on a third disagreement, present both positions (the plan and the
oracle's reasons) to the user and proceed per their call, noted in the
final report. In `/argus-mode` a `revise` may be overridden only with an
explicit user-visible justification; in `/argus-consult`, never. The
oracle always runs at its pinned `opus` tier — per-spawn model overrides
for a pinned agent do not exist in the harness, and an opus oracle is a
strong independent check even under a Fable lead.

**On `approve`, the plan becomes durable:** the lead posts the
three-column plan as an issue comment and mirrors a link in the draft
PR; at every stage completion the comment's per-stage status is updated
(done / in-flight / remaining + next failable check). This comment is
the exact resume point the handoff procedure relies on.

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
  - **Isolation model: implementers never commit.** They edit files and
    report; the lead verifies each slice, then commits it (serialized,
    Conventional Commits). Parallel fan-out is allowed only across
    disjoint file sets — two executors never mutate the same file or
    share a working tree concurrently.
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
- **Stage-transition marker (mandatory at every boundary):** print one
  line — `Stage N done — failable check: <cmd> → GREEN | next: Stage N+1`
  — before starting the next stage, and update the plan comment. This
  keeps the discipline in recent context on long runs; each stage header
  in both SKILL.md files also carries an explicit
  "Read `references/<file>.md` now" directive, so the reference is read
  at the stage that needs it, not from memory.

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
  6. **Security** — injection surfaces, authz seams, secrets in the diff,
     unsafe defaults. Checked on every review, not only on "security
     tasks".
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
- **Verdict → action mapping:** `ship` → merge. `fix-then-ship` → fix
  the findings, re-run Stage 4, merge — no fresh review required.
  `rework` → return to Stage 3 (or Stage 2 if the plan is implicated);
  a fresh Stage 5 review is mandatory afterwards; capped at two rework
  cycles, then escalate to the user. `reject` → stop; do not merge;
  report the reviewer's reason to the user.
- On merge: flip the draft PR to ready, merge (issue auto-closes).
- Final report to the user: what shipped, evidence (test output, PR link),
  anything skipped and why.

## Skill 2: `/argus-consult`

Target lead models: **Sonnet, Haiku** (also usable by any non-Fable/Opus
lead). Same pipeline, same references, with three **mandatory oracle
checkpoints** — the big model is paid for only at quality-critical decision
points while the cheap model does all execution:

1. **After Plan:** the same Stage 2.5 gate; the lead must apply the
   verdict (no override path in consult mode).
2. **During Execute — objective triggers, not felt uncertainty:** consult
   `argus-oracle` whenever (a) execution deviates from the approved
   plan's stages or test list, (b) a new module, interface, or dependency
   not named in the plan is about to be created, or (c) a stage's
   failable check fails twice. Feeling uncertain remains a valid extra
   trigger — but the three above are mandatory and mechanically
   checkable, because a small model that is confidently wrong feels no
   uncertainty.
3. **Before Deliver:** `argus-reviewer` is NOT spawned in consult mode —
   `model: inherit` would grade the gate at the small lead's own tier.
   The oracle performs the final review instead, applying the same
   6-dimension rubric, the same reviewer operating rules (end-to-end
   tracing, no rubber-stamps, `file:line` citations), and the same
   `ship / fix-then-ship / rework / reject` verdict with the same
   verdict→action mapping. The GREEN precondition holds: the lead
   attaches the verbatim Stage 4 command and its full output to the
   review brief, and the oracle audits that evidence (command, suite
   scope, freshness) rather than re-running the suite itself.

Slice acceptance under a small lead stays mechanical: the lead runs each
slice's failable check against its written acceptance criteria and
confirms the output; judgment calls about slice quality fold into
checkpoint 3's oracle review rather than per-slice oracle calls.

`/argus-consult` recites the same Argus creed (from
`references/creed.md`) once its pipeline engages, and contains the
reverse gate: on a Fable/Opus session it announces the redirect and runs
the `/argus-mode` pipeline directly in the same turn — no stop, no
retyping.

## Agents

All agent files state explicitly in their system prompt: *you inherit no
CLAUDE.md, no conversation history — the brief is your whole world.* Each
embeds the conventions it needs (Conventional Commits, the quality
doctrine, TDD).

"Read-only" is a **prompt-level contract**: agent frontmatter can allow
or deny whole tools, not modes of a tool, so read-only agents simply
omit Bash where possible and the reviewer's Bash grant is scoped by its
system prompt to running the test suite. Mechanical enforcement via a
`PreToolUse` hook stays a Future Idea.

| Agent | Model | Tools | Mandate |
|---|---|---|---|
| `argus-oracle` | `opus` (pinned) | Read, Grep, Glob (no Bash) | Advisor, never executor. Three duties: plan review (mandatory simpler-alternative pass, then the goal-backward rubric; structured verdict; instant `revise` on missing preconditions), architecture consultation (decision + rationale + risks), and — in consult mode — the final review, applying the reviewer's 6-dimension rubric and `ship/fix-then-ship/rework/reject` verdict while auditing the lead's attached test evidence instead of re-running it. Returns analysis; never edits files. |
| `argus-explorer` | `haiku` | read-only | Fast codebase reconnaissance; returns findings as structured summaries with `file:line` references, not file dumps. |
| `argus-implementer` | `sonnet` | all | Executes one self-contained implementation slice TDD-first. Quality bar embedded: docblocks on public API, SOLID, small modules, justified patterns, refactor leg mandatory, secure by default (doctrine #6). Edits files but **never commits** — the lead verifies and commits each slice. |
| `argus-reviewer` | `inherit` | Read, Grep, Glob + Bash (scoped by prompt to test runs) | The 6-dimension review gate. Refuses non-GREEN diffs; runs the test suite itself (may scope to affected targets, citing the lead's Stage 4 full-suite output as baseline); traces beyond the diff; never rubber-stamps; findings cite `file:line`; verdict `ship / fix-then-ship / rework / reject`. Not spawned in `/argus-consult` — the oracle takes this duty there. |

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
6. **Secure by default.** No injection surfaces, authorization respected
   at every seam, no secrets in code or diffs, safe defaults. Security is
   part of the writer's bar, not only the reviewer's — the reviewer's
   sixth dimension audits what the implementer already owed.

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
- **Context budget — count signals, don't estimate:** 60+ turns into the
  task; 25+ files read or a single huge (>50k-token) file/log; long
  outputs being re-scrolled repeatedly. Two or more true → finish the
  current atomic step, then **propose** a handoff to the user with the
  per-stage status. (An authoritative low-context system warning still
  means hand off now, no proposal.) "Almost done" does not cancel the
  proposal.
- **Clean handoff — the pipeline is resumable by construction:** the
  issue, the draft PR, and the plan comment posted at Stage 2.5 already
  hold the durable state (degraded modes: `PLAN.md` in the worktree). To hand off: commit work in progress, update the
  plan comment with per-stage status (done / in-flight / remaining, plus
  the next failable check), then tell the user to start a fresh session —
  it resumes from the issue/PR state instead of a hand-written summary.

## Distribution

- `.claude-plugin/plugin.json` — plugin manifest (`name: "argus-mode"`).
- `.claude-plugin/marketplace.json` — intended: the repo doubles as its
  own marketplace (`/plugin marketplace add parsilver/argus-mode`, then
  install `argus-mode`). The docs do not explicitly confirm the
  single-repo dual role — verify first during implementation (see
  Validation item 1); fallback: move the plugin into a subdirectory
  listed by marketplace.json, or split the marketplace into its own repo.
- Skill invocation is always namespaced by Claude Code: the real
  commands are `/argus-mode:run` and `/argus-mode:consult`. Unqualified
  `/argus-mode` resolution is NOT documented platform behavior — the
  README documents the real commands.
- `npx skills add parsilver/argus-mode` (third-party, vercel-labs) is a
  **skills-only** install: the agents ship only with the Claude Code
  plugin. Both SKILL.md files therefore check agent availability first;
  when the agents are missing, the oracle/reviewer passes run inline by
  the lead — a weaker gate, declared openly in the final report (never a
  silent degrade). The README states this limitation.

## Cost & Expectations (README: "What this costs")

The pipeline trades tokens and wall-clock for quality, and says so up
front. The README carries a "What this costs" section and each SKILL.md
opens with a one-line expectation: a medium task pays the git ceremony,
at least one opus oracle run (more on revise loops), and a review-gate
run. `/argus-consult` is the cheap-**execution** path, not a cheap path —
its mandatory oracle checkpoints can exceed a plain small-model session's
cost. Guidance on when NOT to invoke sits beside the install
instructions.

## Repo Conventions (root `CLAUDE.md`)

The repo carries a root `CLAUDE.md` locking consistency invariants, so
any future session editing this repo preserves them automatically:

- Every skill has an entry in the top-level `README.md` (name linked to
  its `SKILL.md`); list skills in `.claude-plugin/plugin.json` only if
  the current manifest schema supports a skills field (verify at
  implementation — `skills/` auto-discovery may make it redundant).
- Every agent appears in the README agent table with its model + mandate.
- `references/` files are shared by both skills — a change there changes
  both pipelines; re-read both SKILL.md files to confirm they still hold.
- Version bumps update `plugin.json` and `CHANGELOG.md` together.

## Validation

Before tagging `v0.1.0`:

1. **Platform assumptions first** (fail fast, before building on them):
   the single-repo plugin+marketplace dual role installs cleanly via
   `/plugin marketplace add`; the plugin.json schema's skills field (or
   `skills/` auto-discovery); `${CLAUDE_PLUGIN_ROOT}`-based references
   resolve from both skills after a real install.
2. `plugin-dev:plugin-validator` agent — structural validation of
   plugin.json / marketplace.json / skills / agents. (plugin-dev is a
   development dependency — noted in the README.)
3. `plugin-dev:skill-reviewer` agent — quality review of both SKILL.md
   files (triggering, clarity, progressive disclosure).
4. Manual smoke tests — each designed to actually exercise its claim:
   - End-to-end: a small two-file feature with tests, explicitly above
     the triviality bar, on an Opus session → full pipeline; plan comment
     posted and updated; draft PR flips to ready on merge.
   - Gate: `/argus-mode` on a Sonnet session → hard stop with the three
     doors; "proceed anyway" honored and recorded in the report.
   - Checkpoint 2: a seeded ambiguous-architecture task (two viable
     designs stated in the prompt) on `/argus-consult` → an objective
     trigger fires and the oracle is consulted mid-execution.
   - Degradation: a repo with no remote → `PLAN.md` fallback, local
     `git merge --no-ff`, degraded steps named in the report.
   - Handoff/resume: kill the session mid-Stage 3 → a fresh session
     resumes from the issue/PR plan comment.
   - Escape hatch: a genuinely trivial task → declined with the
     classification announced, no creed recital.

## Future Ideas (explicitly out of scope for v0.1)

- A `PreToolUse` hook enforcing the model gate mechanically.
- Workflow-tool orchestration scripts for large fan-outs.
- Per-language quality profiles (e.g., PHP/Laravel, TypeScript presets).
- Specialist review lenses (security / a11y / performance) as parallel
  runs of the same `argus-reviewer` with a lens parameter — extra eyes,
  not extra agents.

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
