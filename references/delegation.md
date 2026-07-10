# Delegation

Delegation is a tool, not a default. Every fan-out costs a brief, a context
copy, and a verification pass — spend that cost only when it buys more than
it takes.

## Decomposition is not fan-out

PR-level decomposition (`pipeline.md`) splits *deliverables*: each
sub-issue ships its own reviewed, mergeable PR. Fan-out here splits
*execution inside one branch*: implementer slices the lead verifies and
commits into a single PR. Size the deliverable first (decomposition),
then decide who executes each slice (fan-out) — a plan that needs five
executors is not automatically five PRs, and five PRs don't need five
executors.

## When to stay solo vs fan out

| Stay solo (lead executes in the main loop) | Fan out (delegate to agents) |
|---|---|
| Single-file change | Multi-file or multi-component work |
| Tightly coupled edits — the change ripples through interdependent lines the lead already has in view | Broad reconnaissance across the codebase |
| Briefing an agent would cost more than doing the work | Independent slices or test suites that don't share files |

Rule of thumb: if writing the brief takes longer than the edit itself, stay
solo.

## Brief discipline

Every brief to `argus-explorer` or `argus-implementer` must stand alone. The
agent inherits no conversation history, no CLAUDE.md, nothing said earlier
in this session — the brief is its whole world.

A brief is complete only when it has all four:

- **Absolute paths.** Never "the file we discussed" or "that module from
  earlier" — the agent has no earlier.
- **Explicit, checkable acceptance criteria.** At least one failable check
  (see `verification.md`) the agent (or the lead, on review) can actually
  run.
- **Restated conventions.** The quality doctrine and repo conventions the
  slice touches, copied in — not referenced. Agents don't read
  `quality.md` on their own initiative.
- **Scope boundaries.** Which files it may touch; which it must not.

### The teaching example

**Bad brief:**

> Clean up the auth module.

Fails on every axis: no path, no file, no definition of "clean up", no
acceptance criteria, and it assumes the agent already knows what "the auth
module" means from context it does not have.

**Good brief:**

> Refactor `/Users/parsilver/Projects/acme-api/src/auth/session_manager.py`.
>
> Acceptance criteria:
> - `SessionManager.validate()` and `SessionManager.refresh()` split into
>   single-responsibility methods (currently one 80-line method doing
>   both).
> - Every public method keeps or gains a docblock (Google-style, per repo
>   convention).
> - Failable check: `pytest tests/auth/test_session_manager.py` passes,
>   unchanged (no test edits).
> - Do not touch `session_store.py` or anything outside
>   `src/auth/session_manager.py`.
>
> Do not commit. Report back the diff and the test command's full output.

Passes on every axis: one absolute path, a precise definition of the
change, a check that can go RED, an explicit scope boundary, zero
references to anything said earlier.

## Context-footprint estimation

Before delegating, estimate what the agent will actually have to read to do
the work — a brief that says "understand the payments module" without
bounding it can burn an agent's whole context on file discovery before it
writes a line.

- Name the specific files or directories in scope; don't send an agent to
  "explore" an unbounded area.
- Work that reads large or many files does not go out as one brief — split
  it into bounded per-file or per-directory slices, each independently
  briefed and independently verifiable.
- If you cannot name the file list before delegating, that's a signal the
  reconnaissance itself is the task — send `argus-explorer` to produce the
  file list first, then brief `argus-implementer` against that list.

## Isolation model

The working-tree model, stated once: **shared-tree fan-out with
quiesced-tree verification.** Executors run in the session's single
working tree — subagents inherit the session's working directory, so
per-executor checkouts don't exist, and per-slice worktree plumbing
would add branch-and-merge machinery the serialized commit rule below
already provides. Isolation therefore comes from three rules: disjoint
file sets, a quiesced tree at verification time, and serialized
commits.

- **Implementers never commit.** `argus-implementer` edits files and
  reports back the diff plus its check's output — nothing more.
- **Parallel fan-out only across disjoint file sets.** Two executors
  never mutate the same file. "Mutate" includes command side effects —
  lockfiles, snapshot directories, generated artifacts — not just
  deliberate edits; two slices whose commands could rewrite the same
  artifact are not disjoint. If two slices might touch the same file,
  run them sequentially instead. At most three implementers in flight
  at once — past that, the lead's verification queue is the
  bottleneck, not executor throughput.
- **Verification happens on a quiesced tree.** The lead verifies and
  commits only when no executor is in flight — a check run while a
  sibling's half-finished edits sit in the tree can go falsely RED (a
  sibling's syntax error) or falsely GREEN (a sibling's edit masking
  the failure). Dispatch a wave, wait for every executor to return,
  then verify and commit the slices one at a time.
