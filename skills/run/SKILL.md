---
name: run
description: The argus-mode engineering pipeline for Fable/Opus leads — staged plan with failable checks, independent oracle plan review, TDD execution with delegated agents, 6-dimension review gate before merge. Trigger when the user invokes /argus-mode:run, or the argus pipeline is requested in a session running on a Fable or Opus model. Not for trivial lookups or edits the triviality hatch covers.
---

# /argus-mode:run — the Argus Mode pipeline

The `${CLAUDE_PLUGIN_ROOT}/references/` files are the source of truth: on
any conflict between a summary in this file and a reference file, the
reference wins.

**Cost, up front:** a medium task pays the git ceremony (issue + branch/worktree + draft PR), at least one `argus-oracle` (opus) plan-review run — more on revise cycles — and an `argus-reviewer` review-gate run. Do **not** invoke this for a trivial lookup or anything the Stage 1 triviality hatch covers (≤3 changed lines AND one file AND no public-API or behavior change AND no new test warranted — a bugfix never qualifies) — handle those directly instead.

## Agent availability check

Before Stage 0, check whether `argus-oracle`, `argus-explorer`, `argus-implementer`, and `argus-reviewer` exist as spawnable agents (true on a Claude Code plugin install; not true on a skills-only install, e.g. `npx skills add`).

- Any missing → **announce this to the user now**, plainly, naming which agents are absent. Never degrade silently.
- **Scope each degrade to the agent that is actually missing.** No `argus-oracle` → Stage 2.5 (the plan-review gate) runs **inline**; no `argus-reviewer` → Stage 5 (the review gate) runs **inline**; both apply the same rubrics from `${CLAUDE_PLUGIN_ROOT}/references/verification.md` and `${CLAUDE_PLUGIN_ROOT}/references/quality.md`. An agent that is present still runs its own gate — a missing reviewer does not push the plan review inline, and vice versa.
- No `argus-explorer` / `argus-implementer` → Stage 3 fan-out has no executors: the lead executes every slice **solo**, in plan order, under the same TDD and verification rules.
- Any gate the lead runs inline is a **weaker gate** — the lead grading its own work. State plainly in the Deliver section of the final report which gates ran inline and why.
- On a skills-only install `${CLAUDE_PLUGIN_ROOT}` may be unset and the `references/` files unreachable. If a "Read now" target can't be read, run from this file's summaries, announce that too, and treat the references as authoritative the moment they're available again.

## Stage 0 — Model gate

Check the session's model ID (system prompt: "You are powered by the model named …"). Accepted: the ID contains `fable` or `opus` as a substring — a case-insensitive substring match on the exact model ID (not the display name), not a prefix whitelist. The substring is a deliberate trade: every future model whose ID carries a top-tier token passes without a skill update, and a future top-tier model named something else entirely hard-stops into the three doors below — for unrecognized names the gate fails toward asking, not toward passing.

Not accepted → **hard stop**. Present exactly these three doors; do not proceed on any other outcome:

1. Switch model (`/model`) and re-run this skill.
2. Continue under the consult pipeline instead — offer this; on the user's yes, read `${CLAUDE_PLUGIN_ROOT}/skills/consult/SKILL.md` and follow it in that same turn, carrying the user's original request over so nothing is retyped. When that path is unreachable (skills-only install), invoke the installed consult skill by name instead — the redirect is to the skill, not the file.
3. User explicitly replies "proceed anyway" → run on the current model with reduced guarantees. Record the override and the user's stated reason in the final report. Under this override, Stage 5 routes to `argus-oracle` (final-review duty, consult evidence brief: diff as patch text or an on-disk patch file — written outside the repo tree (the session's scratch directory), or removed before any later commit — verbatim Stage 4 command and output, run-time HEAD SHA, produced git-artifact text, and a pointer to `${CLAUDE_PLUGIN_ROOT}/references/verification.md` as the rubric's source of truth) instead of `argus-reviewer` — the reviewer's `model: inherit` would grade the gate at the overriding lead's own tier. Record the substitution in the final report.

Never warn-and-continue past a failed gate silently.

