---
name: consult
description: The argus-mode pipeline for Sonnet/Haiku leads — the small model executes while a pinned-opus oracle gates the plan, arbitrates architecture, and performs the final review. Trigger when the user invokes /argus-mode:consult or asks for the argus pipeline on a smaller model. Not for trivial lookups or edits the triviality hatch covers.
---

# /argus-mode:consult — small-model lead + oracle checkpoints

Runs the same disciplined pipeline as `/argus-mode:run` for a Sonnet/Haiku
lead: the small model leads all execution; a pinned-`opus`
`argus-oracle` gates the plan, arbitrates architecture mid-execution, and
performs the final review. Three oracle checkpoint **types**; two always
fire (plan review, final review), the mid-execution one fires whenever its
objective triggers do. Expect at minimum: the git intake ceremony, one
`argus-oracle` plan-review run (more on revise cycles), and one oracle-led
final review. This is not a cheap path — see "What this costs" at the end
before invoking it on routine work.

The `${CLAUDE_PLUGIN_ROOT}/references/` files are the source of truth: on
any conflict between a summary in this file and a reference file, the
reference wins.

## Agent availability check (run this before Stage 0)

Skills-only installs (e.g. `npx skills add`) ship no agents. Check that
`argus-oracle`, `argus-explorer`, and `argus-implementer` exist as
spawnable agents. If `argus-oracle` is unavailable:

- **Announce it to the user now**, plainly — not in the final report
  alone. In consult mode this degrade is severe: a small lead grading its
  own work is exactly what the oracle exists to prevent. Offer the user
  the choice before proceeding: switch to a Fable/Opus session (or a full
  plugin install), or explicitly accept inline gates.
- On acceptance, run each checkpoint **inline** — same rubric, same
  precondition refusal, same verdict set — and state in the final report
  that every gate ran inline, not via an independent agent.
- Missing executors degrade the same way as in `/argus-mode:run`: Stage 3
  fan-out has no agents, so the lead executes every slice **solo**, in
  plan order, under the same TDD and verification rules — announced, not
  silent.
- On a skills-only install `${CLAUDE_PLUGIN_ROOT}` may be unset and the
  `references/` files unreachable — if a "Read now" target can't be read,
  run from this file's summaries and announce that too.
- Never silently skip a checkpoint because the agent isn't installed.

## Stage 0 — Model gate (reverse)

Check the session model exactly as `/argus-mode:run` Stage 0 does — the
system prompt's "You are powered by the model named …" / model ID,
substring match on the tier token (not a prefix whitelist).

- Model ID contains `fable` or `opus` → this is the **wrong** skill for
  this session. Announce the redirect in one line, then **read
  `${CLAUDE_PLUGIN_ROOT}/skills/run/SKILL.md` and follow it in full —
  from its agent-availability check onward — in this same turn**; no
  stop, no re-ask, no retyping. The user asked for the workflow; which
  skill name got them there is an implementation detail.
- Otherwise (Sonnet, Haiku, or any other non-Fable/Opus tier) → this is
  the right skill. Continue below.

## Stage 1 — Intake

Read `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` now — it opens with
the canonical triviality escape hatch (apply it first; trivial → announce,
handle directly, stop — summary: ≤3 changed lines AND one file AND no
public-API/behavior change AND no new test warranted; a bugfix is never
trivial; read-only lookups are trivial if answerable from one file),
then the read-only-work route (non-trivial lookups skip the git intake
entirely — plan, explore, report per the route's report contract; its
landing rule decides where findings live, chat or a `question`-labeled
issue), the ambiguity gate (a new capability with unstated
requirements gets clarified with the requester before the issue is
written), the git intake (issue with its
fields filled and added to the repo's project board when one exists →
branch/worktree → draft PR), and the full degradation table. Once the triviality check clears
and the pipeline engages, read `${CLAUDE_PLUGIN_ROOT}/references/creed.md`
and recite the creed verbatim, once — never before the check, never again
mid-pipeline. Nothing about intake changes in consult mode — same escape
hatch, same re-entry rule, same degraded forms when there's no repo, no
remote, or no `gh`.

## Stage 2 — Plan