- **The lead verifies scope, then the check, then commits.** For each
  returned slice: run `git status` and diff the tree's mutation set
  against the union of every brief's file scope — a mutated file
  outside every scope is an undeclared overlap: stop, serialize the
  remaining slices, and re-verify both affected slices sequentially.
  Then run the slice's failable check against its acceptance criteria.
  Only after it passes does the lead commit that slice's files —
  atomic, tree GREEN after every commit, Conventional Commits format
  per `git-conventions.md`.
- **Commits are serialized.** One slice verified and committed before the
  next is accepted — never batch-accept multiple unverified slices.
- A cheaper executor is less reliable by construction — the lead's
  verification pass is not optional overhead, it's the reason delegation
  is safe at all.
- Enforcement note: "implementers never commit" is a **prompt-level
  contract** — the implementer's tool grant must include Bash for test
  runs, and tool grants cannot block `git commit` while allowing test
  commands. The lead's serialized verify-then-commit pass is the
  mechanical backstop.

## What the lead never delegates

These stay with the lead, always, regardless of how routine they look:

- **Architecture decisions** — what structure the code takes.
- **Debugging** — root-causing a failure. The lead runs the diagnose loop
  in `debugging.md` (or the `debug-mantra` skill when installed — see the
  routing table below).
- **The review gate** — Stage 5 belongs to `argus-reviewer` (or the oracle
  in consult mode), spawned and read by the lead, never skipped.
- **Verification sign-off** — declaring a check GREEN is the lead's claim,
  made against output the lead has read.
- **Merge** — flipping the PR and merging.
- **Security-sensitive edits** — auth, secrets, injection-surface code.

## Domain skill routing

Domain expertise enters the pipeline as a skill the **lead** invokes at the
right stage, not as agent capability — subagents cannot be assumed to have
the same skills installed as the lead's session. A domain skill's output
(aesthetic direction, token system, component conventions) flows into
executor briefs; it is not delegated alongside the implementation work.

**Detection rule:** consult the session's available-skills listing.
Never guess a skill name from memory — training data names skills that may
not be installed in this session, and an invented skill invocation fails
silently or worse. Match by name and description against the table below.
Plugin-namespaced variants count as matches (e.g. a plugin's
`some-plugin:frontend-design` matches a `frontend-design` row).

| Domain / signal | Candidate skill |
|---|---|
| UI/visual work — layout, palette, type, motion, interface copy | `frontend-design` |
| `components.json` present in the repo (shadcn project) | `shadcn` |
| Charts, plots, dashboards, data visualization | `dataviz` |
| Bug investigation — root-causing a failure or unexplained behavior | `debug-mantra` |
| Long user-facing prose — docs, README, release notes | `humanizer` |
| Research / deep-dive investigation — multi-file or multi-source questions | `deep-research`, `paper-research`, or any installed research skill |
| Security review beyond the standing dimension-6 check — auth design, threat surfaces | `security-review` or similar |
| Library-docs lookup — current API or version documentation for a dependency | a docs skill/server (e.g. `context7`) |
| New-capability ideation — requirements unclear, solution space open | `brainstorming` or similar |
| Post-incident or gate-miss writeup — root cause, what the gates missed | `post-mortem` or similar |
| (extend this table as new domains recur — it is a starting set, not a closed list) | — |

Several rows have stronger fallbacks than the quality doctrine alone:
no `debug-mantra` → the shipped diagnose loop in `debugging.md`; no
`humanizer` → the prose-style rules in `git-conventions.md`; no
research skill → the read-only route and its report contract
(`pipeline.md`); no security-review skill → `quality.md` principle 6
plus review dimension 6, applied deliberately rather than in passing;
no docs skill → the library's official documentation via web fetch,
never memory alone; no brainstorming skill → the ambiguity gate in
`pipeline.md` (clarify before the issue); no post-mortem skill → the
four-field record contract in `post-mortem.md`, the minimum bar either
way.

If a detected domain has no installed skill matching it, the plan states
**"no matching skill installed"** explicitly for that domain and proceeds
on the quality doctrine (`quality.md`) alone. Never a silent degrade — an
unrecorded gap looks identical to a domain nobody noticed.

## How this document is used

- **Stage 2 (Plan)** — the domain→skill table here backs the plan
  header's domain-routing record.
- **Stage 2.5 (Plan Review Gate)** — the oracle's rubric checks the plan's
  delegation choices and domain routing against this document
  (`verification.md`, rubric items 6 and 7).
- **Stage 3 (Execute)** — the solo/fan-out call, brief discipline, and
  isolation model here are the operating rules for every delegation the
  lead makes.