Exception: a task that plainly clears the Stage 1 triviality hatch may be handled directly without the model gate — announce the classification as usual. The gate protects the pipeline; work the pipeline itself would decline needs no protecting.

## Stage 1 — Intake

### Triviality escape hatch

Canonical definition lives in `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md`. Summary: trivial = ALL of ≤3 changed lines, one file, no public-API or behavior change (a bugfix changes behavior — a bugfix is never trivial), no new test warranted. (Read-only lookups: trivial if answerable from one file.)

Trivial → announce the classification ("this is a trivial edit — skipping the pipeline"), handle it directly, stop. No creed, no ceremony.

**Re-entry rule:** if the "trivial" edit turns out to need a second edit, a second file, or its first check fails → stop, announce the reclassification, re-enter at Stage 1 proper (full pipeline, from git intake). The hatch is not a bypass valve for the pipeline. The rule survives the commit: a hatch edit that fails after it was committed or pushed re-enters the full pipeline the same way, and a broken commit it left on the default branch is reverted first (`pipeline.md`, re-entry rule).

**Non-trivial read-only work** (analysis or a question needing more than one file) — **read `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` now** and take its read-only route: plan, oracle review, explore, report. The report follows the route's report contract (question → searched → `file:line`-cited findings → open questions), and its landing rule decides where findings live: chat for one-shot answers, a `question` issue when they feed later work, outlive the session, or hand off mid-run — except a finding exposing a vulnerability in a public repo which never lands on a public issue. Degraded (no repo, no remote, or issues disabled): offer a committed report file, else deliver in chat and name the degrade. It re-enters the git intake the moment it turns into a code change.

### Pipeline engagement

Once the task clears the triviality check, the pipeline engages: **read `${CLAUDE_PLUGIN_ROOT}/references/creed.md` now and recite the Argus creed verbatim, once.** Never recite it again for the rest of this run.

### Git intake

For a new capability whose acceptance criteria can't be derived from the
request, the ambiguity gate applies — clarify with the requester before
the issue is written (`pipeline.md`, Ambiguous ask).

**Read `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` and `${CLAUDE_PLUGIN_ROOT}/references/git-conventions.md` now** — pipeline.md is the flow (follow it exactly, including its degradation rules); git-conventions.md is the naming, message, prose-style, diagram, and decision-record standard every artifact below follows.

**Resume first (`pipeline.md`, Resume — the receiving side):** when the request names an existing issue, PR, or branch — or an in-flight branch whose plan comment already covers this task — adopt that state instead of creating new artifacts: reconcile the plan comment against the branch's commit log (the log outranks the comment), apply any recorded-but-unapplied review outcome, and enter at the first open item. The steps below create state only when none exists:

1. `git fetch origin`. The base is `origin/<default>`; fast-forward the local default branch only when this run branches in place (per the step-3 in-flight probe) — never when it takes a worktree, which branches straight off `origin/<default>`.
2. `gh issue create` describing the work — filling every metadata dimension the repo actually has per `pipeline.md`'s Issue metadata contract (type, labels, milestone, Projects fields, relationships — discover, then apply; judgment values (priority, size, iteration) only when the requester stated them or the issue text carries them — never inferred from the work; attribution metadata never created or reused) and adding the issue to the repo's project board when one exists (`pipeline.md`, Project-board sync).
3. Branch named `<n>-<slug>`. Run the mechanical in-flight probe (`pipeline.md`, git intake step 3): the primary checkout's HEAD off the default branch, a non-primary `git worktree list` entry, or an open draft PR on an `<n>-*` branch → take an isolated worktree branched from `origin/<default>` (`git worktree add <path> -b <n>-slug origin/<default>`) and never `git switch` or fast-forward the primary checkout; no arm hits → a clean solo checkout takes the branch directly via `gh issue develop <n>` (or `git switch -c`). Each arm has a named degrade.
4. Empty bootstrap commit, open a **draft** PR with `Closes #<n>` immediately.

**Announce in-flight work** (`pipeline.md`, Announce in-flight work at intake): when the step-3 probe or the Resume check finds an open PR or worktree for a task other than this run's, announce in-flight work in-session (`in flight: #12, worktree ../repo-12`) before planning — session-only output, the same treatment as the stage-transition marker, never a git artifact.

