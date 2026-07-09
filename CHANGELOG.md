# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/parsilver/argus-mode/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/parsilver/argus-mode/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/parsilver/argus-mode/releases/tag/v0.1.0
