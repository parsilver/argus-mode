---
name: consult
description: The argus-mode pipeline for Sonnet/Haiku leads — the small model executes while a pinned-opus oracle gates the plan, arbitrates architecture, and performs the final review. Trigger when the user invokes /argus-mode:consult or asks for the argus pipeline on a smaller model.
---

# /argus-mode:consult — small-model lead + oracle checkpoints

Runs the same disciplined pipeline as `/argus-mode:run` for a Sonnet/Haiku
lead: the small model does all reading, writing, and testing; a pinned-`opus`
`argus-oracle` gates the plan, arbitrates architecture mid-execution, and
performs the final review. Expect at minimum: the git intake ceremony, one
`argus-oracle` plan-review run (more on revise cycles), zero or more
mid-execution oracle consults, and one oracle-led final review. This is not
a cheap path — see "What this costs" at the end before invoking it on
routine work.

## Stage 0 — Model gate (reverse)

Check the session model exactly as `/argus-mode:run` Stage 0 does — the
system prompt's "You are powered by the model named …" / model ID,
substring match on the tier token (not a prefix whitelist).

- Model ID contains `fable` or `opus` → this is the **wrong** skill for
  this session. Announce the redirect in one line and run the
  `/argus-mode:run` pipeline's Stage 0–5 directly, in this same turn —
  no stop, no re-ask, no retyping. The user asked for the workflow; which
  skill name got them there is an implementation detail.
- Otherwise (Sonnet, Haiku, or any other non-Fable/Opus tier) → this is
  the right skill. Continue below.

## Stage 1 — Intake

Read `${CLAUDE_PLUGIN_ROOT}/references/creed.md` now and recite it once the
triviality check clears (never before, never again mid-pipeline). Read
`${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` now for the triviality hatch,
git intake (issue → branch/worktree → draft PR), and the full degradation
table. Nothing about intake changes in consult mode — same escape hatch,
same re-entry rule, same degraded forms when there's no repo, no remote, or
no `gh`.

## Stage 2 — Plan

Read `${CLAUDE_PLUGIN_ROOT}/references/quality.md` now for the doctrine the
plan must satisfy, and `${CLAUDE_PLUGIN_ROOT}/references/delegation.md` now
for the domain-skill routing table. Write the same three-column plan as
`/argus-mode:run` — What/Owner, Failable check, Architecture & patterns —
with a domain header recording which installed skills apply and which
don't (never guessed from memory). The plan's shape doesn't change in
consult mode; what happens to it next does.

## Stage 2.5 — Plan review gate (checkpoint 1 of 3)

Read `${CLAUDE_PLUGIN_ROOT}/references/verification.md` now for the full
rubric: the mandatory simpler-alternative pass first, the goal-backward
review, and instant precondition refusal on a plan with no failable checks
or no test list.

Spawn `argus-oracle` with the plan, the task statement, and relevant repo
context — the identical gate `/argus-mode:run` runs, with one binding
difference:

| | `/argus-mode:run` | `/argus-mode:consult` |
|---|---|---|
| `revise` verdict | may be overridden with an explicit user-visible justification | **no override path — ever** |
| Revise-cycle cap | two, then escalate to the user | same: two, then escalate to the user |

The lead **must** apply the oracle's verdict. On `approve`, the plan
becomes durable exactly as in `/argus-mode:run`: post it as an issue
comment (or `PLAN.md` in degraded mode), mirror a link in the draft PR,
update per-stage status at every stage completion.

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

**Slice acceptance stays mechanical.** The lead runs each slice's failable
check against its written acceptance criteria and confirms the output —
this is not a fourth oracle checkpoint. Judgment calls about slice
*quality* (beyond pass/fail) fold into checkpoint 3's final review; never
spawn the oracle per slice.

Print the stage-transition marker at every boundary —
`Stage N done — failable check: <cmd> → GREEN | next: Stage N+1` — and
update the plan comment, exactly as in `/argus-mode:run`.

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
reviewer operating rules and the 6-dimension rubric.

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
| `rework` | return to Stage 3 (or Stage 2 if the plan is implicated); fresh Stage 5 review mandatory after; capped at two rework cycles, then escalate to the user |
| `reject` | stop; do not merge; report the oracle's reason to the user |

**Precondition refusal still holds:** a non-GREEN diff gets an instant
refusal naming the missing evidence, not a review.

**Evidence handling is the one structural difference from
`/argus-mode:run`:** attach the Stage 4 command and its full output
**verbatim** to the review brief. The oracle audits that evidence —
command, suite scope, freshness — rather than re-running the suite itself
(unlike `argus-reviewer`, which may re-run tests). If the attached
evidence is stale, ambiguous, or doesn't cover the changed surface, that
is itself a `revise`-equivalent finding: the oracle refuses to audit
evidence it can't trust.

On `ship` / `fix-then-ship`: flip the draft PR to ready, merge, issue
auto-closes. Final report to the user: what shipped, evidence, anything
skipped and why — same shape as `/argus-mode:run`.

## Agent availability fallback

Skills-only installs (e.g. `npx skills add`) ship no agents. If
`argus-oracle` is unavailable, the lead runs each checkpoint **inline** —
same rubric, same precondition refusal, same verdict set — and the final
report states openly that the gate ran inline, not via an independent
agent. Never silently skip a checkpoint because the agent isn't installed.

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
