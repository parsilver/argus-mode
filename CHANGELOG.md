# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  `verification.md`, `quality.md`, `on-track.md`, `debugging.md` — a
  self-contained diagnose loop (adapted with credit from
  thananon/9arm-skills debug-mantra) with domain routing to a locally
  installed `debug-mantra` skill when present — and
  `git-conventions.md` — branch naming, Conventional Commits, and
  issue/PR title and description contracts for every artifact the
  pipeline creates.
- Self-hosted marketplace (`.claude-plugin/marketplace.json`) enabling
  `/plugin marketplace add parsilver/argus-mode`.

[0.1.0]: https://github.com/parsilver/argus-mode/releases/tag/v0.1.0