Read `${CLAUDE_PLUGIN_ROOT}/references/quality.md` now for the doctrine the
plan must satisfy, `${CLAUDE_PLUGIN_ROOT}/references/delegation.md` now
for the domain-skill routing table, and
`${CLAUDE_PLUGIN_ROOT}/references/verification.md` now for what a
failable check is — the plan's middle column is written against that
definition, not discovered at the gate. Write the same three-column plan as
`/argus-mode:run` — What/Owner, Failable check, Architecture & patterns —
with a domain header recording which installed skills apply and which
don't (never guessed from memory). Scout before you plan applies
unchanged (`pipeline.md`): surfaces not read this session get their
reconnaissance questions answered first, recorded as a `Scouted:` line
in the plan header. The decomposition test applies
unchanged (`pipeline.md`): an oversized plan splits into a parent
issue with sub-issues, one PR each. The plan's shape doesn't change in
consult mode; what happens to it next does.

## Stage 2.5 — Plan review gate (checkpoint 1 of 3)

Read `${CLAUDE_PLUGIN_ROOT}/references/verification.md` now for the full
rubric: the mandatory simpler-alternative pass first, the goal-backward
review, and instant precondition refusal on a plan with no failable checks
or no test list.

Spawn `argus-oracle` with the plan, the task statement, relevant repo
context, and a pointer to `${CLAUDE_PLUGIN_ROOT}/references/verification.md`
as the rubric's source of truth — the identical gate `/argus-mode:run`
runs, with one binding difference:

| | `/argus-mode:run` | `/argus-mode:consult` |
|---|---|---|
| `revise` verdict | may be overridden with an explicit user-visible justification | **no lead override** (the user still decides at the two-cycle escalation) |
| Revise-cycle cap | two, then escalate to the user | same: two, then escalate to the user (board Status → Blocked while waiting, when a board exists) |

The lead **must** apply the oracle's verdict. On `approve`, the plan
becomes durable exactly as in `/argus-mode:run`: post it as an issue
comment — or the degraded location from `pipeline.md`'s degradation table
(`PLAN.md` with no remote; the PR description when only issues are
unavailable) — mirror a link in the draft PR, and update it at every
stage completion. The comment is a git artifact: team voice per
`git-conventions.md`, lexicon check before every post and edit.