Every degraded form — no git repo, no remote at all, remote without `gh`, remote without push rights (fork flow), issues disabled, missing project board, or user opt-out — is defined in `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md`. Apply the matching one and **name it in the final report**. Never silently skip a step.

## Stage 2 — Plan

**Read `${CLAUDE_PLUGIN_ROOT}/references/delegation.md` now** for the domain routing table, and **`${CLAUDE_PLUGIN_ROOT}/references/quality.md` now** — the plan's "Architecture & patterns" column is written against the doctrine, not graded against it for the first time at the gate.

Write the plan as a task list, one row per stage, three columns filled for every row:

| What / owner | Failable check | Architecture & patterns |
|---|---|---|
| The stage's deliverable, and who executes it (lead or which agent) | A concrete check that can actually go RED (command + expected output) | Structures touched, patterns applied and why, test list (name tests before code) |

A check that cannot fail ("looks good", "review the code") is not a check — rewrite it before moving on.

**Scout before you plan** (`pipeline.md`): surfaces not read this session get their reconnaissance questions answered first — direct reads or `argus-explorer` — and the plan header records a `Scouted:` line; the oracle checks the plan against it. Commit-time hook config (`.pre-commit-config.yaml`, `.husky/`, `lefthook.yml`, a non-default `core.hooksPath`) is a standing scout question, recorded on that line as the runner found or "no commit hooks configured — checked".

**Cost line:** the plan header also carries a per-run cost line — order-of-magnitude, naming the pipeline path (read-only route, full pipeline, or full pipeline plus fan-out) and which model tier pays each expensive step (the plan review, execution, the review gate). It is session-side output, surfaced when the plan is presented and never written into the plan comment (`git-conventions.md`, team voice) — not a git-artifact line. The plan-review gate checks it exists (rubric item 12).

**Planned-file overlap check** (`pipeline.md`): once the plan names its file set and before it goes to the plan-review gate, cross-check that set against every in-flight PR's changed files (`gh pr diff <n> --name-only`); on a planned-file overlap, name the files and the PR and ask the user to sequence or proceed — announce-and-ask, not a gate, so no plan-review rubric item is added. No remote or no `gh` degrades to `git worktree list` plus the local branch inventory, or a named skip. The cross-check stays with the lead — the plan-review reviewer cannot fetch a PR's changed-file list.

**Decomposition test:** a plan past ~5 implementation stages, an expected diff beyond the reviewable bar, or multiple independently shippable outcomes splits into a parent issue with sub-issues — one branch and PR each, merged serially (`pipeline.md`, Decomposition). The oracle checks this at the gate.

**Domain skill routing:** record which domains the task touches (UI/visual, shadcn project, data viz, database, …) against the table in `${CLAUDE_PLUGIN_ROOT}/references/delegation.md`. Detect matches from the **session's actual available-skills listing** — never invent a skill name from memory or training data. Plugin-namespaced variants count as matches. If no installed skill matches a domain the task touches, say so explicitly in the plan ("no matching skill installed for `<domain>`") and proceed on the quality doctrine alone — never a silent degrade.

## Stage 2.5 — Plan review gate

**Read `${CLAUDE_PLUGIN_ROOT}/references/verification.md` and `${CLAUDE_PLUGIN_ROOT}/references/quality.md` now.**

Spawn `argus-oracle` (or, if unavailable, apply this rubric inline per the Agent availability check above) with the plan, the task statement, **the issue's acceptance criteria verbatim** (the oracle cannot fetch GitHub content; in degraded modes, the criteria text from `PLAN.md` or the PR description), relevant repo context, the absolute path of the target repo's conventions file (its `CLAUDE.md` or equivalent) or "none exists — checked", and a pointer to `${CLAUDE_PLUGIN_ROOT}/references/verification.md` as the rubric's source of truth. Review order:

