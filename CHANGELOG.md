# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Self-check blind spots closed (development surface, not shipped to
  installs — `tests/run-checks.sh`, `tests/changelog-gate.sh`,
  `tests/fixtures/dirty.md`, `.github/workflows/ci.yml`,
  `RELEASE-CHECKLIST.md`): the lexicon fixture is asserted per
  alternation branch (deleting any single branch turns CI red); rubric
  parity is checked mechanically (plan-review items 10/10/10 across
  verification.md and both skills; review dimensions 6/6/6/6 across
  verification.md, both review agents, and the run skill); every
  released tag needs its RELEASE-CHECKLIST record row (v0.5.1's
  missing row added); and the changelog CI gate now asserts entries
  land inside the `## [Unreleased]` section, via a locally runnable
  `tests/changelog-gate.sh`. (#42)
- Degradation and lifecycle rows (`references/pipeline.md`,
  `references/post-mortem.md`, both skills): the no-remote row splits
  — "remote exists, `gh` missing" now pushes the branch and delivers
  the compare link instead of merging locally into a default branch
  that would diverge from origin; a new "remote exists, no push
  rights" row defines the fork / cross-fork-PR flow; terminal
  outcomes get a cleanup rule (worktrees removed; branches deleted on
  merge or confirmed abandonment, kept on reject — the rejected work
  is the user's to dispose of); the triviality re-entry rule survives
  the commit (a hatch edit failing after commit/push re-enters the
  pipeline, reverting a broken default-branch commit first); and
  post-mortem records get degraded landing spots. (#41)
- Gate-brief contracts, seven fixes (`agents/argus-oracle.md`,
  `agents/argus-reviewer.md`, `references/verification.md`,
  `references/pipeline.md`, both skills): the plan-review brief must
  attach the issue's acceptance criteria verbatim (precondition
  refusal extended — the criteria diff in rubric item 2 was
  unexecutable without them); the delivery-review brief carries the
  verification.md source-of-truth pointer and both review agents gain
  the rebuild/markup-coupled-suite clause in test quality; a plan
  changed after approval is re-gated (rework-to-plan re-enters the
  plan review; run mode gains a deviation rule); the "proceed anyway"
  model-gate override routes the delivery review to the pinned-opus
  oracle instead of the inherit-tier reviewer; a malformed or missing
  gate verdict has a defined disposition (one re-spawn, then the
  announced agent-unavailable degrade — hedges never round to
  approval); the consult mid-execution checkpoint maps to the oracle's
  debugging-arbitration duty and gains a third-firing escalation cap;
  and the changed-file-list-plus-base-ref evidence form is replaced by
  patch text or an on-disk patch file the no-Bash oracle can actually
  Read. (#40)
- Parallel fan-out working-tree model (`references/delegation.md`,
  `agents/argus-implementer.md`, `references/pipeline.md`,
  `skills/run/SKILL.md`): shared-tree fan-out with quiesced-tree
  verification — the disjoint-file-set rule now covers command side
  effects (lockfiles, snapshots, generated artifacts), the lead
  verifies and commits only with no executor in flight after a
  `git status` cross-check against the union of briefed scopes, at
  most three implementers run concurrently, and decomposed sub-issue
  branches are updated onto the current default branch and re-verified
  before each serial merge. (#39)
- Resume path (`references/pipeline.md`, "Resume — the receiving
  side"; both skills; `references/on-track.md`): a request naming an
  existing issue, PR, or branch — or an in-flight branch whose plan
  comment covers the task — adopts the durable state instead of
  re-running intake; the branch's commit log outranks a lagging plan
  comment and is reconciled first; an unchanged approved plan is not
  re-reviewed; a recorded-but-unapplied review outcome is applied
  before new work. The plan-comment lifecycle now records every
  review-gate outcome and its round count, so rework/revise caps
  survive a handoff. (#38)

## [0.5.1] - 2026-07-10

### Fixed

- Skill-summary gaps from the 0.5.0 release review, both skills: the
  consult read-only-route summary names the plan-review step (was
  "plan, explore, report"); the run intake carries a one-clause
  ambiguity-gate mention, kept before the issue is written; consult uses
  label-safe "a `question` issue" phrasing (existing labels only); both
  landing-rule summaries carry the public-repo vulnerability exception (a
  finding exposing a hole in a public repo never lands on a public
  issue); and the consult inline-fallback plan-review rubric enumerates
  all ten review items, reaching parity with the run skill so a
  consult-only install stays self-contained.

## [0.5.0] - 2026-07-10

### Added

- Research flow (`references/pipeline.md`, both skills): the read-only
  route gains a report contract (question → what was searched →
  `file:line`-cited findings → open questions) and a landing rule —
  one-shot answers may stay in chat; findings that feed later work,
  outlive the session, or hand off mid-run land on a `question` issue
  that becomes the route's resume point, with a when-unsure
  tie-breaker toward durability, a private channel for
  vulnerability findings on public repos, and a degraded report-file
  form.
- Scout before you plan (`references/pipeline.md`,
  `references/verification.md`, both skills): surfaces not read this
  session — or no longer in context — get their reconnaissance
  questions answered before the plan is written, recorded as a
  `Scouted:` line in the plan header; the plan review checks the plan
  against that record.
- Domain routing (`references/delegation.md`): four new rows —
  research/deep-dive investigation, security review, library-docs
  lookup, and new-capability ideation — each with a named shipped
  fallback.
- Docs-currency check (`references/verification.md` rubric item 10 and
  dimension 2, both review agents, the run skill's inline rubric):
  plans touching public API or user-visible behavior name the docs
  they update or state that none mention the surface — checked, not
  assumed; a README or doc example contradicted by the diff is a
  Readability finding.
- Ambiguity gate (`references/pipeline.md`): a new capability whose
  acceptance criteria cannot be derived from the request gets targeted
  questions — or two to three shaped options — before the issue is
  written; answers recorded in the issue so the criteria trace to the
  requester, not the pipeline's guess.
- Decision records (`references/git-conventions.md`): a plan decision
  marked load-bearing beyond its PR gets a committed `docs/adr/` entry
  (or the repo's native equivalent), linked from the plan comment.
- `references/releasing.md` (new): the lifecycle tail for repos that
  version — record shipped changes under Unreleased in the same PR;
  a release is its own task (roll-up, manifest bump, tag on the merge
  commit, notes matching the entry; version from the Conventional
  Commits types since the last tag). Canonical for this repo's own
  release discipline, now referenced from `CLAUDE.md`.
- Revert-first rule (`references/pipeline.md`): a merged change that
  breaks production takes an expedited revert path — issue, revert PR,
  verification evidence, review gate, no plan gate — bounded to clean
  reverts; the real fix re-enters as a full run linking the revert.
- `references/post-mortem.md` (new): a reject verdict, a rework-cap
  escalation, a post-merge rejection, or a non-converging acceptance
  hold files a four-field record on the triggering issue (what the
  gate saw, what it missed, which check should have caught it, the
  proposed change — surfaced to the user, never auto-filed). Routing
  row added with an installed post-mortem skill preferred.
- Repo self-enforcement (development surface, not shipped to
  installs): a CI workflow enforcing the changelog-per-shipped-change
  and version-consistency invariants, README completeness, and a
  tag-equals-manifest check; `tests/run-checks.sh` proving the lexicon
  pattern against dirty/clean fixtures and resolving every reference
  cross-link; `RELEASE-CHECKLIST.md` recording the design spec's smoke
  tests per release; a PR template carrying the two repo invariants
  and a bug-report form capturing version, session model, command, and
  install path.

### Fixed

- Review polish from the 0.4.0 release review, both skills: the run
  preamble's hatch summary carries all four criteria; Blocked board
  status is named at the escalation points; the run skill's inline
  fallback rubric carries the parity counterweight, the criteria diff,
  the size escape, and the docs check; the consult intro's overclaim
  ("does all reading, writing, and testing") is corrected to "leads
  all execution"; the third-run self-catch fires
  before the run, not after it.

## [0.4.0] - 2026-07-10

### Added

- Team-voice contract in `references/git-conventions.md`: every git
  artifact reads as an engineer writing to teammates — no session
  vocabulary, no attribution of any form, no machine-local paths, no
  inlined infra values; `command → result` evidence lines, checkbox
  status tracking, `<details>` folding for long coordination detail,
  and a lexicon grep with a refusal condition (with a carve-out for
  repos whose subject matter is the pipeline itself). Review dimension
  2 (`references/verification.md`, reviewer and oracle agents) treats
  violations as Readability findings, and the gates receive the
  produced artifact text as evidence: a fourth consult-mode evidence
  item, and a read-only `gh issue view`/`gh pr view` grant for the
  reviewer.

- GitHub-native tracking (`references/pipeline.md`): intake fills the
  issue fields the repo actually has (labels/milestone/type —
  discover, then apply, never invent); a Project-board sync section
  adds the issue to the repo's Projects v2 board and advances its
  Status as the work moves (In Progress → In Review → Done, Blocked on
  holds), with a degradation row for missing boards or token scope.
- Decomposition rule (`references/pipeline.md`,
  `references/verification.md` rubric item 8,
  `references/delegation.md`): the big-work counterpart of the
  triviality hatch — a plan past ~5 implementation stages, past the
  reviewable-diff bar, or holding multiple independently shippable
  outcomes splits into a parent issue with sub-issues, one branch and
  PR each, merged serially. Decomposition (deliverable splitting) is
  distinguished from fan-out (execution splitting inside one branch).

- Review-gate fixes from field testing (`references/pipeline.md`,
  `references/verification.md`, both skills, README): a subjective-goal
  hold — on perceptual goals `ship` readies the PR and posts comparison
  evidence but the merge waits for the user's explicit acceptance, each
  rejection cycle re-running verification and review before the next
  ask; a planned check that cannot run fails its stage (build the
  harness or record an explicit user waiver — disclosure is not
  evidence); a post-merge rejection re-enters the full pipeline, and a
  PR that defers checklist items must not auto-close its issue; the
  plan review now diffs every plan decision against the issue's
  acceptance criteria (a negation is an instant revise), counterweights
  the simpler-alternative pass on parity goals (each reuse trim states
  the visible delta it leaves), requires a goal-anchored comparison
  check for external-reference goals, treats an old markup-coupled
  suite staying green on a rebuild as non-evidence, and checks that
  copied licensed assets carry their license basis and a
  visibility guard.

### Fixed

- Skill descriptions no longer steer 1–3-line edits away from the
  pipeline before the triviality hatch can classify them — the hatch
  decides (≤3 lines AND one file AND no behavior change), and a bugfix
  never qualifies.
- The subjective-goal hold covers both merging verdicts:
  `fix-then-ship` waits for the user's acceptance exactly like `ship`.
- Board-status guidance sets In Review at the start of the review
  gate, not inside the merge step.

### Changed

- Plan-comment lifecycle (`references/pipeline.md`) rewritten to the
  team-voice contract: "Implementation plan" heading, named checklist
  items instead of internal stage numerals, `command → result`
  evidence, the lexicon check before every post and edit, and
  PR-linked commit references that survive a squash-merge.
- Stage-transition marker declared session-only
  (`references/on-track.md`, both skills) — printed in the session,
  never posted to GitHub.

## [0.3.0] - 2026-07-09

### Added

- Prose-style rules in `references/git-conventions.md` — every prose
  artifact the pipeline writes (issue/PR descriptions, commit bodies,
  docblocks, READMEs) is held free of AI-writing patterns: no filler, no
  promotional tone, no rule-of-three padding, no sycophancy, no generic
  conclusions, plain verbs, evidence-backed hedging only. Adapted with
  credit from blader/humanizer (Wikipedia "Signs of AI writing").
- Domain routing: long user-facing prose (docs, README, release notes)
  routes to a locally installed `humanizer` skill, with the prose-style
  rules as the shipped fallback.

### Fixed

- Gate evidence chain: the run-skill reviewer brief now attaches the
  verbatim Stage 4 command and output; the consult-mode oracle brief
  additionally carries the diff and the run-time HEAD SHA, with
  precondition refusal extended to a missing diff or SHA.
- consult: agent-availability check relocated before Stage 0 and
  extended to cover missing executors; inline triviality summary added
  for the degraded path; the reverse gate follows the run skill in full.
- Read triggers realigned: quality.md read at run Stage 2,
  verification.md at consult Stage 2, pipeline.md re-read at both Stage
  5s; a no-git route defined for non-trivial read-only work; the
  dimension↔principle mapping corrected to one identical sentence in
  quality.md and verification.md; consult's first-failure diagnose-loop
  entry encoded in debugging.md; degraded-location pointers added to the
  run skill's Stage 2.5 and Stage 5; stage-transition marker numbering
  defined; a trivial-task exception added to the run skill's model gate.
- README now links both SKILL.md files (repo invariant) and discloses
  that skills-only installs may also lose the references/ documents;
  delegation.md records that the implementer no-commit rule is a
  prompt-level contract; both skills update the PR's "How it was
  verified" section before flipping the draft ready.

### Changed

- Readability bar tightened everywhere it is stated (quality doctrine,
  review dimension 2, reviewer/oracle/implementer agents): docblocks
  must be truthful **and filler-free** — a docblock written like ad copy
  is treated as missing.
- `plugin.json` carries full manifest metadata: `$schema`, `homepage`,
  `repository`, `license`, `keywords`.
- Release discipline reworked to accumulate-then-release: shipped-file
  changes record under this Unreleased section in their own PR; a
  release PR moves them into a version entry and bumps `plugin.json`.

## [0.2.0] - 2026-07-09

### Added

- `references/debugging.md` — a self-contained four-step diagnose loop
  (reproduce → fail path → falsify → breadcrumb ledger), adapted with
  credit from thananon/9arm-skills debug-mantra. Both skills gain the
  red-check entry point, and domain routing prefers a locally installed
  `debug-mantra` skill with this file as the shipped fallback.
- `references/git-conventions.md` — branch naming, full Conventional
  Commits rules (atomic, tree green after every commit), and issue/PR
  title and description contracts for every artifact the pipeline
  creates. Chained into Stage 1 intake via `pipeline.md` and into the
  lead's slice-commit rule via `delegation.md`.

### Changed

- Release discipline: every merged PR that changes shipped files bumps
  the plugin version and this changelog in the same PR — plugin updates
  are detected by version comparison only.

## [0.1.0] - 2026-07-09

### Added

- Initial release of the argus-mode Claude Code plugin.
- `/argus-mode:run` skill — full staged engineering pipeline for Fable/Opus-led
  sessions: git intake, staged plan, independent plan-review gate, adaptive
  TDD execution, real-command verification, and a 6-dimension review gate
  before merge.
- `/argus-mode:consult` skill — the same pipeline for Sonnet/Haiku-led
  sessions, with mandatory `argus-oracle` checkpoints at plan review,
  objective execution triggers, and final review in place of the reviewer
  agent.
- Four agents: `argus-oracle` (opus, advisor), `argus-explorer` (haiku,
  read-only reconnaissance), `argus-implementer` (sonnet, TDD executor),
  `argus-reviewer` (inherit, 6-dimension review gate).
- Shared reference docs: `creed.md`, `pipeline.md`, `delegation.md`,
  `verification.md`, `quality.md`, `on-track.md`.
- Self-hosted marketplace (`.claude-plugin/marketplace.json`) enabling
  `/plugin marketplace add parsilver/argus-mode`.

[Unreleased]: https://github.com/parsilver/argus-mode/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/parsilver/argus-mode/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/parsilver/argus-mode/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/parsilver/argus-mode/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/parsilver/argus-mode/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/parsilver/argus-mode/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/parsilver/argus-mode/releases/tag/v0.1.0
