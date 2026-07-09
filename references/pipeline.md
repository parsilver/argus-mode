# Pipeline

The git/GitHub mechanics shared by both skills: how work enters the repo
(Stage 1), how the plan stays durable and visible (Stage 2.5 onward), what
degrades when the platform doesn't cooperate, and how a Stage 5 verdict
turns into an action. Read this file at Stage 1, and again at Stage 5.

## Stage 1 — Triviality escape hatch (run this first)

Canonical definition, shared by both skills. Trivial means ALL of:

- ≤3 changed lines, AND
- one file, AND
- no public-API or behavior change — a bugfix changes behavior, so a
  bugfix is never trivial, AND
- no new test warranted.

Read-only lookups: trivial if answerable from one file.

Trivial → announce the classification ("this is a trivial edit — skipping
the pipeline"), handle it directly, stop. No creed, no ceremony.

**Re-entry rule:** if the "trivial" edit turns out to need a second edit,
a second file, or its first check fails → stop, announce the
reclassification, and enter the full pipeline at the git intake below.

- Refusal condition: the hatch is not a bypass valve — a borderline task
  classified trivial without announcing the classification is an
  undisclosed skip of the pipeline.

## Read-only work (non-trivial lookups)

Analysis, investigation, or a question that needs more than one file
fails the hatch but produces **no diff and nothing to merge** — it never
enters the git intake. Route: plan (Stage 2) → oracle plan review →
explore/verify → deliver as the final report. No issue, no branch, no
PR; say so in the report. The moment the work turns out to need a code
change, re-enter at the git intake below.

## Stage 1 — Git intake

Run these four steps, in order, when the project is a git repo. (No repo,
no remote, no `gh`, no issue permission — see Degradation rules below;
each has a defined substitute for these steps, never a silent skip.)

**Every name and message these steps produce follows
`git-conventions.md` — read it together with this file.** Branches,
commits, issues, and PRs land on shared repos and are read by developers
with zero session context; the conventions are part of the deliverable,
not decoration.

1. `git fetch origin`, then fast-forward the default branch to origin —
   branch off the latest, not a stale local copy.
2. Create a GitHub issue describing the work: `gh issue create` — title
   and description per `git-conventions.md` (failable acceptance
   criteria; bugs carry expected/actual, repro steps, verbatim
   evidence).
3. Branch — named `<issue-number>-<short-kebab-slug>`:
   - `gh issue develop <n>` (or `git switch -c` if `gh issue develop`
     isn't available).
   - Use an isolated git worktree whenever the working tree is dirty OR
     other work is in flight.
   - A clean solo checkout may branch in place — no worktree needed.
4. Bootstrap the PR immediately, before writing any implementation code:
   - Create an empty bootstrap commit.
   - Open a **draft** PR with `Closes #<n>` on the first line of the
     description; title and description contract per
     `git-conventions.md` (the title is the future squash subject).
   - This draft PR is the durable home for the plan comment (posted at
     Stage 2.5) and the per-stage status that follows it.

- Refusal condition: implementation work starting before the draft PR
  exists skips the durable-state contract every later stage depends on —
  do step 4 first, not last.
- The PR flips from draft to ready only at Stage 5, on a `ship` or
  `fix-then-ship` verdict (see the mapping below) — never before the
  review gate.

## Plan-comment lifecycle

Posted once, then kept current — this comment is the pipeline's durable
state and the exact resume point a handoff relies on (`on-track.md`).
It is also a git artifact read by humans: written in the team voice
(`git-conventions.md`) — headed "Implementation plan", plain
engineering language, no session vocabulary — and it passes the
lexicon check before the initial post and before every subsequent
edit.

| Event | Action |
|---|---|
| Stage 2.5 oracle verdict = `approve` | Post the plan as an issue comment headed "Implementation plan": the stages as a `- [ ]` task list, each item named (never numbered by pipeline stage), each carrying its done-check as `command → expected result`; design decisions with their reasons; long coordination detail folded into `<details>`. Mirror a link to it in the draft PR description. |
| Every stage completion, Stage 3 onward | Tick the finished item's checkbox and append its evidence as `command → result`. Status words for anything not checkbox-shaped: done / in progress / blocked. |
| Mid-pipeline handoff | Comment reflects state at the moment of handoff; a fresh session reads it to resume — no hand-written summary needed. |

- Commit SHAs cited in the comment stop resolving on the default
  branch after a squash-merge — cite them as PR-linked references (the
  PR keeps them alive) or as full commit URLs.
- Refusal condition: a stage boundary that passes without updating the
  comment breaks the resume contract, and a post or edit that skips
  the lexicon check ships session vocabulary to a human audience — the
  update, in the team voice, is part of finishing the stage.

## Degradation rules

Every stage has a defined degraded form. Never silently skip a pipeline
step — name the degraded form, every time it triggers, in the final
report.

| Condition | Issue / PR | Plan lives in | Reviewer scope | Merge semantics |
|---|---|---|---|---|
| No git repo | Offer `git init`; if declined, skip the git layer for every stage | The final report | Files created/modified this session | N/A — deliver = the final report |
| Git repo, no GitHub remote (or no `gh` CLI) | Local branch only; skip issue and PR | `PLAN.md` in the worktree | `git diff <default-branch>...HEAD` | Local `git merge --no-ff` into the default branch, after the review gate |
| Issues disabled on the repo, or no permission to create them | Branch + PR, no issue | Plan comment moves to the PR description (no issue thread to host it) | Normal — PR diff | Normal — merge the PR; note the missing issue in the final report |
| User opts out ("no issue for this one") | Honor it: branch + PR, no issue | Plan comment moves to the PR description | Normal — PR diff | Normal — merge the PR; note the opt-out in the final report |

- Refusal condition: a degraded form that isn't named in the final
  report is an undisclosed degrade, not a permitted one.

## Stage 5 — Verdict → action mapping

| Verdict | Action |
|---|---|
| `ship` | Flip the draft PR to ready, merge — the issue auto-closes. |
| `fix-then-ship` | Fix the findings, re-run Stage 4 (verify), then merge. No fresh review required. |
| `rework` | Return to Stage 3 (or Stage 2 if the plan itself is implicated). A fresh Stage 5 review is mandatory afterward. |
| `reject` | Stop. Do not merge. Report the reviewer's reason to the user. |

- **Rework cap: two cycles.** A third `rework` verdict on the same piece
  of work does not get a third silent attempt — escalate to the user
  with both positions (what the reviewer flagged, what was tried) and
  proceed per their call, noted in the final report.
- Refusal condition: merging over a `rework` or `reject` verdict, or
  skipping the fresh Stage 5 review after a `rework` cycle, is not a
  shortcut — it is the review gate failing to gate.