1. **Simpler-alternative pass (mandatory, first):** should this work exist at all? Is there a smaller or more elegant route to the same goal — doing nothing, reusing something that already exists, a 10%-of-the-risk change that solves 90% of the goal, or a different layer? On parity/fidelity goals the default inverts: reuse is the risk, and each trim states the visible delta it leaves.
2. Do these stages actually reach the stated goal? Diff each plan decision against the issue's acceptance criteria — a negation is a `revise` — and against the plan header's `Scouted:` record.
3. Is every failable check real (can it go RED)?
4. Is a test list present before each implementation stage?
5. Does the chosen architecture hold under `quality.md`?
6. Is any stage delegating a decision that belongs to the lead (architecture, debugging, review, merge)?
7. Does the domain-skill routing match the surfaces the task touches?
8. Is the plan right-sized for review, or does it need decomposition (`pipeline.md`) — barring the unavoidable-size justification `git-conventions.md` permits?
9. Do copied licensed assets carry their license basis and a visibility guard?
10. Docs stay truthful — the plan names the docs a public-API or behavior change updates, or states none mention the surface (checked, not assumed).
11. Repo conventions respected — the brief points at the target repo's conventions file (`CLAUDE.md` or equivalent) by absolute path, or states none exists (checked); a plan decision that negates an invariant written there is a `revise` naming the invariant, checked against the file, not assumed. These are the *target* repo's own rules, distinct from the issue's criteria (item 2) and the docs the diff touches (item 10). A missing-but-derivable pointer is itself a plain `revise`, not a precondition refusal.
12. Cost line present — the plan header carries a per-run cost line (defined at Stage 2) naming the pipeline path and which model tier pays each expensive step, session-side and never written into the plan comment; its absence is a `revise`, not a precondition refusal.

**Precondition refusal:** a plan arriving without failable checks, without a test list for an implementation stage, or without the issue's acceptance criteria attached verbatim, gets an instant `revise` naming the missing precondition — do not attempt a full review of an unreviewable plan.

Verdict is structured: `approve` or `revise` + reasons. A response lacking exactly one verdict from the set is **no verdict** — re-spawn once with a close-with-one-verdict instruction; a second malformed response or a dead spawn means the agent is unavailable for this gate (`verification.md`, Malformed or missing verdicts — applies at every gate, Stage 5 included).

- `revise` → update the plan, resubmit. Cap: **two revise cycles.** On a third disagreement, present both positions (the plan and the oracle's reasons) to the user, proceed per their call, and note it in the final report — board Status → Blocked while waiting, when a board exists.
- A `revise` may be overridden only with an explicit, user-visible justification.
- The oracle always runs at its pinned `opus` tier, regardless of the lead's model.

**On `approve`, the plan becomes durable:** post the plan as an issue comment and mirror the link in the draft PR — or the degraded location from `pipeline.md`'s table (`PLAN.md` committed on the branch when the platform can't host the comment — no remote, or no `gh`; the PR description when only issues are unavailable). The comment is a git artifact: written in the team voice per `git-conventions.md` (headed "Implementation plan", named checkbox items, `command → result` evidence) — run the lexicon check before posting and before every edit. This comment is the exact resume point — update it at every stage boundary from here on.

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
- Parallel fan-out is allowed only across **disjoint file sets** — two executors never mutate the same file, command side effects (lockfiles, snapshots, generated artifacts) included. The lead verifies and commits only on a quiesced tree — after every in-flight executor has returned — first checking each report's files-changed list against its own brief's scope, then `git status` against the union of all scopes (`delegation.md`, isolation model).
- The lead never delegates: architecture decisions, debugging, the review gate, verification sign-off, merge, or security-sensitive edits.
- All implementation is TDD: red → green → **refactor**. The refactor leg is a real, planned step — not an afterthought.

### Self-catch rules (apply continuously)

- Caught writing implementation code before its test exists → stop, return to the plan's test list.
- Caught claiming progress without running a check → stop, run the stage's failable check.
- About to re-run the same failing command a third time → stop, change approach or ask the user. At the second identical failure, first record the running attempt count on the plan comment (one line per attempt as `command → result`) so the retry bound survives a resume (`pipeline.md`, plan-comment lifecycle).

### Deviation from the approved plan

