# Delegation

Delegation is a tool, not a default. Every fan-out costs a brief, a context
copy, and a verification pass — spend that cost only when it buys more than
it takes.

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

- **Implementers never commit.** `argus-implementer` edits files and
  reports back the diff plus its check's output — nothing more.
- **The lead verifies, then commits.** For each returned slice, the lead
  runs the slice's failable check against its acceptance criteria itself.
  Only after it passes does the lead commit it — atomic, tree GREEN after
  every commit, Conventional Commits format per `git-conventions.md`.
- **Commits are serialized.** One slice verified and committed before the
  next is accepted — never batch-accept multiple unverified slices.
- **Parallel fan-out only across disjoint file sets.** Two executors never
  mutate the same file or share a working tree concurrently. If two
  slices might touch the same file, run them sequentially instead.
- A cheaper executor is less reliable by construction — the lead's
  verification pass is not optional overhead, it's the reason delegation
  is safe at all.

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
| (extend this table as new domains recur — it is a starting set, not a closed list) | — |

Two rows have stronger fallbacks than the others: when no `debug-mantra`
skill is installed, the lead runs the shipped diagnose loop in
`debugging.md`; when no `humanizer` skill is installed, the prose-style
rules in `git-conventions.md` apply — in neither case does the fallback
degrade to the quality doctrine alone.

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