## Stage 3 — Execute (checkpoint 2 of 3)

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation.md` now for brief
discipline, the isolation model (implementers never commit), and the
solo-vs-fan-out criteria. Read `${CLAUDE_PLUGIN_ROOT}/references/on-track.md`
now for loop-breaking, context budget, and the mandatory stage-transition
marker.

Same execution model as `/argus-mode:run`: TDD red → green → refactor,
solo vs. fan-out per the same criteria, `argus-implementer` never commits,
the lead verifies and commits every slice. The delta is **when the lead
stops and calls `argus-oracle` mid-execution.**

**Three objective triggers — mandatory, mechanically checkable, not a
feeling:**

| # | Trigger | Why it's mandatory |
|---|---|---|
| a | Execution is about to deviate from the approved plan's stages or test list | a small lead silently re-scoping is exactly the failure mode the oracle exists to catch |
| b | A new module, interface, or dependency **not named in the approved plan** is about to be created | architecture decisions are never delegated — the oracle is the architecture gate under a small lead |
| c | A stage's failable check has failed **twice** | a third blind retry is already forbidden by `on-track.md` — consult the oracle instead of trying again |

Felt uncertainty is a valid **fourth, optional** trigger — never a
substitute for checking a, b, and c. A confidently wrong small model feels
no uncertainty; the three mechanical triggers catch what the feeling won't.

On any trigger: stop, state the deviation/new-dependency/failure in one
sentence, spawn `argus-oracle` with the plan, the stage in question, and
what's proposed. Apply its verdict before continuing — same as checkpoint
1, no override path.

A red failable check also starts the diagnose loop in
`${CLAUDE_PLUGIN_ROOT}/references/debugging.md` (or the `debug-mantra`
skill when installed) — run it from the **first** failure; when trigger
(c) fires on the second, bring the loop's ledger to the oracle rather
than attempting a third run.

**Slice acceptance stays mechanical.** The lead runs each slice's failable
check against its written acceptance criteria and confirms the output —
this is not a fourth oracle checkpoint. Judgment calls about slice
*quality* (beyond pass/fail) fold into checkpoint 3's final review; never
spawn the oracle per slice.

Print the stage-transition marker at every boundary —
`Stage N done — failable check: <cmd> → GREEN | next: Stage N+1` — and
update the plan comment, exactly as in `/argus-mode:run`. The marker is
session-only — never posted to GitHub; the comment update follows the
team-voice contract in `git-conventions.md`.

## Stage 4 — Verify

Same as `/argus-mode:run`: run the actual build/test/lint commands, read
the output, GREEN evidence required before any "done" claim. A red check
is reported red — never merged over, never rationalized away.

One consult-specific requirement: **capture the exact command and its
full output verbatim.** Checkpoint 3 hands this to the oracle instead of
letting it re-run the suite — a paraphrased "tests passed" is not evidence
the oracle can audit.

## Stage 5 — Review & deliver (checkpoint 3 of 3)

Read `${CLAUDE_PLUGIN_ROOT}/references/verification.md` now for the
reviewer operating rules and the 6-dimension rubric, and
`${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` again for the
verdict→action mapping and the degraded merge semantics. When a
project board exists, set its Status to In Review as this gate begins
(`pipeline.md`, Project-board sync).

**`argus-reviewer` is not spawned in consult mode** — its `model: inherit`
would grade the gate at the small lead's own tier, defeating the point of
an independent review. `argus-oracle` performs the final review instead,
holding the identical bar:

- Same 6 dimensions: correctness, readability (docblocks, intent-revealing
  names), architecture fit, pattern justification, test quality, security.
- Same operating rules: end-to-end tracing beyond the diff, no
  rubber-stamps ("LGTM" is not an output — report what was traced and
  checked), every finding cites `file:line`, report format is
  Finding / Why it matters / Evidence / Suggested change, ordered by
  severity.
- Same verdict set and mapping:

| Verdict | Action |
|---|---|
| `ship` | merge |
| `fix-then-ship` | fix the findings, re-run Stage 4, merge — no fresh review required |
| `rework` | return to Stage 3 (or Stage 2 if the plan is implicated); fresh Stage 5 review mandatory after; capped at two rework cycles, then escalate to the user (board → Blocked while waiting) |
| `reject` | stop; do not merge; report the oracle's reason to the user |

**Subjective-goal hold applies unchanged:** on a perceptual goal (visual fidelity, "looks like X"), a merging verdict — `ship`, or `fix-then-ship` once its fixes are re-verified — readies the PR and posts the comparison evidence, but the merge waits for the user's explicit acceptance; every rejection cycle re-runs Stage 4 and this gate before the next ask (`pipeline.md`, Subjective goals).

**Precondition refusal still holds:** a non-GREEN diff gets an instant
refusal naming the missing evidence, not a review.

**Evidence handling is the one structural difference from
`/argus-mode:run`:** the review brief must carry, verbatim —
1. **the diff itself** (patch text, or changed-file list + base ref the
   oracle can Read against — it has no Bash and cannot run `git diff`),
2. the Stage 4 command and its full output,
3. the **HEAD commit SHA at the moment the Stage 4 command ran**, so
   freshness is checkable instead of taken on the lead's word, and
4. **the git-artifact text this run produced** — issue body, PR
   description, the current plan comment — so the team-voice check
   (dimension 2) has something to read; the oracle cannot fetch
   GitHub content itself.

The oracle audits that evidence — command, suite scope, freshness,
artifact voice — rather than re-running the suite itself (unlike
`argus-reviewer`, which may re-run tests). A missing diff, missing SHA,
missing artifact text, or stale/ambiguous output is an instant refusal
naming the gap: the oracle never reviews blind, and never audits
evidence it can't trust.

On `ship` / `fix-then-ship`: update the PR description's "How it was
verified" section with the Stage 4 command and its result — PR text in
the team voice per `git-conventions.md` — flip the draft PR to ready,
merge — issue auto-closes (degraded modes: local `git merge --no-ff`
per `pipeline.md`). Set the board Status to Done on merge, when a
board exists. Final report to the user: what shipped, evidence,
anything skipped and why — same shape as `/argus-mode:run`.

## What this costs

`/argus-mode:consult` is the cheap-**execution** path, not a cheap path.
Three mandatory oracle checkpoints — plan review, potentially several
mid-execution consults, and the final review — run at the pinned `opus`
tier regardless of what the lead costs. On a task with real architectural
ambiguity or a rocky execution (checkpoint 2 firing more than once), this
pipeline can cost **more** in tokens and wall-clock than a plain
Sonnet/Haiku session doing the same work with no gates — that is the
trade being made, not a bug. Reach for it when the quality bar matters and
the lead isn't Fable/Opus; skip it for throwaway scripts or genuinely
trivial edits (Stage 1's triviality hatch still applies).