A new module, interface, or dependency not named in the approved plan — or a re-scoped stage — is never executed on momentum: record it as a plan-comment amendment and re-run the Stage 2.5 plan review on the amended plan (the revise-cycle cap keeps counting) before proceeding. The plan gate's `approve` covers the plan as reviewed, not whatever it grows into. One kind of deviation is the exception: a change that alters or weakens an existing gate — this plugin's own skills/agents/references when installed, `.github/workflows/*`, or the test/lint/CI config a verification check depends on — goes to the user for explicit approval, not to this plan-review gate, which is part of what the edit would weaken (`delegation.md`, review dimension 6). Where the edit is this repo's own stated task, the normal gates apply.

### Between every stage

Run the on-track check — **read `${CLAUDE_PLUGIN_ROOT}/references/on-track.md` now**: loop signals, bounded deliberation, context budget.

Then, before starting the next stage, print the mandatory transition marker and update the plan comment:

```
Stage N done — failable check: <cmd> → GREEN | next: Stage N+1
```

The marker is session-only — printed here, never posted to GitHub. The plan-comment update that accompanies it is a git artifact and follows the team-voice contract in `git-conventions.md`.

## Stage 4 — Verify

Run the actual build/test/lint commands and read the output. GREEN evidence is required before any "done / fixed / passing" claim. A red check is reported as red — never merged over, never rationalized away.

For every new test, the pre-implementation failing run — the RED leg — is captured alongside the green and forwarded to the review gate; that RED must be a behavioral assertion failure naming the pinned behavior, not a collection/import/attribute/syntax error that fails before the behavior runs (`verification.md`, what a failable check is).

The full-suite evidence names which CI job and command it mirrors, including the install path CI uses — a clean dependency install, not a warm local cache; a mismatch, or a repo with no CI config to mirror, is a named degradation in the final report, never silent (`verification.md`, what a failable check is). This binds the full-suite run and the reviewer's suite re-run, not every per-slice check. A red-then-green rerun with no code change is disclosed in that evidence, never presented as plain green.

The repo's commit-hook suite is Stage-4 evidence too — run it explicitly through its configured runner (`command → result`), naming the runner as the full-suite evidence names its CI job; no commit hooks configured is a named absence in the final report, and a configured hook that cannot run fails its stage (`verification.md`, what a failable check is). The lead never commits `--no-verify` (or any hook-suppression flag) — a hook bypass is a gate bypass, and a hook that fails on the lead's commit is a Stage-4 RED into `debugging.md`.

A red check that resists one obvious correction is a debugging event, not a retry event: **read `${CLAUDE_PLUGIN_ROOT}/references/debugging.md` now** and run the diagnose loop (reproduce → fail path → falsify → ledger) before any further attempt. If a `debug-mantra` skill is installed in the session, invoke it instead (domain routing, `references/delegation.md`).

## Stage 5 — Review & deliver

**Read `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` again now** for the verdict→action mapping and the degraded merge semantics. When a project board exists, set its Status to In Review as this gate begins (`pipeline.md`, Project-board sync).

**Read `${CLAUDE_PLUGIN_ROOT}/references/verification.md` now** for the reviewer operating rules: end-to-end, not diff-local (trace the call graph through the unchanged code around the diff — bugs hide at the seams); no rubber-stamps ("LGTM" is not an output — report what was traced and what was checked); every finding cites `file:line`; report format per finding is **Finding / Why it matters / Evidence / Suggested change**, ordered by severity.

