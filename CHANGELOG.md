# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- Domain routing (`references/delegation.md`): three new rows —
  research/deep-dive investigation, security review, and library-docs
  lookup — each with a named shipped fallback.

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

[0.4.0]: https://github.com/parsilver/argus-mode/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/parsilver/argus-mode/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/parsilver/argus-mode/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/parsilver/argus-mode/releases/tag/v0.1.0