Spawn `argus-reviewer` on the diff (or, if unavailable, apply this rubric inline per the Agent availability check above; under a Stage 0 "proceed anyway" override, spawn `argus-oracle`'s final-review duty instead — see the model gate). **The brief must attach the verbatim Stage 4 command and its full output** — the reviewer's precondition demands it — **name the issue and PR under review** so the reviewer can read their text with its read-only `gh` grant (dimension 2 covers the artifacts this run produced), **and carry a pointer to `${CLAUDE_PLUGIN_ROOT}/references/verification.md` as the rubric's source of truth** — the reviewer applies the file, not this summary. **Precondition refusal:** the reviewer refuses a diff whose test suite is not shown GREEN — it returns immediately naming the missing precondition.

Review dimensions (rubric shared with `quality.md`):

1. **Correctness** — does it do what the issue says; edge cases.
2. **Readability** — docblocks present, truthful, and free of filler prose on all public API; names communicate intent.
3. **Architecture fit** — boundaries respected; single responsibility.
4. **Pattern justification** — patterns earn their complexity.
5. **Test quality** — tests can actually fail; no tautologies; no reaching green by disabling a test, raising a timeout, or a blind-rerun to green (a red-then-green rerun is disclosed, not counted as plain green).
6. **Security** — injection surfaces, authz seams, secrets in the diff, unsafe defaults. Checked on every review, not only "security tasks".

**Verdict → action mapping (exact):**

| Verdict | Action |
|---|---|
| `ship` | Merge. |
| `fix-then-ship` | Fix the findings, re-run Stage 4, merge. No fresh review required. |
| `rework` | Return to Stage 3 (or Stage 2 if the plan is implicated — the revised plan re-enters the Stage 2.5 review before execution resumes). A fresh Stage 5 review is mandatory afterward. Cap: two rework cycles, then escalate to the user (board → Blocked while waiting). |
| `reject` | Stop. Do not merge. Report the reviewer's reason to the user. |

**User-acceptance hold (two triggers):** one Stage-5 hold, not a gate per trigger — a merging verdict (`ship`, or `fix-then-ship` once its fixes are re-verified) readies the PR and posts evidence, but the merge waits for the user's explicit acceptance. Trigger 1 — a perceptual goal (visual fidelity, "looks like X"): the evidence is the per-surface comparison against the named reference. Trigger 2 — the diff touches a sensitive path (auth, payments/billing, secrets/`.env`, CI workflow files, DB migrations; `verification.md`, Sensitive paths, is the canonical list): the evidence is the readied PR naming which sensitive paths were touched plus the Stage 4 output, and dimension 6 surfaces the touch at the review. Every rejection cycle re-runs Stage 4 and this gate before the next ask; a target repo's `CLAUDE.md` may exempt a path (named in the plan header and the final report), and the model-gate "proceed anyway" override never waives it (`pipeline.md`, the user-acceptance hold).

**Lifecycle tail:** on a repo that versions, record the change under Unreleased in the same PR and treat a release as its own task (`${CLAUDE_PLUGIN_ROOT}/references/releasing.md`). A bad merge reverts first via the expedited path (`pipeline.md`). A `reject`, a rework-cap escalation, a post-merge rejection, or a non-converging hold files a post-mortem record on the triggering issue (`${CLAUDE_PLUGIN_ROOT}/references/post-mortem.md`).

On merge: first confirm the merge base is current — per `pipeline.md`'s "Merge on a fresh base only", fetch, and if the default branch moved past the base the Stage 4 evidence was gathered on, update the branch and re-run Stage 4 before merging. Then confirm merge readiness (`pipeline.md`, Merge readiness): poll `gh pr checks <n>` and require every required check concluded success (a pending required check waits and is announced; a failing one re-enters `debugging.md`), and read the default branch's protection (`gh api repos/<owner>/<repo>/branches/<default>/protection`) — a required approval the tool cannot supply readies the PR and waits for that GitHub approval instead of merging, and the allowed merge method selects `--squash` / `--rebase` / `--merge`. A concluded-success CI run on the exact verified HEAD SHA is auditable full-suite evidence the reviewer audits via its read-only `gh` grant instead of re-running locally. Zero check-runs or no protection info → named skip, the local Stage 4 stands alone (`pipeline.md`, degradation table). Then update the PR description's "How it was verified" section with the Stage 4 command and its result — PR text in the team voice per `git-conventions.md` — flip the draft PR to ready, merge — the issue auto-closes. Set the board Status to Done on merge, when a board exists, then run the terminal-outcome cleanup (`pipeline.md`): remove the run's worktree, delete the merged branch. (Degraded modes per `pipeline.md`'s table — a local `git merge --no-ff` only when no remote exists at all; a pushed branch + compare link when the remote lacks `gh`; a ready cross-fork PR when push rights are absent.)

### Deliver

Report to the user:

- What shipped, with evidence (test output, PR link).
- Every degraded, skipped, or overridden step, named plainly — never omitted.
